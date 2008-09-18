module RestfulRoutes
  module Locator
    class FireEagleError < StandardError; end

    class FireEagleClient
      include RestfulRoutes::Util

      LOGGER = RestfulRoutes::Logger.new

      def initialize
        @fe_credentials = Hash.new
      end

      def fire_eagle_client
        ::FireEagle::Client.new(:consumer_key => RestfulRoutes::FIRE_EAGLE_CREDENTIALS[:consumer_key],
          :consumer_secret => RestfulRoutes::FIRE_EAGLE_CREDENTIALS[:consumer_secret])
      end
      
      def granted?(msisdn)
        @fe_credentials[msisdn] && @fe_credentials[msisdn][:access_token]
      end
      
      def register(msisdn, test = false)
        client = fire_eagle_client
        begin
          request_token = client.get_request_token

          LOGGER.debug "fireeagle request_token: #{request_token}"
          url = client.authorization_url
          url = tiny_url(url) unless test

          @fe_credentials[msisdn] = {:client => client}
        
          msg = 'pon esta dirección en tu navegador para que podamos leer tu localización en fireeagle y luego envíanos un sms con el texto "fireeagle access" para que confirmemos que todo es correcto:'.to_iso
          RestfulRoutes::Smpp::SmsTransciver.transmit(msisdn, "#{msg} #{url}") unless test

          url
        rescue
          raise FireEagleError, $!
        end        
      end

      def grant_access(msisdn, test = false)
        client = @fe_credentials[msisdn][:client] if @fe_credentials[msisdn]
        raise FireEagleError, 'msisdn not registered' unless client
        
        begin
          access_token = client.convert_to_access_token
          @fe_credentials[msisdn][:access_token] = access_token

          RestfulRoutes::Smpp::SmsTransciver.transmit(msisdn, "gracias por darnos acceso a fireeagle, ahora puedes obviar tu dirección y nosotros te intentamos localizar.".to_iso) unless test
        rescue
          raise FireEagleError, $!
        end
      end

      def locate(msisdn)
        access_token = @fe_credentials[msisdn][:access_token]
        return nil unless access_token
        
        begin
          location = access_token.get(RestfulRoutes::FIRE_EAGLE_USER_URL)

          json = JSON.parse(location.body)

          #en la posición 0 siempre se encuentra la última localización más exacta dentro de una ciudad.
          coords = json['user']['location_hierarchy'][0]['geometry']['coordinates'] if json['stat'] == 'ok' && 
            json['user']['location_hierarchy'] &&
            json['user']['location_hierarchy'][0]['level_name'] == 'exact'

          coords[0..1].reverse if coords
        rescue => error
          raise FireEagleError, error.backtrace.join("\n")
        end
      end

    end
  end
end
