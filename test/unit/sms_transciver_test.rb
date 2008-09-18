require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SmsTransciverTest < Test::Unit::TestCase
  context 'sms transciver' do
    should 'send an sms' do
      assert_nothing_raised { RestfulRoutes::Smpp::SmsTransciver.transmit('686470476', 'sms test') }
    end

    should 'send an sms with my own credentials' do
      assert_nothing_raised { RestfulRoutes::Smpp::SmsTransciver.transmit('686470476', 'test con mi numero', '650075813', 'Jet48qiy') }
    end
  end
end
