require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SmsParserTest < Test::Unit::TestCase
  
#Movil:34686470476
#Texto:Taxi #from virgen de los peligros 3 #name david

  def parse_taxi
    RestfulRoutes::SMSParser.parse('taxi #from virgen de los peligros #name david')
  end
  
  def parse_walk_1
    RestfulRoutes::SMSParser.parse('walk #to divino pastor 3, madrid')
  end
  
  def parse_walk_2
    RestfulRoutes::SMSParser.parse('walk #from virgen de los peligros 10 #to divino pastor 3, madrid')
  end

  def parse_mail
    ["Movil:683353345\nTexto:taxi"]
  end

  context 'parser' do
    should 'return at least a mail' do
      assert(parse_mail.size > 0)
    end

    should 'parse taxi regex' do
      assert_equal('taxi', parse_taxi.key)
      assert_equal('virgen de los peligros', parse_taxi.from)
      assert_equal('david', parse_taxi.name)
    end

    should 'parse walk command without from key' do
      assert_equal('walk', parse_walk_1.key)
      assert_nil(parse_walk_1.from)
      assert_equal('divino pastor 3, madrid', parse_walk_1.to)
      assert_nil(parse_walk_1.loc_key)
    end

    should 'parse walk command with from key' do
      assert_equal('walk', parse_walk_2.key)
      assert_equal('virgen de los peligros 10', parse_walk_2.from)
      assert_equal('divino pastor 3, madrid', parse_walk_2.to)  
    end

    should 'parse fireeagle option' do
      assert_equal('register', RestfulRoutes::SMSParser.parse_fire_eagle_option('movil: 624463643\nfireeagle register'))
    end
    
    should 'parse localizame key' do
      assert_not_nil(RestfulRoutes::SMSParser.parse('walk #to divino pastor 3, Madrid #loc 34456').loc_key)
      assert_not_nil(RestfulRoutes::SMSParser.parse('taxi #from virgen de los peligros #name david #loc 3445').loc_key)
    end

    should 'parse fireeagle option from mail' do
      assert_not_nil RestfulRoutes::SMSParser.parse_fire_eagle_option("Movil:650075813\nTexto:fireeagle register")
      assert_not_nil RestfulRoutes::SMSParser.parse_sender("Movil:686470476\nTexto:fireeagle register").msisdn      
    end

    should 'parse mail in capital letters' do
      assert_not_nil RestfulRoutes::SMSParser.parse_fire_eagle_option("MOVIL:650075813\nTEXTO:FIREEAGLE REGISTER")
    end
  end

  context 'sms' do
    should 'include msisdn' do
      sms = RestfulRoutes::SMSParser.parse_sender(parse_mail.first)
      assert_not_nil(sms.msisdn, 'msisdn should not be nil')
    end
  end
end
