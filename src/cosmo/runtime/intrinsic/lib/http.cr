require "http/server"

class Cosmo::HttpLib < Cosmo::IntrinsicLib
  def inject : Nil
    http = {} of String => Hash(String, IntrinsicFunction)
    server = {} of String => IntrinsicFunction
    server["listen"] = Server::Listen.new(@i)

    http["Server"] = server
    @i.declare_intrinsic("string->string->func", "HTTP", http)
  end

  abstract class Server::ContextFunctionBase < IntrinsicFunction
    def initialize(interpreter : Interpreter, @server_ctx : HTTP::Server::Context)
      super interpreter
    end
  end

  class Server::Response::SetContentType < Server::ContextFunctionBase
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Nil
      TypeChecker.assert("string", args.first, token("HTTP::Server::Response->set_content_type"))
      @server_ctx.response.content_type = args.first.to_s
    end
  end

  class Server::Response::Send < Server::ContextFunctionBase
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Nil
      TypeChecker.assert("string", args.first, token("HTTP::Server::Response->send"))
      @server_ctx.response.print(args.first.to_s)
    end
  end

  class Server::Listen < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      2.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : Nil
      TypeChecker.assert("uint", args.first, token("HTTP::Server->listen"))
      TypeChecker.assert("func", args[1], token("HTTP::Server->listen"))

      port = args.first.as(Int).to_i32
      server = HTTP::Server.new do |ctx|
        ctx.response.content_type = "text/plain"
        wrapped_res = {} of String => Server::ContextFunctionBase
        wrapped_res["content_type"] = Server::Response::SetContentType.new(@interpreter, ctx)
        wrapped_res["send"] = Server::Response::Send.new(@interpreter, ctx)

        wrapped_req = {} of String => ValueType
        wrapped_req["path"] = ctx.request.path

        args[1].as(Function).call([
          TypeChecker.hash_as_value_type(wrapped_res),
          TypeChecker.hash_as_value_type(wrapped_req)
        ])
      end

      server.listen(port)
    end
  end
end
