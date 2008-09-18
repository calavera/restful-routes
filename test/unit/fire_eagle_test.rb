require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'mechanize'

class FireEagleTest < Test::Unit::TestCase

  FIRE_EAGLE_TEST_USER = 'taxiomf@yahoo.com'
  FIRE_EAGLE_TEST_PASSWORD = 'TOMFtomf'

  context 'fire eagle' do
    setup do
      @agent = WWW::Mechanize.new
      @agent.user_agent_alias = 'Windows IE 7'
    end

    should 'locate a msisdn' do
      @fire_eagle = RestfulRoutes::Locator::FireEagleClient.new
      assert_nothing_raised { 
        url = @fire_eagle.register('686470476', true)
        page = @agent.get(URI.parse(url))

        if (page.form(:name => 'login_form'))
          page = page.form(:name => 'login_form') do |form|
            form.login = FIRE_EAGLE_TEST_USER
            form.passwd = FIRE_EAGLE_TEST_PASSWORD
          end.submit
        end

        if (page.form(:name => 'authorize'))
          form = page.form(:name => 'authorize')
          response = form.click_button

          @fire_eagle.grant_access('686470476', true)
          assert_equal([40.4183349609, -3.6994876862], @fire_eagle.locate('686470476'))
        end
      }
    end

  end
end
