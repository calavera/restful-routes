require File.join(File.dirname(__FILE__), '..', 'test_helper')

class GmapsTest < Test::Unit::TestCase
  
  context('route') do
    should 'not be nil' do
      assert_not_nil(go_to_home)
    end

    should 'go on 4 minutes' do
      assert_equal('4 min', go_to_home.duration)
    end

    should 'not raise an exception' do
      assert_nothing_raised {
        go_to_home(true)
      }
    end

    should 'include a polyline' do
      assert_nothing_raised { go_to_home.polyline }
    end

    should 'include a polyline with endpoints' do
      route = go_to_home
      assert route.points_between(route.steps[0].coordinates, route.steps[1].coordinates).size > 0
    end
  end
  
  context 'steps' do
    should 'not be nil' do
      assert_equal(6, go_to_home.steps.size)
    end
  end 
 
  context 'first step' do
    should 'go on 0,2 km' do
      assert_equal('0,2 km', go_to_home.steps[0].distance)
    end
    
    should 'include description' do
      assert_not_nil(go_to_home.steps[0].description)
    end
  end 
  
  context 'geo' do
    should 'return json' do
      assert_not_nil(RestfulRoutes::Locator::Gmaps.locate("virgen de los peligros 3, Madrid"))
    end
  end 
  
  context 'static map' do
    should 'create a map file' do
      coords = RestfulRoutes::Locator::Gmaps.locate("virgen de los peligros 3, Madrid")
      assert_not_nil(RestfulRoutes::Locator::Gmaps.static_map(:center => coords.join(",")))
    end
    
    should 'write markers' do
      coordinates = RestfulRoutes::Locator::Gmaps.locate("divino pastor 10, Madrid")
      
      wasting_time = RestfulRoutes::WastingTime.locate_near(coordinates)
      services = []
      wasting_time.each_with_index do |service, index|
        services << "#{service.latitude},#{service.longitude},#{RestfulRoutes::Locator::Gmaps::MARKET_COLOR[index]}#{('a'..'e').to_a[index]}"
      end
      
      #get the services map
      map = RestfulRoutes::Locator::Gmaps.static_map(:center => coordinates.join(","), 
        :markers => services.join("|"))
    end
  end
  
  def go_to_home(walk = false)
    RestfulRoutes::Locator::Gmaps.route("virgen de los peligros 3, Madrid", "Divino Pastor 10, Madrid", walk)
  end

end
