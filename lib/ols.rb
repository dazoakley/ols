# encoding: utf-8

require 'savon'
require 'ap'

# Simple wrapper for interacting with the OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
# database (created and managed by the EBI).
#
# @author Darren Oakley
module OLS
  # Error class for when we can't find a given ontology term.
  class OntologyTermNotFoundError < StandardError; end

  class << self
    def client
      @client = setup_soap_client if @client.nil?
      @client
    end

    def version
      request :get_version
    end

    def ontologies
      @ontologies ||= {}
      if @ontologies.empty?
        response = request :get_ontology_names
        response[:item].each do |ont|
          @ontologies[ont[:key]] = ont[:value]
        end
      end
      @ontologies
    end

    private

    def setup_soap_client
      Savon::Client.new do
        wsdl.document = "http://www.ebi.ac.uk/ontology-lookup/OntologyQuery.wsdl"
      end
    end

    def request(method)
      response = self.client.request method
      response.body[:"#{method}_response"][:"#{method}_return"]
    end
  end

end
