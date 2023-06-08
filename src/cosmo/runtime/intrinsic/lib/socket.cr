require "socket"

module Cosmo::Intrinsic
  class SocketLib < Lib
    def inject : Nil
      socket = {} of String => Hash(String, IFunction) | IFunction
      server = {} of String => IFunction
      server["listen"] = Server::Listen.new(@i)

      socket["Server"] = server;
      @i.declare_intrinsic("string->any", "Socket", socket)
    end

    abstract class Server::ContextFunctionBase < IFunction
      def initialize(interpreter : Interpreter, @sock : TCPSocket)
        super interpreter
      end
    end

    class Server::Connection::Send < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : Nil
        TypeChecker.assert("string", args.first, token("Socket::Server::Connection->send"))
        @sock.puts args.first
      end
    end

    class Server::Connection::Receive < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end
      
      def call(args : Array(ValueType)) : (String | Nil)
        TypeChecker.assert("string", args.first, token("Socket::Server::Connection->recv"))
        @sock.print args.first
        return @sock.gets
      end
    end

    class Server::Connection::Close < Server::ContextFunctionBase
      def arity : Range(UInt32, UInt32)
        0.to_u .. 0.to_u
      end

      def call(args : Array(ValueType)) : Nil
        @sock.close
      end
    end

    class Server::Listen < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 2.to_u
      end

      def call(args : Array(ValueType)) : Nil
        TypeChecker.assert("uint", args.first, token("Socket::Server->listen"))
        TypeChecker.assert("func", args[1], token("Socket::Server->listen"))
         
        port = args.first.as(Int).to_i32
        tcpserver = TCPServer.new("0.0.0.0", port)
        while client = tcpserver.accept?
          wrapped_conn = {} of String => Server::ContextFunctionBase
          wrapped_conn["send"] = Server::Connection::Send.new(@interpreter, client)
          wrapped_conn["recv"] = Server::Connection::Receive.new(@interpreter, client)
          wrapped_conn["close"] = Server::Connection::Close.new(@interpreter, client)
          spawn do
            args[1].as(Function).call([
              TypeChecker.hash_as_value_type(wrapped_conn)
            ])
          end
        end
        puts port
      end
    end
  end
end
