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

      @cache_directory  = options[:directory]
      @term_id_to_files = {}

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

    private

    # Utility function to prepare the cache.
    def prepare_cache
      Dir.chdir(@cache_directory) do
        Dir.glob("*.marshal") do |filename|
          root_term = Marshal.load( File.open(filename) )
          next unless root_term.is_a? OLS::Term
          @term_id_to_files[ root_term.term_id ] = filename.to_sym
          root_term.all_child_ids.each { |term_id| @term_id_to_files[term_id] = filename.to_sym }
        end
      end
    end
  end
end