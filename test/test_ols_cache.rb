require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Cache object' do
    setup do
      OLS.use_cache({ :directory => "#{File.expand_path(File.dirname(__FILE__))}/fixtures" })
    end

    should 'read in a fixture/cache directory of marshalled objects upon initialisation' do
      cache = OLS.instance_variable_get(:@cache)
      assert cache.is_a? OLS::Cache
      assert cache.instance_variable_get(:@term_id_to_files).size > 10000
    end

    should 'be able to access ontology data without connecting to the OLS service' do
      OLS.stubs(:request).returns(nil)

      assert_respond_to OLS.instance_variable_get(:@cache), :find_by_id

      emap_term = OLS.find_by_id('EMAP:3018')

      assert emap_term.is_a? OLS::Term
      assert_equal 'EMAP:3018', emap_term.term_id
      assert_equal 'EMAP:0', emap_term.root.term_id
      assert_equal 13731, emap_term.size

      # Also check that we can re-request the terms easily without object bumping into each other...
      emap_term2 = OLS.find_by_id('EMAP:3018')
      emap_term.focus_graph!

      assert_equal 19, emap_term.size
      assert_equal 13731, emap_term2.size

      OLS.unstub(:request)
    end

    should 'not get in the way when we request something that is not in the cache' do
      VCR.use_cassette('test_ols_cache') do
        assert_equal nil, OLS.instance_variable_get(:@cache).instance_variable_get(:@term_id_to_files)['GO:0008150']

        biological_process = OLS.find_by_id('GO:0008150')

        assert biological_process.is_a? OLS::Term
        assert biological_process.is_root?
        assert_equal false, biological_process.is_leaf?
        assert_equal 28, biological_process.children.size
      end
    end
  end
end
