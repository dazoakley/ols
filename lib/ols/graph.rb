# encoding: utf-8

module OLS

  # Utility class for representing an ontology graph. You should *NOT* really interact with
  # instances of this class directly, use OLS.find_by_id etc.
  #
  # @author Darren Oakley (https://github.com/dazoakley)
  class Graph
    def initialize
      @graph = {}
    end

    # Fetch the object/parents/children hash for a given term.
    #
    # @param [String] key The ontology term id
    # @return [Hash] The object/parents/children hash for the given term
    def [](key)
      @graph[key]
    end

    # Fetch the OLS::Term object for a node in the graph.
    #
    # @param [String] key The ontology term id
    # @return [OLS::Term] The OLS::Term object for this term id
    def find(key)
      @graph[key][:object] if @graph.has_key? key
    end

    # Add an OLS::Term object into the graph
    #
    # @param [OLS::Term] term The OLS::Term object to add
    # @raise [TypeError] Raised if +term+ is not an OLS::Term object
    def add_to_graph(term)
      raise TypeError, "You must pass an OLS::Term object" unless term.is_a? OLS::Term
      unless @graph.has_key?(term.term_id)
        @graph[term.term_id] = { :object => term, :parents => [], :children => [] }
      end
    end

    # Add an edge/relationship to the ontology graph
    #
    # @param [OLS::Term] parent The parent OLS::Term
    # @param [OLS::Term] child The child OLS::Term
    # @raise [TypeError] Raised if +parent+ or +child+ are not an OLS::Term objects
    def add_relationship(parent,child)
      raise TypeError, "You must pass an OLS::Term object" unless parent.is_a? OLS::Term
      raise TypeError, "You must pass an OLS::Term object" unless child.is_a? OLS::Term
      
      add_to_graph(parent) if self.find(parent.term_id).nil?
      add_to_graph(child) if self.find(child.term_id).nil?
      
      @graph[parent.term_id][:children].push(child.term_id) unless @graph[parent.term_id][:children].include?(child.term_id)
      @graph[child.term_id][:parents].push(parent.term_id) unless @graph[child.term_id][:parents].include?(parent.term_id)
    end
  end

end