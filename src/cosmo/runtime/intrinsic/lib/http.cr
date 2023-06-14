require "http/server"
require "http/client"
require "http/headers"
require "json"

# TODO: an actually nice way to get URI parameters
module Cosmo::Intrinsic
  class HttpLib < Lib
    def inject : Nil
      http = {} of String => Hash(String, IFunction) | IFunction
      server = {} of String => IFunction
      server["listen"] = Server::Listen.new(@i)

      @i.declare_intrinsic("string->Function", "Server", server)
      @i.declare_intrinsic("Function", "request", Client::RequestFunction.new(@i))
    end

    abstract class Client::ResponseBodyFunctionBase < IFunction
      def initialize(interpreter : Interpreter, @body : String)
        super interpreter
      end
    end

    # Makes an HTTP request and returns the response
    class Client::RequestFunction < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 3.to_u
      end

      private def convert_headers(headers : Array(ValueType)) : Array(Array(String))
        headers.map(&.as(Array(ValueType)).map(&.to_s))
      end

      # `string uri`: The URI path to make a request to
      # `Function callback`: Executed when the request is completed
      # `Table? options`
      #   - `string verb`: The HTTP verb to use, e.g. GET, POST
      #   - `string[][] headers`
      #   - `(string | Table)? form`: The form body to send
      def call(args : Array(ValueType)) : ValueType
        t = token("HTTP->fetch")
        TypeChecker.assert("string", args.first, t)
        TypeChecker.assert("Function", args[1], t)
        TypeChecker.assert("(string->any)?", args[2]?, t)

        url = args.first.to_s
        callback = args[1].as Function
        options = args[2]?.nil? ?
          {} of ValueType => ValueType
          : args[2].as Hash(ValueType, ValueType)

        TypeChecker.assert("string?", options["method"]?, t)
        method = (options["method"]? || "get").to_s.downcase
        headers = options["headers"]?
        form = options["form"]?
        TypeChecker.assert("string[][]?", headers, t)
        TypeChecker.assert("string | (string->any) | void", form, t)

        headers_obj = HTTP::Headers.new
        unless headers.nil?
          headers = convert_headers(headers.as Array)
          headers.each do |h|
            unless h.size == 2
              Logger.report_error(
                "Invalid header array '#{h}'",
                "Header array must have exactly 2 elements. The first is the key, the second is the value.",
                t
              )
            end
            headers_obj.add(h.first, h.last)
          end
        end

        case method
        when "put", "patch", "post"
          if form.nil?
            Logger.report_error(
              "Invalid #{method.upcase} options",
              "Options table for the #{method.upcase} method must include a 'form' key",
              t
            )
          end
        end

        case method
        when "get"
          res = HTTP::Client.get(url, headers_obj)
        when "delete"
          res = HTTP::Client.delete(url, headers_obj)
        when "post"
          res = HTTP::Client.post(
            url,
            headers_obj,
            form.is_a?(Hash(String, String)) ? form.to_json : form.to_s
          )
        when "put"
          res = HTTP::Client.put(
            url,
            headers_obj,
            form.is_a?(Hash(String, String)) ? form.to_json : form.to_s
          )
        when "patch"
          res = HTTP::Client.patch(
            url,
            headers_obj,
            form.is_a?(Hash(String, String)) ? form.to_json : form.to_s
          )
        else
          Logger.report_error("Failed to fetch", "Invalid HTTP method '#{method}'", t)
        end

        wrapped_body = {} of String => IFunction
        wrapped_body["json"] = Client::ResponseBody::ToJSON.new(@interpreter, res.body)
        wrapped_body["text"] = Client::ResponseBody::ToText.new(@interpreter, res.body)

        wrapped_res = {} of String => String | Int64 | Hash(String, IFunction)
        wrapped_res["status_code"] = res.status_code
        wrapped_res["body"] = wrapped_body

        callback.call([
          TypeChecker.as_value_type(wrapped_res)
        ])
      end
    end

    # Returns the response body as a string (unchanged)
    class Client::ResponseBody::ToText < Client::ResponseBodyFunctionBase
      def arity : Range(UInt32, UInt32)
        0.to_u .. 0.to_u
      end

      def call(args : Array(ValueType)) : String
        @body
      end
    end

    # Returns the response body as a JSONAny
    class Client::ResponseBody::ToJSON < Client::ResponseBodyFunctionBase
      def arity : Range(UInt32, UInt32)
        0.to_u .. 0.to_u
      end

      def call(args : Array(ValueType)) : ValueType
        begin
          TypeChecker.as_value_type(JSON.parse(@body))
        rescue ex : JSON::ParseException
          Logger.report_error("Failed to parse JSON", ex.message || "Invalid JSON body", token("HTTP::Client::ResponseBody->json"))
        end
      end
    end

    # Base class for all HTTP context functions
    abstract class Server::ContextFunctionBase < IFunction
      def initialize(interpreter : Interpreter, @server_ctx : HTTP::Server::Context)
        super interpreter
      end
    end

    # Sets the `Content-Type` header to `content_type`
    class Response::SetContentType < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      # `string content_type`
      def call(args : Array(ValueType)) : Nil
        TypeChecker.assert("string", args.first, token("HTTP::Server::Response->set_content_type"))
        @server_ctx.response.content_type = args.first.to_s
      end
    end

    # Sends `value` back to the client
    class Response::Send < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      # `JSONAny value`
      def call(args : Array(ValueType)) : Nil
        @server_ctx.response.print(args.first)
      end
    end

    # Retrieves the value of a query parameter
    class Request::GetParameter < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : String?
        @server_ctx.request.query_params.fetch(args.first.to_s, nil)
      end
    end

    # Creates a new server and listens on port `port`, then calls `callback` with the HTTP request and response tables
    class Server::Listen < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 2.to_u
      end

      # `uint port`
      # `Function callback`: The function called when the server starts successfully
      def call(args : Array(ValueType)) : Nil
        TypeChecker.assert("uint", args.first, token("HTTP::Server->listen"))
        TypeChecker.assert("Function", args[1], token("HTTP::Server->listen"))

        port = args.first.as(Int).to_i32
        server = HTTP::Server.new do |ctx|
          ctx.response.content_type = "text/plain"
          wrapped_res = {} of String => Server::ContextFunctionBase
          wrapped_res["content_type"] = Response::SetContentType.new(@interpreter, ctx)
          wrapped_res["send"] = Response::Send.new(@interpreter, ctx)

          wrapped_req = {} of String => ValueType
          wrapped_req["path"] = ctx.request.path
          wrapped_req["query"] = ctx.request.query
          wrapped_req["parameter"] = Request::GetParameter.new(@interpreter, ctx)
          wrapped_req["remote_address"] = !ctx.request.remote_address.nil? ? ctx.request.remote_address.to_s : nil

          args[1].as(Function).call([
            TypeChecker.hash_as_value_type(wrapped_res),
            TypeChecker.hash_as_value_type(wrapped_req)
          ])
        end

        server.listen(port)
      end
    end
  end
end
