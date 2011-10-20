# encoding: utf-8

module OLS

  # Class representing an ontology term
  #
  # @author Darren Oakley
  class Term
    attr_reader :id, :name

    # Creates a new OLS::Term object
    #
    # @param [String] id The ontology term id
    # @param [String] name The ontology term name
    def initialize(id,name)
      @id = id
      @name = name

      @already_fetched_parents  = false
      @already_fetched_children = false
    end

    # The ontology term 'id'
    #
    # @return [String] The ontology term id
    def term
      @id
    end

    # The ontology term 'name'
    #
    # @return [String] The ontology term name
    def term_name
      @name
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
      "#{@id} - #{@name}"
    end

    # Returns the direct parent terms for this ontology term
    #
    # @return [Array] An array of OLS::Term objects
    def parents
      unless @already_fetched_parents
        response = OLS.request(:get_term_parents) { soap.body = { :termId => self.id } }
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

    # Returns an array of all parent term ids for this ontology term
    # (all the way to the top of the ontology).  The array is ordered
    # with the root term first and the most direct parent last.
    #
    # @return [Array] An array of ontology term ids
    def all_parent_ids
      all_parents.map(&:id)
    end

    # Returns an array of all parent term names for this ontology term
    # (all the way to the top of the ontology).  The array is ordered
    # with the root term first and the most direct parent last.
    #
    # @return [Array] An array of ontology term names
    def all_parent_names
      all_parents.map(&:name)
    end

    # Returns the child terms for this ontology term
    #
    # @return [Array] An array of child OLS::Term objects
    def children
      unless @already_fetched_children
        @children = []
        response = OLS.request(:get_term_children) { soap.body = { :termId => self.id, :distance => 1, :relationTypes => [1,2,3,4,5] } }
        unless response.nil?
          if response[:item].is_a? Array
            response[:item].each { |term| @children.push( OLS::Term.new(term[:key],term[:value]) ) }
          else
            term = response[:item]
            @children.push( OLS::Term.new(term[:key],term[:value]) )
          end
        end

        @already_fetched_children = true
      end

      @children
    end
  end
end
