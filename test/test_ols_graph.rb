require 'test_helper'

class OLSGraphTest < Test::Unit::TestCase
  context 'An OLS::Graph object' do
    setup do
      VCR.insert_cassette('test_ols_term')
    end

    teardown do
      VCR.eject_cassette
    end

    context 'once created' do
      setup do
        @graph = OLS::Graph.new
      end

      should 'initialize correctly' do
        assert @graph.instance_variable_get(:@graph).is_a? Hash
        assert @graph.instance_variable_get(:@graph).empty?
      end

      should 'only allow OLS::Term objects to be addded to the graph' do
        assert_raises (TypeError) { @graph.add_to_graph('foo') }
        @graph.add_to_graph( OLS.find_by_id('EMAP:3018') )
      end

      should 'allow access to the nodes of the graph' do
        assert_nil @graph['EMAP:3018']
        @graph.add_to_graph( OLS.find_by_id('EMAP:3018') )
        assert @graph['EMAP:3018'].is_a? Hash
        assert @graph.find('EMAP:3018').is_a? OLS::Term
      end
    end
  end
end