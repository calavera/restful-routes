module RestfulRoutes
  class TaxiControl
    
    GPS = RestfulRoutes::Gps::FakeGps.new    
    LOGGER = RestfulRoutes::Logger.new

    def self.instance
      @@control ||= RestfulRoutes::TaxiControl.new
    end

    def self.start
      loop do
        begin
          instance.run
        rescue => error
          LOGGER.error error.message
          LOGGER.error error.backtrace.join("\n")
        end
        sleep(5)
      end
    end

    def initialize
      @fire_eagle_client = RestfulRoutes::Locator::FireEagleClient.new
    end

    def run
      new_mails = RestfulRoutes::Pop3.check
      LOGGER.info "reading #{new_mails.size} new messages" unless new_mails.empty?

      new_mails.each do |mail|
        fire_eagle_option = register_fire_eagle_options(mail)
        locate_route(mail) unless fire_eagle_option
      end
    end

    def register_fire_eagle_options(mail)
      LOGGER.debug "registering fireeagle options: #{mail}"
      option = SMSParser.parse_fire_eagle_option(mail)
      LOGGER.debug "option: #{option}"
      if (option)
        sms = SMSParser.parse_sender(mail)
        return option unless sms.msisdn
        
        if (option == 'register')
          LOGGER.info "registering new fireeagle user: #{sms.msisdn}"
          @fire_eagle_client.register(sms.msisdn)
        else
          LOGGER.info "granting fireeagle access: #{sms.msisdn}"
          @fire_eagle_client.grant_access(sms.msisdn)
        end
      end
      option
    end
    
    def locate_route(mail)
      sms = RestfulRoutes::SMSParser.parse(mail)
      LOGGER.info "locating route for: #{sms}"

      return send_sms_message(sms.msisdn, 'no hemos entendido tu sms, por favor introduce las palabras clave'.to_iso) unless sms.key
      
      coordinates = RestfulRoutes::Locator::Base.locate(sms, @fire_eagle_client)
      return send_sms_message(sms.msisdn, 'no hemos podido localizarte, prueba enviándonos la dirección exacta'.to_iso) unless coordinates
      LOGGER.info "user #{sms.msisdn} located in #{coordinates}"

      route = GPS.locate_best_route_to(sms, coordinates)
      return send_sms_message(sms.msisdn, 'no entendemos tu mensaje, quizá no sabemos llegar a donde nos pides. Por favor comprueba que es correcto'.to_iso) unless route

      LOGGER.info "sending #{sms.key} route to #{sms.msisdn}"
      send_route(sms, coordinates, route)
    end
    
    def send_route(sms, coordinates, route)
      mms = RestfulRoutes::Smpp::MmsTransciver.new
      mms.transmit(sms, coordinates, route)
    end
    
    def send_sms_message(msisdn, message)
      RestfulRoutes::Smpp::SmsTransciver.transmit(msisdn, message)
    end
  end
end

RestfulRoutes::TaxiControl.start
