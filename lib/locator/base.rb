module RestfulRoutes
  module Locator
    class Base
      
      def self.locate(sms, fire_eagle_client)
        coordinates = Locator::Gmaps.locate(sms.from) if sms.from
          
        coordinates = fire_eagle_client.locate(sms.msisdn) if !coordinates && fire_eagle_client.granted?(sms.msisdn)

        coordinates = Locator::LocalizameApi.locate(sms.msisdn, sms.loc_key) unless coordinates
        
        coordinates
      end
    
    end
  end
end
