require File.join(File.dirname(__FILE__), '..', 'test_helper')

class LocalizameApiTest < Test::Unit::TestCase
  
  context 'localizame' do
    should 'return UMT coordinates' do
      assert_nothing_raised { RestfulRoutes::Locator::LocalizameApi.locate('650075813') }
    end
    
    should 'parse the iframe' do
      body = "<body><iframe><img src=\"http://asdfasdfsd.com?X=844744&Y=24523&z=sdfhfh\"/></iframe></body>"
      coords = body.downcase!.gsub(/.+<iframe>(.+)<\/iframe>.+/, '\1').gsub(/(.+)src="([^"]+)"(.+)/, '\2')
      
      coords = CGI.parse(URI.parse(coords).query).select {|k, v| k == 'x' or k == 'y'}
      assert_equal(2, coords.size)
    end
    
    should 'activate localizame api' do
      assert_nothing_raised { RestfulRoutes::Locator::LocalizameApi.activate_localizame }
    end

    should 'parse utm coordinates' do
      assert_equal(['40.4182319999986', '-3.69951192380233'],  RestfulRoutes::Locator::LocalizameApi.utm2latlon(440655.7624945792, 4474413.442571908))
    end
  end
  
end
