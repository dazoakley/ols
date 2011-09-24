require 'test_helper'

class OLSTest < Test::Unit::TestCase
  context 'The OLS module' do
    should 'make a connection to the OLS SOAP service' do
      assert OLS.client
      assert OLS.client.is_a? Savon::Client
    end

    should 'give access to version metadata' do
      assert OLS.version
      assert OLS.version.is_a? String
    end

    should 'list the available ontologies' do
      assert OLS.ontologies
      assert OLS.ontologies.is_a? Hash
      assert OLS.ontologies.include?('EMAP')
    end

    should 'provide easy access to the root terms of ontologies' do
      emap_roots = OLS.root_terms('EMAP')
      emap_root  = emap_roots.first

      assert emap_roots.is_a? Array
      assert emap_root.is_a? OLS::Term
      assert_equal 'EMAP:0', emap_root.id
      assert_equal 'Mouse_anatomy_by_time_xproduct', emap_root.name
      assert emap_root.parents.empty?
    end
  end
end

