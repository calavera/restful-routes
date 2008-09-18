require File.join(File.dirname(__FILE__), '..', 'test_helper')

class MmsTransciverTest < Test::Unit::TestCase
  context 'mms transciver' do
    setup do
      @gps = RestfulRoutes::Gps::FakeGps.new
    end
    
    should 'send a mms' do
      assert_nothing_raised {
        sms = RestfulRoutes::Sms.new
        sms.key = 'taxi'
        sms.msisdn = '650075813'
      
        send_mms(sms)
      }
    end

    should 'send a mms with multiple pages' do
      assert_nothing_raised {  
        sms = RestfulRoutes::Sms.new
        sms.key = 'walk'
        sms.msisdn = '650075813'
        sms.to = 'divino pastor 10, madrid'

        send_mms(sms)
      }
    end
    
  end

  def send_mms(sms)
    coords = RestfulRoutes::Locator::Gmaps.locate("virgen de los peligros 3, madrid")
    route = @gps.locate_best_route_to(sms, coords)
      
    mms = RestfulRoutes::Smpp::MmsTransciver.new
    mms.transmit(sms, coords, route)
  end
end
