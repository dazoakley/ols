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
      @cache_directory.sub!(/\/$/,'')

      prepare_cache
    end

    # Pull an OLS::Term object out of the cache.  Returns +nil+ if the term is not found.
    #
    # @param [String] term_id The ontology term_id to look up
    # @return [OLS::Term] The found OLS::Term object or +nil+
    def find_by_id(term_id)
      found_term = nil
      filename = @term_id_to_files[term_id]

      unless filename.nil? || filename.empty?
        root_term = Marshal.load( @the_cache[filename] )
        found_term = root_term.send(:find_in_graph,term_id)
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

      OLS.root_terms(ontology).each do |term|
        term_filename = "#{term.term_id.gsub(':','')}.marshal"
        term.focus_graph!
        File.open("#{@cache_directory}/#{term_filename}",'w') { |f| f << Marshal.dump(term) }
        @cached_ontologies[ontology] ||= { :filenames => [], :date => Date.today }
        @cached_ontologies[ontology][:filenames].push(term_filename) unless @cached_ontologies[ontology][:filenames].include? term_filename
        new_filenames.push(term_filename)
      end
      @cached_ontologies[ontology][:filenames].delete_if { |file| !new_filenames.include?(file) }

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

      @cached_ontologies[ontology][:filenames].each do |file|
        File.delete("#{@cache_directory}/#{file}")
      end

      @cached_ontologies.delete(ontology)

      write_cached_ontologies_to_disk
      prepare_cache
    end

    private

    # writes the @cached_ontologies variable to disk
    def write_cached_ontologies_to_disk
      File.open("#{@cache_directory}/cached_ontologies.yaml",'w') { |f| f << @cached_ontologies.to_yaml }
    end

    # Utility function to prepare the cache.
    def prepare_cache
      @cached_ontologies = {}
      @term_id_to_files = {}
      @the_cache = {}

      Dir.mkdir(@cache_directory) unless Dir.exists?(@cache_directory)

      @cached_ontologies = YAML.load( File.open("#{@cache_directory}/cached_ontologies.yaml") ) if File.exists?("#{@cache_directory}/cached_ontologies.yaml")

      @cached_ontologies.each do |ontology,details|
        details[:filenames].each do |filename|
          file_contents = File.new("#{@cache_directory}/#{filename}",'rb').read
          root_term = Marshal.load( file_contents )
          next unless root_term.is_a? OLS::Term

          @the_cache[ filename.to_sym ] = file_contents
          @term_id_to_files[ root_term.term_id ] = filename.to_sym
          root_term.all_child_ids.each { |term_id| @term_id_to_files[term_id] = filename.to_sym }
        end
      end
    end
  end

  class DatabaseCache
    def initialize(args={})
      defaults = {
        :adapter  => 'mysql2',
        :database => 'ols_cache',
        :host     => '127.0.0.1',
        :port     => 3306,
        :user     => 'ols',
        :password => 'ols',
        :encoding => 'utf8'
      }

      @db_connection_details = defaults.merge(args)

      prepare_cache
    end

    def find_by_id(term_id)
      term = nil
      cache_entry = self.db[:term_cache].first( :term_key => term_id )
      term = Marshal.load( Zlib::Inflate.inflate(cache_entry[:marshalled_object]) ) unless cache_entry.nil?
      term
    end

    def add_ontology_to_cache(ontology)
      raise ArgumentError, "'#{ontology}' is not a valid OLS ontology" unless OLS.ontologies.include?(ontology)

      db = self.db
      db.transaction do

        ontology_stamp = db[:ontologies].first( :name => ontology )
        if ontology_stamp.nil?
          db[:ontologies].insert( :name => ontology, :cache_date => Date.today )
        else
          ontology_stamp.update( :cache_date => Date.today )
        end

        OLS.root_terms(ontology).each do |root_term|
          root_term.focus_graph!
          root_term.send(:get_term_metadata)

          root_term.all_children.each do |child|
            child.send(:get_term_metadata)
          end

          save_term_to_db(db,ontology,root_term)

          root_term.all_children.each do |child|
            term = child.dup
            term.focus_graph!
            save_term_to_db(db,ontology,term)
          end
        end

      end
    end

    def save_term_to_db(db,ontology,term)
      db[:term_cache].filter( :term_key => term.term_id ).delete
      db[:term_cache].insert(
        :term_key => term.term_id,
        :ontology_name => ontology,
        :marshalled_object => Zlib::Deflate.deflate( Marshal.dump(term) )
      )
    end

    def db
      @db_connection = Sequel.connect(@db_connection_details) if @db_connection.nil?
      @db_connection
    end

    private

    def prepare_cache
      db = self.db

      unless db.table_exists? :ontologies
        db.create_table :ontologies do
          String :name
          Date :cache_date, { :null => false }
          primary_key [:name]
        end
      end

      unless db.table_exists? :term_cache
        db.create_table :term_cache do
          String :term_key
          String :ontology_name, { :null => false }
          File :marshalled_object, { :null => false }
          primary_key [:term_key]
          foreign_key [:ontology_name], :ontologies, { :key => :name }
        end
      end
    end
  end
end

