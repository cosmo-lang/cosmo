require "http/server"
require "http/client"
require "http/headers"
require "json"

module Cosmo::Intrinsic
  class HttpLib < Lib
    def inject : Nil
      http = {} of String => Hash(String, IFunction) | IFunction
      server = {} of String => IFunction
      server["listen"] = Server::Listen.new(@i)

      @i.declare_intrinsic("string->Function", "Server", server)
      @i.declare_intrinsic("Function", "request", Client::Fetch.new(@i))
    end

    abstract class Client::ResponseBodyFunctionBase < IFunction
      def initialize(interpreter : Interpreter, @body : String)
        super interpreter
      end
    end

    class Client::Fetch < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 3.to_u
      end

      private def convert_headers(headers : Array(ValueType)) : Array(Array(String))
        headers.map(&.as(Array(ValueType)).map(&.to_s))
      end

      def call(args : Array(ValueType)) : ValueType
        TypeChecker.assert("string", args.first, token("HTTP->fetch"))
        TypeChecker.assert("Function", args[1], token("HTTP->fetch"))
        TypeChecker.assert("(string->string) | string->(string[]) | void", args[2]?, token("HTTP->fetch"))

        url = args.first.to_s
        callback = args[1].as Function
        options = args[2]?.nil? ?
          {} of ValueType => ValueType
          : args[2].as Hash(ValueType, ValueType)

        method = (options["method"]? || "get").to_s.downcase
        headers = options["headers"]?
        form = options["form"]?
        TypeChecker.assert("string", method, token("HTTP->fetch"))
        TypeChecker.assert("string[][]", headers, token("HTTP->fetch")) unless headers.nil?
        TypeChecker.assert("string | (string->any)", form, token("HTTP->fetch")) unless form.nil?

        headers_obj = HTTP::Headers.new
        unless headers.nil?
          headers = convert_headers(headers.as Array)
          headers.each do |h|
            unless h.size == 2
              Logger.report_error(
                "Invalid header array '#{h}'",
                "Header array must have exactly 2 elements. The first is the key, the second is the value.",
                token("HTTP->fetch")
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
              "Options for #{method.upcase} method must include a 'form' key",
              token("HTTP->fetch")
            )
          end
        end

        case method
        when "get"
          res = HTTP::Client.get(url, headers_obj)
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
        when "delete"
          res = HTTP::Client.delete(url, headers_obj)
        else
          Logger.report_error("Failed to fetch", "Invalid HTTP method '#{method}'", token("HTTP->fetch"))
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

    class Client::ResponseBody::ToText < Client::ResponseBodyFunctionBase
      def arity : Range(UInt32, UInt32)
        0.to_u .. 0.to_u
      end

      def call(args : Array(ValueType)) : String
        @body
      end
    end

    class Client::ResponseBody::ToJSON < Client::ResponseBodyFunctionBase
      def arity : Range(UInt32, UInt32)
        0.to_u .. 0.to_u
      end

      def call(args : Array(ValueType)) : ValueType
        begin
          TypeChecker.as_value_type(JSON.parse(@body))
        rescue ex : JSON::ParseException
          Logger.report_error("Failed to parse body as JSON", ex.message || "", token("HTTP::Client::ResponseBody->json"))
        end
      end
    end

    abstract class Server::ContextFunctionBase < IFunction
      def initialize(interpreter : Interpreter, @server_ctx : HTTP::Server::Context)
        super interpreter
      end
    end

    class Response::SetContentType < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : Nil
        TypeChecker.assert("string", args.first, token("HTTP::Server::Response->set_content_type"))
        @server_ctx.response.content_type = args.first.to_s
      end
    end

    class Response::Send < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : Nil
        @server_ctx.response.print(args.first)
      end
    end

    class Request::GetParameter < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : String?
        @server_ctx.request.query_params.fetch(args.first.to_s, nil)
      end
    end

    class Server::Listen < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 2.to_u
      end

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
