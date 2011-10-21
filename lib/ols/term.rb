# encoding: utf-8

module OLS

  # Class representing an ontology term
  #
  # @author Darren Oakley
  class Term
    attr_reader :term_id, :term_name

    # Creates a new OLS::Term object
    #
    # @param [String] term_id The ontology term id
    # @param [String] term_name The ontology term name
    def initialize(term_id,term_name)
      @term_id = term_id
      @term_name = term_name

      @already_fetched_parents  = false
      @already_fetched_children = false
      @already_fetched_metadata = false
    end

    # Is this a root node?
    #
    # @return [Boolean] returns true/false depending on if this is a root node or not...
    def is_root?
      self.parents.empty?
    end

    # Is this a leaf node?
    #
    # @return [Boolean] returns true/false depending on if this is a leaf node or not...
    def is_leaf?
      self.children.empty?
    end

    # Is this ontology term obsolete?
    #
    # @return [Boolean] returns true/false depending on if this term is obsolete or not...
    def is_obsolete?
      @is_obsolete ||= OLS.request(:is_obsolete) { soap.body = { :termId => self.term_id } }
    end

    # def xrefs
    #   OLS.request(:get_term_xrefs) { soap.body = { :termId => self.term_id } }
    # end

    # The ontology term definition
    #
    # @return [String] The ontology term definition
    def definition
      get_term_metadata
      @definition
    end

    # Returns a hash listing the different types of synonyms known for this term,
    # keyed by the synonym type
    #
    # @return [Hash] a hash listing the different types of synonyms known for this term
    def synonyms
      get_term_metadata
      @synonyms ||= {}
    end

    # Represent an OLS::Term as a String
    #
    # @return [String] A string representation of an OLS::Term
    def to_s
      "#{@term_id} - #{@term_name}"
    end

    # Returns the direct parent terms for this ontology term
    #
    # @return [Array] An array of OLS::Term objects
    def parents
      unless @already_fetched_parents
        response = OLS.request(:get_term_parents) { soap.body = { :termId => self.term_id } }
        unless response.nil?
          if response[:item].is_a? Array
            @parents = response[:item].map { |term| OLS::Term.new(term[:key],term[:value]) }
          else
            term = response[:item]
            @parents = [ OLS::Term.new(term[:key],term[:value]) ]
          end
        end

        @already_fetched_parents = true
      end

      @parents ||= []
    end

    # Returns an array of all parent term objects for this ontology term
    # (all the way to the top of the ontology).  The array is ordered
    # with the root term first and the most direct parent(s) last.
    #
    # @return [Array] An array of OLS::Term objects
    def all_parents
      return [] if is_root?

      parentage_array = []
      prev_parents = self.parents
      while ( !prev_parents.empty? )
        parentage_array << prev_parents
        prev_parents = prev_parents.map(&:parents).flatten
      end

      parentage_array.reverse.flatten
    end

    # Returns an array of all parent term_ids for this ontology term
    # (all the way to the top of the ontology).  The array is ordered
    # with the root term first and the most direct parent(s) last. 
    # Duplicates are also filtered out.
    #
    # @return [Array] An array of ontology term_ids
    def all_parent_ids
      all_parents.map(&:term_id).uniq
    end

    # Returns an array of all parent term_names for this ontology term
    # (all the way to the top of the ontology).  The array is ordered
    # with the root term first and the most direct parent last.
    # Duplicates are also filtered out.
    #
    # @return [Array] An array of ontology term_names
    def all_parent_names
      all_parents.map(&:term_name).uniq
    end

    alias :all_parent_term_ids :all_parent_ids
    alias :all_parent_term_names :all_parent_names

    # Returns the child terms for this ontology term
    #
    # @return [Array] An array of child OLS::Term objects
    def children
      unless @already_fetched_children
        response = OLS.request(:get_term_children) { soap.body = { :termId => self.term_id, :distance => 1, :relationTypes => [1,2,3,4,5] } }
        unless response.nil?
          if response[:item].is_a? Array
            @children = response[:item].map { |term| OLS::Term.new(term[:key],term[:value]) }
          else
            term = response[:item]
            @children = OLS::Term.new(term[:key],term[:value])
          end
        end

        @already_fetched_children = true
      end

      @children ||= []
    end

    # Convenience method for accessing specific child terms.
    #
    # @param [String] term_id The term_id for the child you wish to access
    # @return [OLS::Term] An OLS::Term object
    def [](term_id)
      children_as_a_hash = {}
      self.children.each do |child|
        children_as_a_hash[child.term_id] = child
      end
      children_as_a_hash[term_id]
    end

    # Returns an array of all child term objects for this ontology term
    # (all the way down to the bottom of the ontology).  The array is NOT
    # guarenteed to come out in any specific order whatsoever.
    #
    # @return [Array] An array of OLS::Term objects
    def all_children
      return [] if is_leaf?

      children_array = []
      prev_children = self.children
      while ( !prev_children.empty? )
        children_array << prev_children
        prev_children = prev_children.map(&:children).flatten
      end

      children_array.flatten
    end

    # Returns an array of all child term_ids for this ontology term
    # (all the way down to the bottom of the ontology).  The array is NOT
    # guarenteed to come out in any specific order whatsoever.
    #
    # @return [Array] An array of ontology term_ids
    def all_child_ids
      all_children.map(&:term_id)
    end

    # Returns an array of all child term_names for this ontology term
    # (all the way down to the bottom of the ontology).  The array is NOT
    # guarenteed to come out in any specific order whatsoever.
    #
    # @return [Array] An array of ontology term_names
    def all_child_names
      all_children.map(&:term_name)
    end

    alias :all_child_term_ids :all_child_ids
    alias :all_child_term_names :all_child_names

    private

    def get_term_metadata
      unless @already_fetched_metadata
        meta = [ OLS.request(:get_term_metadata) { soap.body = { :termId => self.term_id } }[:item] ].flatten
        meta.each do |meta_item|
          case meta_item[:key]
          when 'definition'
            @definition = meta_item[:value]
          when /synonym/
            syn_match = /^(.+)_synonym/.match( meta_item[:key] )
            @synonyms ||= {}
            @synonyms[ syn_match[1].to_sym ] ||= []
            @synonyms[ syn_match[1].to_sym ] << meta_item[:value]
          end
        end

        @already_fetched_metadata = true
      end
    end

  end
end
