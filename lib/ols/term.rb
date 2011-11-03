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
    def initialize(term_id,term_name,graph=nil)
      @term_id   = term_id
      @term_name = term_name

      @already_fetched_parents  = false
      @already_fetched_children = false
      @already_fetched_metadata = false

      if graph.nil?
        @graph = OLS::Graph.new
        @graph.add_to_graph(self)
      else
        @graph = graph
      end
    end

    # Object function used by .clone and .dup to create copies of OLS::Term objects.
    def initialize_copy(source)
      super
      @graph = source.instance_variable_get(:@graph).dup
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

    # Returns the size of the full ontology tree.
    #
    # @return [Integer] The size of the full ontology tree
    def size
      self.root.all_children.size + 1
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

    # Returns the direct parent terms for this ontology term
    #
    # @return [Array] An array of OLS::Term objects
    def parents(skip_fetch=false)
      unless @already_fetched_parents || skip_fetch
        # puts "--- REQUESTING PARENTS (#{self.term_id}) ---"
        response = OLS.request(:get_term_parents) { soap.body = { :termId => self.term_id } }
        unless response.nil?
          if response[:item].is_a? Array
            response[:item].each do |term|
              parent = self.find_in_graph(term[:key]) || OLS::Term.new(term[:key],term[:value],@graph)
              self.add_parent(parent)
            end
          else
            term = response[:item]
            parent = self.find_in_graph(term[:key]) || OLS::Term.new(term[:key],term[:value],@graph)
            self.add_parent(parent)
          end
        end

        @already_fetched_parents = true
      end

      @graph[term_id][:parents].map{ |parent_id| self.find_in_graph(parent_id) }
    end

    # Returns the term_ids for the direct parents of this term.
    #
    # @return [Array] The term_ids for the direct parents of this term
    def parent_ids
      parents.map(&:term_id)
    end

    # Returns the term_names for the direct parents of this term.
    #
    # @return [Array] The term_names for the direct parents of this term
    def parent_names
      parents.map(&:term_name)
    end

    alias :parent_term_ids :parent_ids
    alias :parent_term_names :parent_names

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
    def children(skip_fetch=false)
      unless @already_fetched_children || skip_fetch
        # puts "--- REQUESTING CHILDREN (#{self.term_id}) ---"
        response = OLS.request(:get_term_children) { soap.body = { :termId => self.term_id, :distance => 1, :relationTypes => [1,2,3,4,5] } }
        unless response.nil?
          if response[:item].is_a? Array
            response[:item].each do |term|
              child = self.find_in_graph(term[:key]) || OLS::Term.new(term[:key],term[:value],@graph)
              self.add_child(child)
            end
          else
            term = response[:item]
            child = self.find_in_graph(term[:key]) || OLS::Term.new(term[:key],term[:value],@graph)
            self.add_child(child)
          end
        end

        @already_fetched_children = true
      end

      @graph[term_id][:children].map{ |child_id| self.find_in_graph(child_id) }
    end

    # Returns the term_ids for the direct children of this term.
    #
    # @return [Array] The term_ids for the direct children of this term
    def children_ids
      children.map(&:term_id)
    end

    # Returns the term_names for the direct children of this term.
    #
    # @return [Array] The term_names for the direct children of this term
    def children_names
      children.map(&:term_name)
    end

    alias :children_term_ids :children_ids
    alias :children_term_names :children_names

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

    # Merge in another ontology tree that shares the same root. Duplicate nodes (coming from
    # other_tree) will NOT be overwritten in self.
    #
    # @param [OLS::Term] other_tree The other tree to merge with.
    # @raise [TypeError] This exception is raised if other_tree is not a OLS::Term.
    # @raise [ArgumentError] This exception is raised if other_tree does not have the same root as self.
    def merge!( other_tree )
      raise TypeError, 'You can only merge in another instance of OLS::Term' unless other_tree.is_a?(OLS::Term)
      raise ArgumentError, 'Unable to merge trees as they do not share the same root' unless self.root.term_id == other_tree.root.term_id

      self.focus_graph!
      other_tree.focus_graph!

      merge_trees( self.root, other_tree.root )
    end

    # Flesh out and focus the ontology graph around this term.
    #
    # This will fetch all children and parents for this term, and will also trick each 
    # parent/child object into thinking the ontology graph is fully formed so no further 
    # requests to OLS will be made (to further flesh out the tree).
    #
    # i.e. This allows us to do the following
    #
    #   e = OLS.find_by_id('EMAP:3018')
    #   e.focus_graph!
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
    # without e.focus_graph! it would print the *complete* EMAP tree (>13,000 terms).
    def focus_graph!
      self.all_parents.each do |parent|
        parent.lock
      end

      self.all_children.each do |child|
        child.lock
      end
    end

    # Returns a copy of this ontology term object with the parents removed.
    #
    # @return [OLS::Term] A copy of this ontology term object with the parents removed
    def detached_subtree_copy
      copy = self.dup
      copy.parents = []
      copy.lock_parents
      copy
    end

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

    # Save an image file showing graph structure of all children from the current term.
    # Requires graphviz to convert the .dot source file to an image file.
    #
    # @param [String] filename The filename to save the DOT and image files to - omit the file extension
    # @param [String] fmt The image format to produce - i.e. png or jpg
    def write_children_to_graphic_file(filename='graph',fmt='png')
      dotfile = filename + ".dot"
      imgfile = filename + "." + fmt

      nodes = [ self ] + self.all_children
      node_ranks = {}

      nodes.each do |node|
        node_ranks[node.level] ||= []
        node_ranks[node.level].push(node.term_id.gsub(':',''))
      end

      edges = self.all_children.map do |child|
        child.parents.map { |parent| "    #{parent.term_id} -> #{child.term_id}".gsub(':','') }
      end.flatten.uniq

      write_dot_and_image_file(dotfile,imgfile,fmt,nodes,node_ranks,edges)
    end

    # Save an image file showing graph structure of all parents for the current term.
    # Requires graphviz to convert the .dot source file to an image file.
    #
    # @param [String] filename The filename to save the DOT and image files to - omit the file extension
    # @param [String] fmt The image format to produce - i.e. png or jpg
    def write_parentage_to_graphic_file(filename='graph',fmt='png')
      dotfile = filename + ".dot"
      imgfile = filename + "." + fmt

      nodes = self.all_parents + [ self ]
      node_ranks = {}

      nodes.each do |node|
        node_ranks[node.level] ||= []
        node_ranks[node.level].push(node.term_id.gsub(':',''))
      end

      edges = self.all_parents.map do |parent|
        parent.children.map { |child| "    #{parent.term_id} -> #{child.term_id}".gsub(':','') }
      end.flatten.uniq

      write_dot_and_image_file(dotfile,imgfile,fmt,nodes,node_ranks,edges)
    end

    # Image drawing utility function.  This is responsible for writing the DOT 
    # source file and converting it into the desired image format.
    #
    # @param [String] dotfile The DOT filename
    # @param [String] imgfile The image filename
    # @param [String] fmt The image format to produce - i.e. png or jpg
    # @param [Array] nodes An array of OLS::Term objects to enter as nodes in the graph
    # @param [Hash] node_ranks A hash of node names grouped by their level
    # @param [Array] edges An array of edge statements already pre-formatted for DOT format
    def write_dot_and_image_file(dotfile,imgfile,fmt,nodes,node_ranks,edges)
      File.open(dotfile,'w') do |f|
        f << "digraph OntologyTree_#{self.term_id.gsub(':','')} {\n"
        f << nodes.map { |vert| "    #{vert.term_id.gsub(':','')} [label=\"#{vert.term_id}\"]" }.join("\n")
        f << "\n"
        f << edges.join("\n")
        f << "\n"
        node_ranks.each_value { |nodes| f << "    { rank=same; #{nodes.join(' ')} }\n" }
        f << "}\n"
      end
      system( "dot -T#{fmt} #{dotfile} -o #{imgfile}" )
    end
    private(:write_dot_and_image_file)

    protected

    # Stop this object from trying to fetch up more parent terms from OLS
    def lock_parents
      @already_fetched_parents = true
    end

    # Stop this object from trying to fetch up more child terms from OLS
    def lock_children
      @already_fetched_children = true
    end

    # Stop this object from looking up anymore parent/child terms from OLS
    #
    # @see #lock_parents
    # @see #lock_children
    def lock
      lock_parents
      lock_children
    end

    # Graph access function. Allows you to reset the parentage for a given term.
    #
    # @param [Array] parents An array of OLS::Term objects to set as the parents
    # @raise [ArgumentError] Raised if an Array is not passed
    # @raise [TypeError] Raised if the parents array does not contain OLS::Term objects
    def parents=(parents)
      raise ArgumentError, "You must pass an array" unless parents.is_a?(Array)
      parents.each { |p| raise TypeError, "You must pass an array of OLS::Term objects" unless p.is_a?(OLS::Term) }
      @graph[self.term_id][:parents] = parents.map(&:term_id)
    end

    # Graph access function. Adds a parent relationship (for this term) to the graph.
    #
    # @param [OLS::Term] parent The OLS::Term to add as a parent
    # @raise [TypeError] Raised if parent is not an OLS::Term object
    def add_parent(parent)
      raise TypeError, "You must pass an OLS::Term object" unless parent.is_a?(OLS::Term)
      @graph.add_relationship(parent,self)
    end

    # Graph access function. Adds a child relationship (for this term) to the graph.
    #
    # @param [OLS::Term] child The OLS::Term to add as a child
    # @raise [TypeError] Raised if child is not an OLS::Term object
    def add_child(child)
      raise TypeError, "You must pass an OLS::Term object" unless child.is_a?(OLS::Term)
      @graph.add_relationship(self,child)
    end

    # Graph access function. Finds an OLS::Term object in the graph.
    #
    # @param [String] term_id The term id to look up
    def find_in_graph(term_id)
      @graph.find(term_id)
    end

    private

    # Utility function to hit the :get_term_metadata soap endpoint and extract the
    # given metadata for an ontology term.
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

    # Utility function to recursivley merge two ontology (sub)trees.
    #
    # @param [OLS::Term] tree1 The target ontology tree to merge into.
    # @param [OLS::Term] tree2 The donor ontology tree (that will be merged into target).
    # @return [OLS::Term] The merged ontology tree.
    def merge_trees( tree1, tree2 )
      names1 = tree1.children.map(&:term_id)
      names2 = tree2.children.map(&:term_id)

      names_to_merge = names2 - names1
      names_to_merge.each do |name|
        new_child         = tree2[name].detached_subtree_copy
        new_child.parents = [ tree1 ]
        tree1.add_child(new_child)
      end

      tree1.children.each do |child|
        merge_trees( child, tree2[child.term_id] ) unless tree2[child.term_id].nil?
        child.lock
      end

      return tree1
    end

  end
end
