module Cosmo
  module Intrinsic
    class JSONLib < Lib
      def inject : Nil
        json = {} of String => IFunction
        serialize = Serialize.new(@i)
        deserialize = Deserialize.new(@i)
        json["serialize"] = serialize
        json["deserialize"] = deserialize
        json["stringify"] = serialize
        json["parse"] = deserialize

        @i.declare_intrinsic("string->Function", "JSON", json)
        @i.interpret("type JSONType = JSONType[]|(string->JSONType)|string|float|int|uint", "JSONLib")
      end

      # Parses a raw JSON input into a Cosmo value
      class Deserialize < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : ValueType
          t = token("JSON->deserialize")
          begin
            TypeChecker.assert("string", args.first, t)
            TypeChecker.as_value_type(JSON.parse(args.first.to_s).raw)
          rescue ex : JSON::ParseException
            Logger.report_error("Failed to parse JSON", ex.message || "Invalid JSON body", t)
          end
        end
      end

      # Stringify a Cosmo value into a JSON string
      class Serialize < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        private def as_json_type(value : ValueType) : JSON::Any
          if value.is_a?(Array)
            JSON::Any.new(value.map { |v| as_json_type(v) })
          elsif value.is_a?(Hash)
            json_hash = {} of String => JSON::Any
            value.each_key do |k|
              json_hash[k.to_s] = as_json_type(value[k])
            end
            JSON::Any.new(json_hash)
          else
            JSON::Any.new(value.as JSON::Any::Type)
          end
        end

        def call(args : Array(ValueType)) : String
          TypeChecker.assert("JSONType", args.first, token("JSON->serialize"))
          as_json_type(args.first).to_json
        end
      end
    end
  end
end
