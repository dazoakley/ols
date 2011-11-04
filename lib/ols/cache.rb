# encoding: utf-8

module OLS

  # Utility class responsible for handling caching in the OLS gem.  You should *NOT* 
  # really interact with instances of this class directly, use the methods on the OLS 
  # module and the resulting OLS::Term objects.
  #
  # @author Darren Oakley (https://github.com/dazoakley)
  class Cache
    # Creates a new OLS::Cache object and scans the cache directory for cached terms.
    def initialize(args={})
      options = { :directory => Dir.getwd }.merge(args)
      @cache_directory = options[:directory]

      prepare_cache
    end

    # Pull an OLS::Term object out of the cache.  Returns +nil+ if the term is not found.
    #
    # @param [String] term_id The ontology term_id to look up
    # @return [OLS::Term] The found OLS::Term object or +nil+
    def find_by_id(term_id)
      found_term = nil
      filename = @term_id_to_files[term_id].to_s

      unless filename.nil? || filename.empty?
        Dir.chdir(@cache_directory) do
          root_term = Marshal.load( File.open(filename) )
          found_term = root_term.send(:find_in_graph,term_id)
        end
      end

      found_term
    end

    # Returns a list of the cached ontologies.
    #
    # @return [Array] A list of the cached ontologies
    def cached_ontologies
      @cached_ontologies.keys
    end

    # Add an ontology to the cache.
    #
    # @param [String] ontology The ontology to add
    # @raise [ArgumentError] Raised if the ontology is not part of OLS
    def add_ontology_to_cache(ontology)
      raise ArgumentError, "'#{ontology}' is not a valid OLS ontology" unless OLS.ontologies.include?(ontology)

      new_filenames = []

      Dir.chdir(@cache_directory) do
        OLS.root_terms(ontology).each do |term|
          term_filename = "#{term.term_id.gsub(':','')}.marshal"
          term.focus_graph!
          File.open("#{term_filename}",'w') { |f| f << Marshal.dump(term) }
          @cached_ontologies[ontology] ||= []
          @cached_ontologies[ontology].push(term_filename) unless @cached_ontologies[ontology].include? term_filename
          new_filenames.push(term_filename)
        end
      end

      @cached_ontologies[ontology].delete_if { |file| !new_filenames.include?(file) }

      write_cached_ontologies_to_disk
      prepare_cache
    end

    alias :refresh_ontology_in_cache :add_ontology_to_cache

    # Remove an ontology from the cache.
    #
    # @param [String] ontology The ontology to remove
    # @raise [ArgumentError] Raised if the ontology is not part of OLS
    def remove_ontology_from_cache(ontology)
      raise ArgumentError, "'#{ontology}' is not part of the cache" unless OLS.ontologies.include?(ontology)

      Dir.chdir(@cache_directory) do
        @cached_ontologies[ontology].each do |file|
          File.delete(file)
        end
      end

      @cached_ontologies.delete(ontology)

      write_cached_ontologies_to_disk
      prepare_cache
    end

    private

    # writes the @cached_ontologies variable to disk
    def write_cached_ontologies_to_disk
      Dir.chdir(@cache_directory) do
        File.open('cached_ontologies.yaml','w') { |f| f << @cached_ontologies.to_yaml }
      end
    end

    # Utility function to prepare the cache.
    def prepare_cache
      @cached_ontologies = {}
      @term_id_to_files = {}

      Dir.chdir(@cache_directory) do
        @cached_ontologies = YAML.load( File.open('cached_ontologies.yaml') ) if File.exists?('cached_ontologies.yaml')

        @cached_ontologies.each do |ontology,filenames|
          filenames.each do |filename|
            root_term = Marshal.load( File.open(filename) )
            next unless root_term.is_a? OLS::Term
            @term_id_to_files[ root_term.term_id ] = filename.to_sym
            root_term.all_child_ids.each { |term_id| @term_id_to_files[term_id] = filename.to_sym }
          end
        end
      end
    end
  end
end