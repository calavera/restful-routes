require 'net/pop'

module RestfulRoutes
  require 'tmail'

  class Pop3
    def self.check
      mails = []
      Net::POP3.start(RestfulRoutes::POP_SERVER, 110, RestfulRoutes::POP_CREDENTIALS[:username], RestfulRoutes::POP_CREDENTIALS[:password]) do |pop|      
        pop.each_mail { |m|
          mail_message = TMail::Mail.parse(m.pop)
          mails << mail_message.body
          m.delete! 
        } unless pop.mails.empty?
      end     
      mails
    end
  end
end
