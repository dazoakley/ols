require 'test_helper'

class OLSTest < Test::Unit::TestCase
  include OLS

  context "The OLS module" do
    should "make a connection to the OLS SOAP service" do
      assert OLS.client
      assert OLS.client.is_a? Savon::Client
    end

    should "give access to version metadata" do
      assert OLS.version
      assert OLS.version.is_a? String
    end

    should "list the available ontologies" do
      assert OLS.ontologies
      assert OLS.ontologies.is_a? Hash
      assert OLS.ontologies.include?('EMAP')
    end
  end
end
