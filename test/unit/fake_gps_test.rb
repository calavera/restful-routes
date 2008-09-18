require File.join(File.dirname(__FILE__), '..', 'test_helper')

class FakeGpsTest < Test::Unit::TestCase   
  context('client') do
    setup do
      @fake_gps = RestfulRoutes::Gps::FakeGps.new
    end

    should ('get_the_nearest_taxi') do
      coords = RestfulRoutes::Locator::Gmaps.locate('Virgen de los peligros 3, madrid')
      taxi = @fake_gps.locate_taxi_near(coords)
      assert_not_nil(taxi)
    end
  end
end
