require "http/client"
require "uri"
require "json"

module Cosmo
  module Intrinsic
    class WebhookLib < Lib
      def inject : Nil
        discord_webhook = {} of String => IFunction
        discord_webhook["send"] = Send.new(@i)

        @i.declare_intrinsic("string->Function", "DiscordWebhook", discord_webhook)
      end

      class Send < IFunction
        def arity : Range(UInt32, UInt32)
          2.to_u .. 2.to_u
        end

        def call(args : Array(ValueType)) : String
          t = token("Webhook->send")
          TypeChecker.assert("string", args.first, t)
          TypeChecker.assert("string", args[1], t)

          webhook_url = args[0].to_s
          payload = { "content" => args[1].to_s }

          headers = HTTP::Headers{"Content-Type" => "application/json"}
          response = HTTP::Client.post(url: webhook_url, form: payload, headers: headers, tls: true)

          if response.status_code == 301
            new_location = response.headers["Location"]
            return call([new_location, args[1]])
          elsif response.status_code == 204
            return "Message sent successfully!"
          else
            Logger.report_error("Failed to send webhook message", "Status code #{response.status_code}", t)
          end
        end
      end
    end
  end
end
