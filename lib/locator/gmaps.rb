module RestfulRoutes
  class LocalizerError < StandardError; end
  
  module Locator
    require 'digest/md5'
    
    class Gmaps
    
      MARKET_COLOR = %w{purple yellow blue green orange}
    
      def self.route(from, to, walking = false)
        from = CGI.escape(from)
        to = CGI.escape(to)      

        maps_url = "http://maps.google.com/maps/nav?hl=es&gl=es&output=js&oe=utf8&q=from%3A#{from}+to%3A#{to}&gl=ES"
        maps_url += "&dirflg=w" if walking && RestfulRoutes::GMAPS_WALKING_DIRECTIONS_AVAILABLE

        json = connect(maps_url)      
        json ? RestfulRoutes::Route.new(json) : nil
      end

      def self.locate(address)
        address = CGI.escape(address)
        maps_url = "http://maps.google.es/maps/geo?hl=es&gl=es&output=js&q=#{address}&oe=utf8"
      
        json = connect(maps_url)
           
        json ? json['Placemark'][0]['Point']['coordinates'][0..1].reverse : nil
      end
    
      def self.static_map(options)
        params = options.map {|k, v| k.to_s + '=' + CGI.escape(v.to_s)} * '&'
        maps_url = "http://maps.google.com/staticmap?size=250x250&maptype=mobile&#{params}" +
          "&key=#{RestfulRoutes::GMAPS_API_KEY}" #&zoom=16
        
        file_path = "#{Digest::MD5.hexdigest(maps_url)}.gif"
        #cached maps
        return File.open(file_path) if File.exist?(file_path)
        
        resp = Net::HTTP.get_response(URI.parse(maps_url))
        raise StandardError, "static maps error: #{resp}" unless resp.is_a?(Net::HTTPSuccess)
        
        file = File.new(file_path, 'w')
        file.write(resp.body)
        file.close
        file
      end
   
      private 
      def self.connect(url)
        uri = URI::parse(url)
      
        res = Net::HTTP.start(uri.host, uri.port) {|http|
          req = Net::HTTP::Get.new(uri.path + '?' + uri.query)
          req['User-Agent'] = 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)'

          http.request(req)
        }
      
        return nil unless res.instance_of?(Net::HTTPOK)
        json = JSON.parse(res.body)
        
        return json['Status']['code'].to_i == 200? json : nil
      end
    
    end
  end
end
