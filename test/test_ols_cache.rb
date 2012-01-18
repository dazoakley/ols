require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Cache object' do
    setup do
      @cache_directory = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"
      OLS.setup_cache({ :directory => @cache_directory })

      if OLS.cached_ontologies.include?('TRANS')
        Dir.chdir(@cache_directory) do
          Dir.glob('TRANS*').each do |file|
            File.delete(file)
          end
          File.open('cached_ontologies.yaml','w') do |file|
            file << { 'EMAP' => ['EMAP0.marshal'], 'MP' => ['MP0000001.marshal'] }.to_yaml
          end
        end
        OLS.setup_cache({ :directory => @cache_directory })
      end
    end

    teardown do
      OLS.instance_variable_set(:@cache,nil)
    end

    should 'read in a fixture/cache directory of marshalled objects upon initialisation' do
      cache = OLS.instance_variable_get(:@cache)
      assert cache.is_a? OLS::Cache
      assert OLS.using_cache?
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

      # Test the collection of metadata into the cache
      mp_term = OLS.find_by_id('MP:0002115')
      assert_equal 'any structural anomaly of the limb or autopod bones', mp_term.definition

      OLS.unstub(:request)
    end

    should 'be able to access root terms (if they are in the cache) without connecting to the OLS service' do
      OLS.stubs(:request).returns({ :item => [] })

      assert_respond_to OLS.instance_variable_get(:@cache), :root_terms

      emap_roots = OLS.root_terms('EMAP')
      emap_root = emap_roots.first

      assert emap_roots.is_a? Array
      assert emap_root.is_a? OLS::Term
      assert emap_root.is_root?
      assert_equal 'EMAP:0', emap_root.term_id
      assert_equal 13731, emap_root.size

      OLS.unstub(:request)
    end

    should 'not get in the way when we request something that is not in the cache' do
      VCR.use_cassette('test_ols') do
        assert_equal nil, OLS.instance_variable_get(:@cache).instance_variable_get(:@term_id_to_files)['GO:0008150']

        biological_process = OLS.find_by_id('GO:0008150')

        assert biological_process.is_a? OLS::Term
        assert biological_process.is_root?
        assert_equal false, biological_process.is_leaf?
        assert_equal 28, biological_process.children.size
      end
    end

    should 'not get in the way when we request root_terms that are not in the cache' do
      VCR.use_cassette('test_ols') do
        assert !OLS.cached_ontologies.include?('GO')

        go_roots = OLS.root_terms('GO')

        assert go_roots.is_a? Array
        assert_equal 3, go_roots.size
      end
    end

    should 'setup/manage cached objects for the user' do
      Dir.chdir(@cache_directory) do
        files = Dir.glob('*')
        assert files.include?('cached_ontologies.yaml')
        assert_equal false, files.include?('TRANS0000000.marshal')
      end

      VCR.use_cassette('test_ols') do
        # list cached ontologies
        assert OLS.cached_ontologies.is_a? Array
        assert OLS.cached_ontologies.include? 'EMAP'
        assert OLS.cached_ontologies.include? 'MP'

        # add a new ontology to the cache
        assert OLS.ontologies.keys.include? 'TRANS'
        OLS.add_ontology_to_cache('TRANS')
        assert OLS.cached_ontologies.include? 'TRANS'

        Dir.chdir(@cache_directory) do
          files = Dir.glob('*')
          assert files.include?('TRANS0000000.marshal')
        end
      end

      trans = OLS.find_by_id('TRANS:0000000')
      assert_equal 25, trans.size

      VCR.use_cassette('test_ols') do
        # remove an ontology from the cache
        OLS.remove_ontology_from_cache('TRANS')
        assert_equal false, OLS.cached_ontologies.include?('TRANS')
        Dir.chdir(@cache_directory) do
          files = Dir.glob('*')
          assert_equal false, files.include?('TRANS0000000.marshal')
        end
      end
    end
  end
end
