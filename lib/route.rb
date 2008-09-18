
module RestfulRoutes
  require 'json'

  class Route
    include RestfulRoutes::Util
    
    attr_accessor :wasting_time
    
    def initialize(json)
      @json = json
    end
    
    def status
      @json['Status']['code']
    end
    
    def duration
      html2text(@json['Directions']['Duration']['html'])
    end

    def seconds
      @json['Directions']['Duration']['seconds']
    end
    
    def from
      @json['Placemark'][0]['address']
    end
    
    def to
      @json['Placemark'][1]['address']
    end

    def polyline
      @polyline ||= RestfulRoutes::PolylineDecoder.decode(@json['Directions']['Polyline']['points']) if @json['Directions']['Polyline']
    end

    def points_between(coords_a, coords_b)
     index_a = polyline.index(coords_a.join(","))
     index_b = polyline.index(coords_b.join(",")) || (polyline.size - 1)
     polyline[index_a +1..index_b +1] if index_a && index_b
    end

    def end_coordinates
      @json['Directions']['Routes'][0]['End']['coordinates'][0..1].reverse
    end
    
    def steps
      @steps ||= @json['Directions']['Routes'][0]['Steps'].map do |step|
        Step.new(step)
      end
    end
    
    def taxi_subject
      "tu taxi llegará en #{duration}".to_iso
    end
    
    def taxi_message(services)
      msg = "tu taxi llegará en #{duration}"
      if (services)
        msg += ", puedes esperar tomándote algo en los sitios que te recomendamos:\n\n"
        msg += RestfulRoutes::WastingTime.pretty_print(services)
      end
      msg += "\n\nsi no queres esperar mándanos otro sms con la palabra WALK seguido de #TO más la dirección a donde quieres ir y nosotros te enviamos la ruta a pie más corta que conocemos, junto a los mejores sitios donde tomar algo y descansar"
      msg += "\n\ngracias por usar nuestro servicio"
      msg.to_iso
    end

    def walk_subject
      "ruta para ir desde #{from} a #{to}".to_iso
    end

    def walk_message
      msg = "a continuación te detallamos la ruta a seguir para ir desde #{from} a #{to}"
      
      msg += "\n\nrecuerda que siempre puedes hacer una parada en uno de los sitios que te proponemos"
      msg += "\n\ngracias por usar nuestro servicio"
      msg.to_iso
    end

    def to_s
      JSON.pretty_generate(@json)
    end
  end
  
  class Step    
    include RestfulRoutes::Util
    
    def initialize(json)
      @json = json
    end
    
    def description(services = nil)
      msg = html2text(@json['descriptionHtml'])

      if (services)
        msg += "\n\npuedes descansar tomándote algo en los sitios que te recomendamos:\n\n"
        msg += RestfulRoutes::WastingTime.pretty_print(services)
      end

      msg.to_iso
    end
    
    def distance
      html2text(@json['Distance']['html'])
    end
    
    def duration
      html2text(@json['Duration']['html'])
    end

    def coordinates
      @json['Point']['coordinates'][0..1].reverse
    end
  end
end
