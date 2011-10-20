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
    end

    # Is this a root node?
    #
    # @return [Boolean] returns true/false depending if this is a root node or not...
    def is_root?
      self.parents.empty?
    end

    # Is this a leaf node?
    #
    # @return [Boolean] returns true/false depending if this is a leaf node or not...
    def is_leaf?
      self.children.empty?
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
    # with the root term first and the most direct parent last.
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
    # with the root term first and the most direct parent last.
    #
    # @return [Array] An array of ontology term_ids
    def all_parent_ids
      all_parents.map(&:term_id)
    end

    # Returns an array of all parent term_names for this ontology term
    # (all the way to the top of the ontology).  The array is ordered
    # with the root term first and the most direct parent last.
    #
    # @return [Array] An array of ontology term_names
    def all_parent_names
      all_parents.map(&:term_name)
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

  end
end
