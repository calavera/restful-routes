module RestfulRoutes
  module Locator
    
    class LocalizameApiError < StandardError; end
    
    class LocalizameApi
      extend Algebra
      
      LOCALIZAME_API = 'www.localizame.movistar.es'
      
      def self.locate(msisdn, loc_key = nil)
        activate_localizame
        
        grant_credentials(msisdn, loc_key) if loc_key
          
        jsession_id = login(RestfulRoutes::LOCALIZAME_CREDENTIALS[:username], 
          RestfulRoutes::LOCALIZAME_CREDENTIALS[:password])
          
        if (jsession_id)
          coords = localiza(jsession_id, msisdn)
          
          logout(jsession_id)
          return coords
        end
      end
      
      def self.activate_localizame
        RestfulRoutes::Smpp::SmsTransciver.transmit('424', 'CLAVE', 
          RestfulRoutes::MOVISTAR_PRIVATE_CREDENTIALS[:username],
          RestfulRoutes::MOVISTAR_PRIVATE_CREDENTIALS[:password])
      end
      
      def self.localiza(jsession_id, msisdn)
        Net::HTTP.start(LOCALIZAME_API) do |http|
          req = post_request('/buscar.do', 'application/x-www-form-urlencoded')
          req['Cookie'] = "JSESSIONID=#{jsession_id}"
          
          resp = http.request(req, "telefono=#{msisdn}")
          
          if (resp.is_a?(Net::HTTPSuccess))
            return coords(resp.body.downcase)
          end
        end if jsession_id
        return nil
      end
      
      def self.coords(body)
         if body.match(/.+<iframe>.+/)
            url = body.gsub(/.+<iframe>(.+)<\/iframe>.+/, '\1').gsub(/(.+)src="([^"]+)"(.+)/, '\2')

            if (url)
              coords = CGI.parse(URI.parse(url).query).select {|k, v| k == 'x' || k == 'y'}
              return coords ? utm2latlon(coords['x'], coords['y']) : nil
            end
          end
      end
      
      def self.grant_credentials(msisdn, loc_key)
        jsession_id = login(msisdn, loc_key)
        new_user(jsession_id)
        auth(jsession_id, RestfulRoutes::LOCALIZAME_CREDENTIALS[:username])
        logout(jsession_id)
        jsession_id
      end
      
      def self.login(msisdn, key)
        Net::HTTP.start(LOCALIZAME_API) do |http|
          req = post_request("/login.do?clave=#{key}&usuario=#{msisdn}",
            'application/x-www-form-urlencoded')
            
          resp = http.request(req)
          return nil unless resp['set-cookie']
          
          jsession_id = resp['set-cookie'].split(" ").select{|k| k.split("=")[0] == 'JSESSIONID'}
          jsession_id.first.split("=")[1] unless jsession_id.empty?
        end
      end
      
      def self.new_user(jsession_id)
        Net::HTTP.start(LOCALIZAME_API) do |http|
          req = get_request('/nuevousuario.do')
          req['Cookie'] = "JSESSIONID=#{jsession_id}"
          req['referer'] = 'http://www.localizame.movistar.es/login.do'
          
          http.request(req)
        end
      end
      
      def self.auth(jsession_id, msisdn)
        Net::HTTP.start(LOCALIZAME_API) do |http|
          req = get_request("/insertalocalizador.do?telefono=#{msisdn}")
          req['Cookie'] = "JSESSIONID=#{jsession_id}"
          req['referer'] = 'http://www.localizame.movistar.es/buscalocalizadorespermisos.do'
          
          http.request(req)
        end
      end
      
      def self.logout(jsession_id)
        Net::HTTP.start(LOCALIZAME_API) do |http|
          req = get_request('/logout.do')
          req['Cookie'] = "JSESSIONID=#{jsession_id}"
          
          http.request(req)
        end
      end
      
      def self.get_request(url)
        req = Net::HTTP::Get.new(url)
        common_headers.each {|k, v| req[k] = v}
        req
      end
      
      def self.post_request(url, content_type)
        req = Net::HTTP::Post.new(url)
        common_headers.each {|k, v| req[k] = v}
        req['Content-Type'] = content_type
        req
      end
      
      def self.common_headers
        headers = {}
        headers['Accept-Encoding'] = 'identity'
        headers['Connection'] = 'Keep-Alive'
        headers['User-Agent'] = 'Mozilla/4.0 (compatible MSIE 6.0 Windows NT 5.0 .NET CLR 1.1.4322 .NET CLR 2.0.50727)'
        headers['Accept'] = 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/vnd.ms-powerpoint, application/vnd.ms-excel, application/msword, application/x-shockwave-flash, */*'
        headers['Accept-Language'] = 'es'
        headers
      end
      
      UTM_SCALE_FACTOR = 0.9996
      AXIS_MAJOR = 6378137.0
      AXIS_MINIOR = 6356752.314
      
      def self.utm2latlon(x, y, zone = 30)
        x = x.to_f
        y = y.to_f

        x -= 500000.0
        x /= UTM_SCALE_FACTOR

        y /= UTM_SCALE_FACTOR

        central_meridian = deg2rad(-183.0 + (zone * 6.0))

        phif = foot_point_latitude(y)
        	
        ep2 = ((AXIS_MAJOR ** 2.0) - (AXIS_MINIOR ** 2.0)) / (AXIS_MINIOR ** 2.0)
        	
        cf = Math.cos(phif)
        	
        nuf2 = ep2 * (cf ** 2.0)
        	
        nf = (AXIS_MAJOR ** 2.0) / (AXIS_MINIOR * Math.sqrt(1 + nuf2))
        nf_pow = nf
        	
        tf = Math.tan(phif)
        tf2 = tf * tf
        tf4 = tf2 * tf2
        
        x1frac, x2frac, x3frac, x4frac, x5frac, x6frac, x7frac, x8frac = nil
        
        [1.0, 2.0, 6.0, 24.0, 120.0, 720.0, 5040.0, 40320.0].each_with_index do |value, index|
          nf_pow *= nf if index > 0

          dividend = (index % 2 != 0)?tf : 1.0
          divisor = (index % 2 != 0)?(value * nf_pow) : (value * nf_pow * cf)

          eval("x#{index + 1}frac = #{dividend} / #{divisor}", binding, __FILE__, __LINE__)
        end

        x2poly = -1.0 - nuf2
        
        x3poly = (-1.0 - 2) * (tf2 - nuf2)
        
        x4poly = 5.0 + (3.0 * tf2) + (6.0 * nuf2) - (6.0 * tf2 * nuf2) - (3.0 * (nuf2 ** 2)) - (9.0 * tf2 * (nuf2 ** 2))
        
        x5poly = 5.0 + (28.0 * tf2) + (24.0 * tf4) + (6.0 * nuf2) + (8.0 * tf2 * nuf2)
        
        x6poly = -61.0 - (90.0 * tf2) - (45.0 * tf4) - (107.0 * nuf2) + (162.0 * tf2 * nuf2)
        
        x7poly = -61.0 - (662.0 * tf2) - (1320.0 * tf4) - (720.0 * (tf4 * tf2))
        
        x8poly = 1385.0 + (3633.0 * tf2) + (4095.0 * tf4) + (1575 * (tf4 * tf2))
        
        latitude = phif + (x2frac * x2poly * (x ** 2)) + (x4frac * x4poly * (x ** 4.0)) + (x6frac * x6poly * (x ** 6.0)) + (x8frac * x8poly * (x ** 8.0))
        	
        longitude = central_meridian + (x1frac * x) + (x3frac * x3poly * (x ** 3.0)) + (x5frac * x5poly * (x ** 5.0)) + (x7frac * x7poly * (x ** 7.0))
        
        [rad2deg(latitude).to_s, rad2deg(longitude).to_s]
      end

      def self.foot_point_latitude(y)
        n = (AXIS_MAJOR - AXIS_MINIOR) / (AXIS_MAJOR + AXIS_MINIOR)
        	
        alpha_ = ((AXIS_MAJOR + AXIS_MINIOR) / 2.0) * (1 + ((n ** 2) / 4) + ((n ** 4) / 64))
        
        y_ = y / alpha_
        
        beta_ = (3.0 * n / 2.0) + (-27.0 * (n ** 3.0) / 32.0) + (269.0 * (n ** 5.0) / 512.0)
        
        gamma_ = (21.0 * (n ** 2.0) / 16.0) + (-55.0 * (n ** 4.0) / 32.0)
        	
        delta_ = (151.0 * (n ** 3.0) / 96.0) + (-417.0 * (n ** 5.0) / 128.0)
        	
        epsilon_ = (1097.0 * (n ** 4.0) / 512.0)
        	
        return y_ + (beta_ * Math.sin(2.0 * y_)) + (gamma_ * Math.sin(4.0 * y_)) + (delta_ * Math.sin(6.0 * y_)) + (epsilon_ * Math.sin(8.0 * y_))
      end
=begin
      def self.utm2latlon(f, f1, j = 30)
        d = 0.99960000000000004
        d1 = 6378137
        d2 = 0.0066943799999999998

        d4 = (1 - Math.sqrt(1 - d2)) / (1 + Math.sqrt(1 - d2))
        d15 = f1 - 500000
        d16 = f
        d11 = ((j - 1) * 6 - 180) + 3
        d3 = d2 / (1 - d2)
        d10 = d16 / d
        d12 = d10 / (d1 * (1 - d2 / 4 - (3 * d2 * d2) / 64 - (5 * (d2**3) ) / 256))
        d14 = d12 + ((3 * d4) / 2 - (27 * (d4**3) ) / 32) * Math.sin(2 * d12) + ((21 * d4 * d4) / 16 - (55 * (d4**4) ) / 32) * Math.sin(4 * d12) + ((151 * (d4**3) ) / 96) * Math.sin(6 * d12)
        d13 = rad2deg(d14)
        d5 = d1 / Math.sqrt(1 - d2 * Math.sin(d14) * Math.sin(d14))
        d6 = Math.tan(d14) * Math.tan(d14)
        d7 = d3 * Math.cos(d14) * Math.cos(d14)
        d8 = (d1 * (1 - d2)) / ((1 - d2 * Math.sin(d14) * Math.sin(d14))**1.5)
        d9 = d15 / (d5 * d)
        d17 = d14 - ((d5 * Math.tan(d14)) / d8) * (((d9 * d9) / 2 - (((5 + 3 * d6 + 10 * d7) - 4 * d7 * d7 - 9 * d3) * (d9**4) ) / 24) + (((61 + 90 * d6 + 298 * d7 + 45 * d6 * d6) - 252 * d3 - 3 * d7 * d7) * (d9**6) ) / 720)
        d17 = rad2deg(d17)
        d18 = ((d9 - ((1 + 2 * d6 + d7) * (d9**3) ) / 6) + (((((5 - 2 * d7) + 28 * d6) - 3 * d7 * d7) + 8 * d3 + 24 * d6 * d6) * (d9**5) ) / 120) / Math.cos(d14)
        d18 = d11 + rad2deg(d18)
        return [d17, d18]
      end
=end
    end
  end
end
