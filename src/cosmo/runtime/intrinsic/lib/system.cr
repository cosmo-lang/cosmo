module Cosmo::Intrinsic
  class SystemLib < Lib
    class EnvLib < Lib
      def inject : Nil
      end

      def build(_system : Hash(String, Hash(String, Cosmo::Intrinsic::IFunction | String) | IFunction | String)) : Nil
        env = {} of String => IFunction | String
        env["var"] = Var.new(@i)
        env["set_var"] = SetVar.new(@i)

        TypeChecker.assert("string->(Function|string)", env, token("SystemLib::EnvLib#inject"))
        _system["Env"] = env
      end

      class Var < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : String
          TypeChecker.assert("string", args.first, token("System::Env->var"))

          key = args.first.to_s
          begin
            ENV[key]
          rescue KeyError
            Logger.report_error("Missing environment variable", key, token("System::Env->var"))
          end
        end
      end

      class SetVar < IFunction
        def arity : Range(UInt32, UInt32)
          2.to_u .. 2.to_u
        end

        def call(args : Array(ValueType)) : Nil
          TypeChecker.assert("string", args.first, token("System::Env->set_var"))
          TypeChecker.assert("string", args[1], token("System::Env->set_var"))
          ENV[args.first.to_s] = args[1].to_s
        end
      end
    end

    class Exec < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : String
        t = token("System->exec")
        TypeChecker.assert("string", args.first, t)

        command_args = args.first.to_s.split(' ')
        process = command_args.shift
        io = IO::Memory.new

        begin
          Process.run(process, command_args, input: STDIN, output: io, error: io)
        rescue File::NotFoundError
          Logger.report_error("Invalid 'exec' process", "Command '#{process}' could not be found", t)
        end

        io.to_s.chomp
      end
    end

    def inject : Nil
      _system = {} of String => IFunction | String | Hash(String, Cosmo::Intrinsic::IFunction | String)
      _system["os"] = os
      EnvLib.new(@i).build(_system)

      @i.declare_intrinsic("Function", "exec", Exec.new(@i))
      @i.declare_intrinsic("string->any", "System", _system)
    end

    private def os : String
      {% if flag?(:linux) %}
        "Linux"
      {% elsif flag?(:darwin) %}
        "Darwin"
      {% elsif flag?(:windows) %}
        "Windows"
      {% elsif flag?(:bsd) %}
        "BSD"
      {% else %}
        "Unknown"
      {% end %}
    end
  end
end
