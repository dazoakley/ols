require 'test_helper'

class OLSTest < Test::Unit::TestCase
  context 'The OLS module' do
    setup do
      VCR.insert_cassette('test_ols')
    end

    teardown do
      VCR.eject_cassette
    end

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
      assert_equal 3, OLS.root_terms('GO').size
    end

    should 'find terms by id' do
      emap_0 = OLS.find_by_id('EMAP:0')
      assert emap_0.is_a? OLS::Term
      assert_equal 'Mouse_anatomy_by_time_xproduct', emap_0.name
      assert_raise(OLS::TermNotFoundError) { OLS.find_by_id('MP:WIBBLE') }
    end

    should 'be able to find terms from synonyms' do
      term = OLS.find_by_id('GO:0007242')
      assert term.is_a? OLS::Term
      assert_equal 'GO:0023034', term.id
      assert_equal 'intracellular signaling pathway', term.name
    end

    # should 'be able to find terms by name' do
    #   terms = OLS.find_by_name('mitochondrion','GO')
    #   assert terms.first.is_a? OLS::Term
    #   assert terms.size > 2
    #   assert terms.delete_if { |elm| elm.name =~ /mitochondrion/ }.size == 0
    # end
  end
end

