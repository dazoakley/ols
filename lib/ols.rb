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

    # Fetch the version string for the current build of OLS
    #
    # @return [String] Then version string for the current OLS build
    def version
      request :get_version
    end

    # Fetch a hash of all ontologies in the OLS service, keyed by their short-name
    #
    # @return [Hash] names of ontologies: short-name (keys), full-names (values)
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

    # Fetch all the root terms for a given ontology
    #
    # @param [String/Symbol] ontology The short-name of the ontology
    # @return [Array] An array of OLS::Term objects for all root terms the requested ontology
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

    # Fetch an ontology term (OLS::Term) by its id
    #
    # @param [String/Symbol] id An ontology id to look for - i.e. 'GO:0023034'
    # @return [OLS::Term] An OLS::Term object for the requested ontology id
    # @raise OLS::TermNotFoundError Raised if the requested ontology id cannot be found
    def find_by_id(id)
      name = request(:get_term_by_id) { soap.body = { :termId => id } }
      raise TermNotFoundError if name.eql?(id)
      OLS::Term.new(id,name)
    end

    # def find_by_name(partial_name,ontology)
    #   terms = request(:get_terms_by_name) { soap.body = { :partialName => partial_name, :ontologyName => ontology, :reverseKeyOrder => false } }
    #   ap terms
    # end

    def request(method,&block)
      response = nil
      if block
        response = self.client.request(method,&block)
      else
        response = self.client.request method
      end
      response.body[:"#{method}_response"][:"#{method}_return"]
    end

    private

    # Helper function to initialize the (Savon) SOAP client
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

