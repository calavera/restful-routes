$:.unshift File.join(File.dirname(__FILE__),'lib')

module RestfulRoutes
  %w{rubygems net/http uri cgi json fireeagle}.each {|gem| require gem}
  
  require 'logger'
  require 'util'
  require 'polyline_decoder'
  require 'algebra'

  %w{locator gps smpp}.each do |dir|
    Dir[ File.join(File.dirname(__FILE__), 'lib', dir, '/*.rb')].sort.each { |file| require file }
  end
  
  require 'sms'
  require 'sms_parser'
  require 'route'
  require 'pop3'
  require 'wasting_time'

  LOG_LEVEL = RestfulRoutes::LOG_LEVELS[:debug]

  POP_SERVER = 'mail.restfulroutes.com'

  POP_CREDENTIALS = {:username => 'taxiomf@restfulroutes.com', :password => 'taxiOMFtaxiOMF'}

  FIRE_EAGLE_USER_URL = 'https://fireeagle.yahooapis.com/api/0.1/user.json'

  FIRE_EAGLE_CREDENTIALS = {
    :consumer_key => 'hzM6MGK9bdzA', :consumer_secret => 'dRp4gdXSOLa9LCmn0xrGTwFMdBDqHJK4'
  }
  
  OOS_CREDENTIALS = {
    :appToken => '43f958619515903cb041566d5ca466b8', :secret_key => '6d8b4dae75bc303cb9fc4d31834f5acd'
  }

  MOVISTAR_CREDENTIALS = {:username => '660007961', :password => '297911'}
  MOVISTAR_PRIVATE_CREDENTIALS = {:username => '650075813', :password => 'Jet48qiy'}
  
  LOCALIZAME_CREDENTIALS = {:username => '650075813', :password => '75662'}
  
  GMAPS_API_KEY = 'ABQIAAAAh6iKXeHf6uR8To-PqSTlFhT2yXp_ZAY8_ufC3CFXhHIE1NvwkxT4tDxF0QqxuHMk6f9VGUGAUsDvQw'

  #Aunque google map ya soporta rutas a pie la api no tiene esta funcionalidad todavía.
  #En la siguiente dirección avisan de que ya la tienen preparada pero no la han puesto en producción todavía:
  #    http://code.google.com/p/gmaps-api-issues/issues/detail?id=195#c22
  #
  #Una vez puesta en producción esta funcionalidad solo habría que cambiar esta constante para que la
  #aplicación sirva rutas a pie.
  GMAPS_WALKING_DIRECTIONS_AVAILABLE = false

end

class String
  def to_iso
    self.unpack("U*").pack("C*")
  end
end
