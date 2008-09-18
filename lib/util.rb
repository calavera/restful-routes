module RestfulRoutes
  module Util
    require 'open-uri'
    
    TINYURL = 'http://tinyurl.com/api-create.php?url=%s'
    ISGD = 'http://is.gd/api.php?longurl=%s'

    LOGGER = RestfulRoutes::Logger.new

    def html2text(html) 
      html.gsub(/(&nbsp;|\n|\s)+/im, ' ').squeeze(' ').strip.gsub(/\<.*?\>/, '')
    end

    def tiny_url(url)
      begin
        url = open(ISGD % CGI.escape(url)).read
      rescue
        LOGGER.debug $!
        begin
          url = open(TINYURL % CGI.escape(url)).read
        rescue
          LOGGER.debug $!
          #returns the complete url
        end
      end
      LOGGER.debug url
      url
    end
  end
end
