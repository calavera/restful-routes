require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'net/smtp'

class Pop3Test < Test::Unit::TestCase
  context 'mail server' do
    setup do
      Net::SMTP.start('mail.restfulroutes.com', 25, 'localhost',
          RestfulRoutes::POP_CREDENTIALS[:username], RestfulRoutes::POP_CREDENTIALS[:password], :login) do |smtp|
        smtp.send_message('test', 'taxiomf@restfulroutes.com', 'taxiomf@restfulroutes.com')
      end
    end

    should 'have a new unreaded email' do
      assert RestfulRoutes::Pop3.check.size > 0
    end

    should 'read the mail body' do
      assert_not_nil RestfulRoutes::Pop3.check.first
    end
  end
end
