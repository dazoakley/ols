# encoding: utf-8

require 'savon'

# Simple wrapper for interacting with the OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
# database (created and managed by the EBI).
#
# @author Darren Oakley
module OLS
  # Error class for when we can't find a given ontology term.
  class TermNotFoundError < StandardError; end

  DEFAULT_LOG_LEVEL = :warn

  class << self
    # Returns the raw (Savon) SOAP client for the OLS webservice
    #
    # @return [Object] The raw (Savon) SOAP client for the OLS webservice
    def client
      @client = setup_soap_client if @client.nil?
      @client
    end

    # Generic request method to allow simple access to all the
    # OLS webservice end-points (provided by Savon)
    #
    # @param [String/Symbol] method The SOAP method to call
    # @param [Block] &block An optional code-block to pass to the SOAP call
    # @return [Hash] The OLS method call return
    def request(method,&block)
      response = nil
      if block
        response = self.client.request(method,&block)
      else
        response = self.client.request method
      end
      response.body[:"#{method}_response"][:"#{method}_return"]
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
    # @param [String/Symbol] term_id An ontology id to look for - i.e. 'GO:0023034'
    # @return [OLS::Term] An OLS::Term object for the requested ontology id
    # @raise OLS::TermNotFoundError Raised if the requested ontology id cannot be found
    def find_by_id(term_id)
      term_name = request(:get_term_by_id) { soap.body = { :termId => term_id } }
      raise TermNotFoundError if term_name.eql?(term_id)
      OLS::Term.new(term_id,term_name)
    end

    # Sets whether to log HTTP requests.
    attr_writer :log

    # Returns whether to log HTTP/SOAP requests. Defaults to +false+.
    def log?
      @log ? true : false
    end

    # Sets the logger to use.
    attr_writer :logger

    # Returns the logger. Defaults to an instance of +Logger+ writing to STDOUT.
    def logger
      @logger ||= ::Logger.new STDOUT
    end

    # Sets the log level.
    attr_writer :log_level

    # Returns the log level. Defaults to :warn.
    def log_level
      @log_level ||= DEFAULT_LOG_LEVEL
    end

    private

    # Helper function to initialize the (Savon) SOAP client
    def setup_soap_client
      Savon.configure do |config|
        config.log = false unless OLS.log?
        config.log_level = OLS.log_level
        config.logger = OLS.logger
      end

      HTTPI.log = false unless OLS.log?
      HTTPI.log_level = OLS.log_level
      HTTPI.logger = OLS.logger

      Savon::Client.new do
        wsdl.document = "http://www.ebi.ac.uk/ontology-lookup/OntologyQuery.wsdl"
      end
    end
  end
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'ols', 'version')
require File.join(directory, 'ols', 'term')

