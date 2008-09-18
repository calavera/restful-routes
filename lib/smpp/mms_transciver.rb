module RestfulRoutes
  module Smpp
    require 'mechanize'
    
    class MmsTransciver

      LOGGER = RestfulRoutes::Logger.new
      
      def initialize
        @agent = WWW::Mechanize.new
        @agent.user_agent_alias = "Windows IE 7"
        @page = @agent.get(URI.parse("http://www.multimedia.movistar.es/authenticate"))

        form = @page.forms.name("loginForm").first
        form.TM_LOGIN = RestfulRoutes::MOVISTAR_CREDENTIALS[:username]
        form.TM_PASSWORD = RestfulRoutes::MOVISTAR_CREDENTIALS[:password]
        @agent.submit(form)
      end
      
      def transmit(sms, coordinates, route)
        @page = @agent.get(URI.parse('http://www.multimedia.movistar.es/do/multimedia/create?l=sp-SP&v=mensajeria'))
        
        LOGGER.info "sending mms to #{sms.msisdn}"
        if (sms.key == 'taxi')
          transmit_taxi_mms(sms, coordinates, route)
        else
          transmit_walk_mms(sms, coordinates, route)
        end
         LOGGER.info "mms sended properly to #{sms.msisdn}"
      end
      
      def transmit_taxi_mms(sms, coordinates, route)
        #get the services map
        LOGGER.debug "uploading map"
        wasting_time = RestfulRoutes::WastingTime.locate_near(coordinates)
        upload_static_map(:center => coordinates.join(","), :markers => markers(wasting_time, coordinates))
        
        send_mms(sms.msisdn, route.taxi_subject, route.taxi_message(wasting_time))
      end
      
      def transmit_walk_mms(sms, coordinates, route)
        #the first page is a summary with the complete map
        LOGGER.debug("creating summary page")
        upload_static_map(:path => "rgb:0x0000ff,weight:5|#{route.polyline.join('|')}") if route.polyline
        new_page(2, route.walk_message)
        
        #la api de envío de mms solo soporta 5 páginas de mms, así que hay que reducir los
        #pasos de la ruta para mostrarla en 4 páginas
        steps = []
        route.steps.each_with_index{|s, i| steps << s if i % ((route.steps.size / 3).ceil) == 0}
        
        steps.each_with_index do |step, index|          
          next_coords = ((steps.size - 1) == index)?route.end_coordinates : steps[index +1].coordinates

          wasting_time = RestfulRoutes::WastingTime.locate_near(step.coordinates, next_coords)
          
          upload_static_map(:path => "rgb:0x0000ff,weight:5|#{path(route, step.coordinates, next_coords)}", 
            :markers => markers(wasting_time, step.coordinates, next_coords))

          new_page(3 + index, step.description(wasting_time))
        end

        send_mms(sms.msisdn, route.walk_subject)
      end
      
      def markers(wasting_time, *coords)
        markers = coords.map {|c| "#{c.join(",")},red"}
        markers << wasting_time_markers(wasting_time) unless wasting_time.empty?
        markers.flatten.join("|")
      end
      
      def path(route, *coords)
        middle_points = route.points_between(coords[0], coords[1])
        (path = []) << coords[0].join(",")
        path << middle_points if middle_points 
        path << coords[1].join(",")
        path.flatten.join("|")
      end

      def send_mms(msisdn, subject, text = nil)
        @page.form(:name => 'mmsForm') do |form|
          form.to = msisdn
          form.subject = subject
          form.text = text if text
          form.action = '/do/multimedia/send?l=sp-SP&v=mensajeria'
        end.submit
      end

      def upload_static_map(options)
        map = RestfulRoutes::Locator::Gmaps.static_map(options)
        upload(map) if map
      end

      def wasting_time_markers(wasting_time)
        services = []
        wasting_time.each_with_index do |service, index|
          services << "#{service.latitude},#{service.longitude},#{RestfulRoutes::Locator::Gmaps::MARKET_COLOR[index]}#{('a'..'e').to_a[index]}"
        end
        services
      end

      def new_page(page, message)
        LOGGER.debug "adding page #{page} to the mms"

        @page = @page.form(:name => 'mmsForm') do |form|
          form.action = "/do/multimedia/slide?l=sp-SP&v=mensajeria&slide=" + page.to_s
          form.text = message
        end.submit
      end
      
      def upload(file)
        LOGGER.debug "uploading #{file.path}"

        upload_page = @agent.get("/do/multimedia/upload?l=sp-SP&v=mensajeria")
        
        upload_page.form(:name => 'mmsComposerUploadItemForm') do |form|
          form.file_uploads.first.file_name = file.path
        end.submit
        
      end
    end
  end
end
