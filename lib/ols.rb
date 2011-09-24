# encoding: utf-8

require 'savon'
require 'ap'

# Simple wrapper for interacting with the OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
# database (created and managed by the EBI).
#
# @author Darren Oakley
module OLS
  # Error class for when we can't find a given ontology term.
  class TermNotFoundError < StandardError; end

  class << self
    def client
      @client = setup_soap_client if @client.nil?
      @client
    end

    def request(method,&block)
      response = nil
      if block
        response = self.client.request(method,&block)
      else
        response = self.client.request method
      end
      response.body[:"#{method}_response"][:"#{method}_return"]
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

    def root_terms(ontology)
      root_terms = []
      response = request(:get_root_terms) { soap.body = { :ontologyName => ontology } }

      if response[:item].is_a? Array
        response[:item].each do |term|
          root_terms.push( OLS::Term.new(term[:key],term[:value]) )
        end
      else
        term = response[:item]
        root_terms.push( OLS::Term.new(term[:key],term[:value]) )
      end

      root_terms
    end

    def find_by_id(id)
      name = request(:get_term_by_id) { soap.body = { :termId => id } }
      raise TermNotFoundError if name.eql?(id)
      OLS::Term.new(id,name)
    end

    private

    def setup_soap_client
      Savon.configure do |config|
        config.log = false            # disable logging
        config.log_level = :info      # changing the log level
      end

      Savon::Client.new do
        wsdl.document = "http://www.ebi.ac.uk/ontology-lookup/OntologyQuery.wsdl"
      end
    end
  end
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'ols', 'version')
require File.join(directory, 'ols', 'term')

