# encoding: utf-8

require 'savon'

# Simple wrapper for interacting with the OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
# database (created and managed by the EBI).
#
# @author Darren Oakley (https://github.com/dazoakley)
module OLS
  # Error class for when we can't find a given ontology term.
  class TermNotFoundError < StandardError; end

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
      term = nil

      term = @cache.find_by_id(term_id) if using_cache?

      if term.nil?
        term_name = request(:get_term_by_id) { soap.body = { :termId => term_id } }
        raise TermNotFoundError if term_name.eql?(term_id)
        term = OLS::Term.new(term_id,term_name)
      end

      term
    end

    # Set whether to log HTTP requests - pass in +true+ or +false+
    attr_writer :log

    # Returns whether to log HTTP/SOAP requests. Defaults to +false+
    def log?
      @log ? true : false
    end

    # Set the logger to use
    attr_writer :logger

    # Returns the logger. Defaults to an instance of +Logger+ writing to STDOUT
    def logger
      @logger ||= ::Logger.new STDOUT
    end

    # Set the log level
    attr_writer :log_level

    # Return the log level. Defaults to :warn
    def log_level
      @log_level ||= :warn
    end

    # Set a HTTP proxy to use
    attr_writer :proxy

    # Returns a HTTP proxy url.  Will read the +http_proxy+ environment variable if present
    def proxy
      @proxy ||= ( ENV['http_proxy'] || ENV['HTTP_PROXY'] )
    end

    # Are we using a local cache? Defaults to +false+.
    # @see #setup_cache
    def using_cache?
      @cache ? true : false
    end

    # Configure the OLS gem to use a local cache. Useful if you have some serious ontology
    # activity going on, or you want to insulate yourself from server outages and the like.
    #
    # *NOTE:* We only support a file-based (on-disk) cache at the moment. By default it will
    # look in/use the current working directory, or you can pass a configuration hash as follows:
    #
    #   OLS.setup_cache({ :directory => '/path/to/cache_directory' })
    #
    # Support for other cache backends will come in future builds.
    def setup_cache(options={})
      @cache = OLS::Cache.new(options)
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

      Savon::Client.new do |wsdl, http|
        wsdl.document = "http://www.ebi.ac.uk/ontology-lookup/OntologyQuery.wsdl"
        http.proxy = OLS.proxy unless OLS.proxy.nil?
      end
    end
  end
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'ols', 'version')
require File.join(directory, 'ols', 'graph')
require File.join(directory, 'ols', 'term')
require File.join(directory, 'ols', 'cache')
