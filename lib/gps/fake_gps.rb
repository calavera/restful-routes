module RestfulRoutes  
  module Gps    
    class FakeGps
      include Algebra

      def initialize(taxis = 10)
        @fake_taxis = taxis
      end
      
      def locate_best_route_to(sms, coordinates)
        route = nil
        if sms.key == 'taxi'
          route = locate_taxi_near(coordinates)
        elsif sms.key == 'walk'
          destination = RestfulRoutes::Locator::Gmaps.locate(sms.to) if sms.to
          route = RestfulRoutes::Locator::Gmaps.route(coordinates.join(","), destination.join(","), true) if destination
        end
        route
      end

      def locate_taxi_near(coordinates)
        min_route = nil
        locate_taxis(coordinates).each do |taxi|
          route = Locator::Gmaps.route(taxi.join(", "), coordinates.join(","))
          min_route = route unless min_route && min_route.seconds < route.seconds
        end
        min_route.wasting_time = true if min_route
        min_route 
      end
      
      private
      def locate_taxis(coordinates, radius = 3)
        random_points_into_a_circumference(coordinates, radius)
      end

    end
  end
end
