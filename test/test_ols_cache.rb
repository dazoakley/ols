require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Cache object during initialization' do
    setup do
      OLS.use_cache({ :directory => "#{File.expand_path(File.dirname(__FILE__))}/fixtures" })
    end
    
    should 'read in a fixture/cache directory of marshalled objects' do
      cache = OLS.instance_variable_get(:@cache)
      assert cache.is_a? OLS::Cache
      
    end
  end

  context 'An OLS::Cache object once initialized' do
    setup do
      OLS.stubs(:request).returns(nil)
    end

    teardown do
      OLS.unstub(:request)
    end

    should 'allow the rest of the OLS machinery access to ontology data without the need to call OLS directly' do
      
    end
  end
end
