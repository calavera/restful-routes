module RestfulRoutes
  require 'oos4ruby'
  
  class WastingTime
    extend Algebra
    
    def self.locate_near(*coordinates)
      center_point = coordinates.size == 1?coordinates[0]:midpoint(coordinates[0], coordinates[1])

      oos = Oos4ruby::Oos.new
      oos.auth_app(RestfulRoutes::OOS_CREDENTIALS[:appToken], RestfulRoutes::OOS_CREDENTIALS[:secret_key])
      
      response = oos.search(:lat => center_point[0], :lon => center_point[1], :radius => 0.2,
        :tags => ['bar', 'tapas', 'cañas', 'copas', 'comer'], :tag_op => 'or')
      response[0..4] unless response.empty?
    end

    def self.pretty_print(services)
      msg = ''
      services.each_with_index do |service, index|
        msg += "#{('a'..'e').to_a[index].upcase} - #{service.name}\n\t#{service.user_address}\n"
      end
      msg
    end
  end
end
