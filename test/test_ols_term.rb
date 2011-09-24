require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Term object' do
    should 'be created via the OLS class methods' do
      mp_0 = OLS.root_terms('MP').first
      assert mp_0.is_a? OLS::Term
      assert_equal 'MP:0000001', mp_0.id

      emap_0 = OLS.find_by_id('EMAP:0')
      assert emap_0.is_a? OLS::Term
      assert_equal 'Mouse_anatomy_by_time_xproduct', emap_0.name

      ma_0 = OLS.find_by_name('mouse anatomical entity')
      assert ma_0.is_a? OLS::Term
      assert_equal 'MA:0000001', ma_0.id
    end

    # context 'once created' do
    #   setup do
    #     @term = OLS.find_by_id('EMAP:3018')
    #   end

    #   should '' do

    #   end
    # end
  end
end

