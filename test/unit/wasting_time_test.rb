require File.join(File.dirname(__FILE__), '..', 'test_helper')

class  WastingTimeTest < Test::Unit::TestCase
  
  context 'oos' do
    should 'return places with one point' do
      assert !RestfulRoutes::WastingTime.locate_near(['40.416741', '-3.70325']).empty?
    end

    should 'return places with two points' do
      assert !RestfulRoutes::WastingTime.locate_near(['40.42151', '-3.70795'], ['40.42339', '-3.70751']).empty?
    end
  end
end
