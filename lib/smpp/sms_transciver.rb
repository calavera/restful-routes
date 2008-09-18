module RestfulRoutes
  module Smpp
  class SmsTransciver
    
    SENDER_URL = 'https://opensms.movistar.es/aplicacionpost/loginEnvio.jsp'
    
    def self.transmit(msisdn, message, login = RestfulRoutes::MOVISTAR_CREDENTIALS[:username], 
        password = RestfulRoutes::MOVISTAR_CREDENTIALS[:password])
      Net::HTTP.post_form(URI.parse(SENDER_URL),
        {
          'TM_ACTION' => 'AUTHENTICATE',
          'TM_LOGIN' =>  login,
          'TM_PASSWORD' => password,
          'to' => msisdn,
          'message' => message
        }
       )
    end
    
  end
  end
end
