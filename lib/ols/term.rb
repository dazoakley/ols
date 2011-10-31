# encoding: utf-8

module OLS

  # Class representing an ontology term
  #
  # @author Darren Oakley (https://github.com/dazoakley)
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
    # @return [Boolean] +true+/+false+ depending on if this is a root node or not...
    def is_root?
      self.parents.empty?
    end

    # Is this a leaf node?
    #
    # @return [Boolean] +true+/+false+ depending on if this is a leaf node or not...
    def is_leaf?
      self.children.empty?
    end

    # Is this ontology term obsolete?
    #
    # @return [Boolean] +true+/+false+ depending on if this term is obsolete or not...
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
            @parents = response[:item].map do |term|
              parent = OLS::Term.new(term[:key],term[:value])
              parent.children = [ self ]
              parent
            end
          else
            term = response[:item]
            parent = OLS::Term.new(term[:key],term[:value])
            parent.children = [ self ]
            @parents = [ parent ]
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

    # Returns the child terms for this ontology term.
    #
    # @return [Array] An array of child OLS::Term objects
    def children
      unless @already_fetched_children
        response = OLS.request(:get_term_children) { soap.body = { :termId => self.term_id, :distance => 1, :relationTypes => [1,2,3,4,5] } }
        unless response.nil?
          if response[:item].is_a? Array
            @children = response[:item].map do |term|
              child = OLS::Term.new(term[:key],term[:value])
              child.parents = [ self ]
              child
            end
          else
            term = response[:item]
            child = OLS::Term.new(term[:key],term[:value])
            child.parents = [ self ]
            @children = [ child ]
          end
        end

        @already_fetched_children = true
      end

      @children ||= []
    end

    # Returns +true+ if the ontology term has any children.
    #
    # @return [Boolean] true/false depending on if this term has children or not...
    def has_children?
      !self.children.empty?
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

    # Pretty prints the (sub)tree rooted at this ontology term.
    #
    # @param [Number] level The indentation level (4 spaces) to start with.
    def print_tree(level=1)
      if is_root?
        print "*"
      else
        print(' ' * (level - 1) * 4)
        print "|---"
        print( self.has_children? ? "+" : ">" )
      end

      puts " #{self.term_id}"

      self.children.each { |child| child.print_tree(level + 1)}
    end

    # Returns depth of this term in its ontology tree.  Depth of a node is defined as:
    #
    # Depth:: Length of the terms path to its root.  Depth of a root term is zero.
    #
    # @return [Number] Depth of this node.
    def level
      return 0 if self.is_root?
      1 + parents.first.level
    end

    # Returns the root term for this ontology.
    #
    # @return [OLS::Term] The root term for this ontology
    def root
      root = self
      root = root.parents.first while !root.is_root?
      root
    end

    # Merge two trees that share the same root node. Returns a new tree conating the 
    # contents of the merge between other_tree and self. Duplicate nodes (coming from 
    # other_tree) will NOT be overwritten in self.
    #
    # @param [OLS::Term] other_tree The other tree to merge with.
    # @return [OLS::Term] the resulting tree following the merge.
    #
    # @raise [TypeError] This exception is raised if other_tree is not a OLS::Term.
    # @raise [ArgumentError] This exception is raised if other_tree does not have the same root node as self.
    def merge( other_tree )
      check_merge_prerequisites( other_tree )

      target_tree = self.clone
      target_tree.focus_tree_around_me!

      donor_tree = other_tree.clone
      donor_tree.focus_tree_around_me!

      new_tree = merge_trees( target_tree.root, donor_tree.root )
    end

    # Flesh out and focus the ontology tree around this term.
    #
    # This will fetch all children and parents for this term, and will also trick each 
    # parent/child object into thinking the ontology tree is fully formed so no further 
    # requests to OLS will be made (to further flesh out the tree).
    #
    # i.e. This allows us to do the following
    #
    #   e = OLS.find_by_id('EMAP:3018')
    #   e.focus_tree_around_me!
    #   e.root.print_tree
    #
    # gives:
    #   * EMAP:0
    #       |---+ EMAP:2636
    #           |---+ EMAP:2822
    #               |---+ EMAP:2987
    #                   |---+ EMAP:3018
    #                       |---+ EMAP:3022
    #                           |---+ EMAP:3023
    #                               |---+ EMAP:3024
    #                                   |---> EMAP:3025
    #                                   |---> EMAP:3026
    #                               |---+ EMAP:3027
    #                                   |---> EMAP:3029
    #                                   |---> EMAP:3028
    #                               |---+ EMAP:3030
    #                                   |---> EMAP:3031
    #                                   |---> EMAP:3032
    #                       |---> EMAP:3019
    #                       |---+ EMAP:3020
    #                           |---> EMAP:3021
    #
    # without e.focus_tree_around_me! it would print the *complete* EMAP tree (>13,000 terms).
    def focus_tree_around_me!
      # TODO: write tests for me!!!!
      self.all_parents.each do |parent|
        parent.instance_variable_set :@already_fetched_parents, true
        parent.instance_variable_set :@already_fetched_children, true
      end

      self.all_children.each do |child|
        child.instance_variable_set :@already_fetched_parents, true
        child.instance_variable_set :@already_fetched_children, true
      end
    end

    protected

    attr_writer :children, :parents

    private

    # TODO: document me...
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

    # Utility function to check that the conditions for an ontology tree merge are met.
    #
    # @see #merge
    def check_merge_prerequisites( other_tree )
      unless other_tree.is_a?(OLS::Term)
        raise TypeError, 'You can only merge in another instance of OLS::Term'
      end

      unless self.root.term_id == other_tree.root.term_id
        raise ArgumentError, 'Unable to merge trees as they do not share the same root'
      end
    end

    # Utility function to recursivley merge two ontology (sub)trees.
    #
    # @param [OLS::Term] tree1 The target ontology tree to merge into.
    # @param [OLS::Term] tree2 The donor ontology tree (that will be merged into target).
    # @return [OLS::Term] The merged ontology tree.
    def merge_trees( tree1, tree2 )
      names1 = tree1.has_children? ? tree1.children.map { |child| child.term_id } : []
      names2 = tree2.has_children? ? tree2.children.map { |child| child.term_id } : []

      names_to_merge = names2 - names1
      names_to_merge.each do |name|
        # tree1 << tree2[name].detached_subtree_copy
      end

      tree1.children.each do |child|
        merge_trees( child, tree2[child.term_id] ) unless tree2[child.term_id].nil?
      end

      return tree1
    end

  end
end
