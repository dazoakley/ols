require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Term object' do
    context 'once created' do
      setup do
        @term = OLS.find_by_id('EMAP:3018')
      end

      should 'daslfjakj' do
        true
      end
    end
  end
end

