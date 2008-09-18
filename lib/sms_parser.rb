module RestfulRoutes
  class SMSParser
    
    FIRE_EAGLE_REGEX = /.*fireeagle\s(register|access).*/i
    MAIL_SENDER_REGEX = /.*from:(\s)?(".+")?(\s)?<(.+)>/i
    MOBILE_REGEX = /.*movil:([0-9]+).*/i
    TAXI_REGEX = /.*(taxi)(\s)?(#from\s([^#-]+))?(#name\s([^#-]+))?(#loc\s(.+))?(\n|\r|\r\n)?/i
    WALKING_REGEX = /.*(walk)\s(#from\s([^#-]+))?#to\s([^#-]+)(#loc\s(.+))?(\n|\r|\r\n)?/i
    
    def self.parse(message)
      sms = parse_body(message)
      parse_sender(message, sms)
    end

    def self.parse_mails(mails)
      parsed = mails.map do |mail|
        sms = parse(mail)
      end.compact
    end

    def self.parse_fire_eagle_option(message)
      if matcher = FIRE_EAGLE_REGEX.match(message)
        return matcher[1]
      end
    end

    def self.parse_body(message)
      sms = parse_taxi(message)
      sms = parse_walk(message) unless sms
      sms
    end
    
    def self.parse_taxi(message)
      if matcher = TAXI_REGEX.match(message)
        sms = RestfulRoutes::Sms.new
        sms.key = matcher[1].downcase
        sms.from = matcher[4].strip if matcher[4]
        sms.name = matcher[6].strip if matcher[6]
        sms.loc_key = matcher[8].strip if matcher[8]
        return sms
      end
    end
    
    def self.parse_walk(message)
      if matcher = WALKING_REGEX.match(message)
        sms = RestfulRoutes::Sms.new
        sms.key = matcher[1].downcase
        sms.from = matcher[3].strip if matcher[3]
        sms.to = matcher[4].strip
        sms.loc_key = matcher[6].strip if matcher[6]
        return sms
      end
    end

    def self.parse_sender(message, sms = nil)
      sms = RestfulRoutes::Sms.new unless sms
      if matcher = MOBILE_REGEX.match(message)
        
        sms.msisdn = (matcher[1].size == 11?'+' : '') + matcher[1]
      end
      sms
    end
  end
end
