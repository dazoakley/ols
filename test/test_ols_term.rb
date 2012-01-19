require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Term object' do
    setup do
      VCR.insert_cassette('test_ols')
    end

    teardown do
      VCR.eject_cassette
    end

    context 'once created' do
      setup do
        @emap_term = OLS.find_by_id('EMAP:3018')
        @mp_term   = OLS.find_by_id('MP:0002115')
      end

      should 'have an id/term and a name' do
        assert_equal 'EMAP:3018', @emap_term.term_id
        assert_equal 'TS18,nose', @emap_term.term_name
        assert_equal 'MP:0002115', @mp_term.term_id
        assert_equal 'abnormal limb bone morphology', @mp_term.term_name
      end

      should 'be able to represent itself as a string' do
        assert_equal 'EMAP:3018 - TS18,nose', @emap_term.to_s
      end

      should 'be able to say if it is an obsolete term' do
        assert_equal false, @emap_term.is_obsolete?
        assert_equal false, OLS.find_by_id('GO:0007242').is_obsolete?
        assert OLS.find_by_id('GO:0008945').is_obsolete?
      end

      should 'be able to give its definition' do
        assert_nil @emap_term.definition
        assert_equal 'any structural anomaly of the limb or autopod bones', @mp_term.definition

        go_term = OLS.find_by_id('GO:0007242')
        assert_equal 'intracellular signal transduction', go_term.term_name
        assert_equal(
          'The process in which a signal is passed on to downstream components within '+\
          'the cell, which become activated themselves to further propagate the signal '+\
          'and finally trigger a change in the function or state of the cell.',
          go_term.definition
        )
      end

      should 'be able to give a terms synonyms' do
        go_term = OLS.find_by_id('GO:0007242')

        assert_equal 'intracellular signal transduction', go_term.term_name

        assert go_term.synonyms.keys.include? :exact
        assert go_term.synonyms[:exact].include? 'intracellular signaling chain'

        assert go_term.synonyms.keys.include? :related
        assert go_term.synonyms[:related].include? 'intracellular signaling pathway'

        assert go_term.synonyms.keys.include? :narrow
        assert go_term.synonyms[:narrow].include? 'signal transmission via intracellular cascade'

        assert go_term.synonyms.keys.include? :alt_id
        assert go_term.synonyms[:alt_id].include? 'GO:0023013'

        assert_equal Hash, @emap_term.synonyms.class
        assert @emap_term.synonyms.empty?
      end

      should 'be able to report its parents' do
        assert_equal 1, @emap_term.parents.size
        assert_equal 'EMAP:2987', @emap_term.parents.first.term_id

        assert_equal 2, @mp_term.parents.size

        mp_term_parent_term_ids = @mp_term.parent_ids
        assert mp_term_parent_term_ids.include?('MP:0002109')
        assert mp_term_parent_term_ids.include?('MP:0009250')

        mp_term_parent_term_names = @mp_term.parent_names
        assert mp_term_parent_term_names.include? OLS.find_by_id('MP:0002109').term_name
        assert mp_term_parent_term_names.include? OLS.find_by_id('MP:0009250').term_name
      end

      should 'be able to generate a flat list of ALL parents (up the ontology)' do
        assert @emap_term.all_parents.is_a? Array
        assert @emap_term.all_parents.first.is_a? OLS::Term
        assert_equal 4, @emap_term.all_parents.size
        assert_equal 'EMAP:0', @emap_term.all_parents.first.term_id

        assert @mp_term.all_parents.is_a? Array
        assert @mp_term.all_parents.first.is_a? OLS::Term
        assert_equal 6, @mp_term.all_parents.size
        assert_equal 'MP:0000001', @mp_term.all_parents.first.term_id
        assert @mp_term.all_parents.last.term_id =~ /MP:0002109|MP:0009250/
      end

      should 'be able to generate a flat list of ALL parent terms/names' do
        assert @emap_term.all_parent_ids.is_a? Array
        assert_equal 4, @emap_term.all_parent_ids.size
        assert_equal 'EMAP:0', @emap_term.all_parent_ids.first

        assert @emap_term.all_parent_names.is_a? Array
        assert_equal 4, @emap_term.all_parent_names.size
        assert_equal 'Mouse_anatomy_by_time_xproduct', @emap_term.all_parent_names.first

        assert @mp_term.all_parent_ids.is_a? Array
        assert_equal 6, @mp_term.all_parent_ids.size
        assert_equal 'MP:0000001', @mp_term.all_parent_ids.first

        assert @mp_term.all_parent_names.is_a? Array
        assert_equal 6, @mp_term.all_parent_names.size
        assert_equal 'mammalian phenotype', @mp_term.all_parent_names.first
      end

      should 'be able to report its children' do
        assert @emap_term.has_children?
        assert_equal 3, @emap_term.children.size
        assert @emap_term['EMAP:3022'].is_a? OLS::Term
        assert @emap_term.children_ids.include? 'EMAP:3022'
        assert @emap_term.children_names.include? OLS.find_by_id('EMAP:3022').term_name
      end

      should 'be able to generate a flat list of ALL children (down the ontology)' do
        assert @emap_term.all_children.is_a? Array
        assert @emap_term.all_children.first.is_a? OLS::Term
        assert_equal 14, @emap_term.all_children.size
        emap3032_included = false
        @emap_term.all_children.each do |child|
          emap3032_included = true if child.term_id.eql?('EMAP:3032')
        end
      end

      should 'be able to generate a flat list of ALL child terms/names' do
        assert @emap_term.all_child_ids.is_a? Array
        assert_equal 14, @emap_term.all_child_ids.size
        assert @emap_term.all_child_ids.include?('EMAP:3032')

        assert @emap_term.all_child_names.is_a? Array
        assert_equal 14, @emap_term.all_child_names.size
        assert @emap_term.all_child_names.include?('TS18,mesenchyme,medial-nasal process')
      end

      should 'allow easy access to child terms using the [] helper' do
        emap = OLS.find_by_id('EMAP:0')
        assert emap['EMAP:2636'].is_a? OLS::Term
        assert emap['EMAP:2636']['EMAP:2822'].is_a? OLS::Term
        assert_equal 'EMAP:2636', emap['EMAP:2636'].term_id
        assert_equal 'TS18,embryo', emap['EMAP:2636'].term_name
      end

      should "be able to say if it's a root/leaf node" do
        assert_equal false, @emap_term.is_root?
        assert_equal false, @emap_term.is_leaf?

        emap3032 = OLS.find_by_id('EMAP:3032')
        assert_equal false, emap3032.is_root?
        assert emap3032.is_leaf?

        emap0 = OLS.find_by_id('EMAP:0')
        assert emap0.is_root?
        assert_equal false, emap0.is_leaf?
      end

      should 'be able to give its depth level' do
        assert_equal 0, OLS.find_by_id('EMAP:0').depth
        assert_equal 4, @emap_term.depth

        # This next term has 2 routes through the graph - 3 and 5 levels deep
        # the .depth function should return the shortest depth.
        assert_equal 3, @mp_term.depth
      end

      should 'be able to "focus" a empty ontology graph around a given term' do
        # First, test the following EMAP graph...
        #
        # * EMAP:0
        #     |---+ EMAP:2636
        #         |---+ EMAP:2822
        #             |---+ EMAP:2987
        #                 |---+ EMAP:3018
        #                     |---+ EMAP:3022
        #                         |---+ EMAP:3023
        #                             |---+ EMAP:3024
        #                                 |---> EMAP:3025
        #                                 |---> EMAP:3026
        #                             |---+ EMAP:3027
        #                                 |---> EMAP:3029
        #                                 |---> EMAP:3028
        #                             |---+ EMAP:3030
        #                                 |---> EMAP:3031
        #                                 |---> EMAP:3032
        #                     |---> EMAP:3019
        #                     |---+ EMAP:3020
        #                         |---> EMAP:3021

        @emap_term.focus_graph!

        assert_equal 'EMAP:0', @emap_term.root.term_id
        assert_equal 1, @emap_term.root.children.size
        assert_equal 3, @emap_term.children.size
        assert_equal 4, @emap_term.level

        assert @emap_term.instance_variable_get :@already_fetched_parents
        assert @emap_term.instance_variable_get :@already_fetched_children

        assert @emap_term.root.instance_variable_get :@already_fetched_parents
        assert @emap_term.root.instance_variable_get :@already_fetched_children

        # Now test the following MP graph...
        #
        # * MP:0000001
        #     |---+ MP:0005371
        #         |---+ MP:0000545
        #                 |---+ MP:0002115
        #                     ...
        #     |---+ MP:0005390
        #         |---+ MP:0005508
        #             |---+ MP:0009250
        #                 |---+ MP:0002115
        #                     ...
        #

        @mp_term.focus_graph!

        assert_equal 'MP:0000001', @mp_term.root.term_id
        assert_equal 2, @mp_term.root.children.size
        assert @mp_term.root.children.map(&:term_id).include? 'MP:0005371'
        assert @mp_term.root.children.map(&:term_id).include? 'MP:0005390'
      end

      should 'be able to "focus" a large pre-populated graph around a single term' do
        # bulk out the target graph
        @emap_term.focus_graph!
        assert_equal 19, @emap_term.size

        # make it a touch larger
        @emap_term.merge!( OLS.find_by_id('EMAP:3003') )
        assert_equal 34, @emap_term.size

        # cut it back to the origninal focused graph
        @emap_term.focus_graph!
        raw_graph = @emap_term.instance_variable_get(:@graph).raw_graph

        assert_equal 19, @emap_term.size
        assert_equal 19, raw_graph.keys.size
        assert_equal false, raw_graph.keys.include?('EMAP:3003')
      end

      should 'be able to "focus" a large pre-populated graph around a single term without clobbering the existing graph' do
        # bulk out the target graph
        @emap_term.focus_graph!
        assert_equal 19, @emap_term.size

        # make it a touch larger
        @emap_term.merge!( OLS.find_by_id('EMAP:3003') )
        assert_equal 34, @emap_term.size

        # cut it back to the origninal focused graph
        new_graph = @emap_term.focus_graph

        orig_raw_graph = @emap_term.instance_variable_get(:@graph).raw_graph
        new_raw_graph  = new_graph.instance_variable_get(:@graph).raw_graph

        assert_equal 34, @emap_term.size
        assert_equal 19, new_graph.size

        assert_equal 34, orig_raw_graph.keys.size
        assert_equal 19, new_raw_graph.keys.size

        assert orig_raw_graph.keys.include?('EMAP:3003')
        assert_equal false, new_raw_graph.keys.include?('EMAP:3003')
      end

      should 'be able to "detach" the graph to be able to retain just parents' do
        # We expect the following here...
        #
        # * EMAP:0
        #     |---+ EMAP:2636
        #         |---+ EMAP:2822
        #             |---+ EMAP:2987
        #                 |---+ EMAP:3018

        @emap_term.focus_graph!
        @emap_term.remove_children!

        assert_equal 'EMAP:3018', @emap_term.term_id
        assert_equal 'EMAP:0', @emap_term.root.term_id
        assert_equal 5, @emap_term.size
        assert_equal 5, @emap_term.instance_variable_get(:@graph).raw_graph.size

        # Test the copy variant of this function
        @mp_term.focus_graph!
        new_term = @mp_term.remove_children

        assert new_term.object_id != @mp_term.object_id
        assert new_term.is_leaf?
        assert_equal 'MP:0000001', new_term.root.term_id
        assert_equal 7, new_term.size
        assert_equal 7, new_term.instance_variable_get(:@graph).raw_graph.size
        assert_equal 105, @mp_term.size
        assert_equal 105, @mp_term.instance_variable_get(:@graph).raw_graph.size
      end

      should 'be able to "detach" the graph to be able to retain just children' do
        # We expect the following here...
        #
        # |---+ EMAP:3018
        #     |---+ EMAP:3022
        #         |---+ EMAP:3023
        #             |---+ EMAP:3024
        #                 |---> EMAP:3025
        #                 |---> EMAP:3026
        #             |---+ EMAP:3027
        #                 |---> EMAP:3029
        #                 |---> EMAP:3028
        #             |---+ EMAP:3030
        #                 |---> EMAP:3031
        #                 |---> EMAP:3032
        #     |---> EMAP:3019
        #     |---+ EMAP:3020
        #         |---> EMAP:3021

        @emap_term.focus_graph!
        @emap_term.remove_parents!

        assert_equal 'EMAP:3018', @emap_term.term_id
        assert @emap_term.is_root?
        assert_equal 15, @emap_term.size
        assert_equal 15, @emap_term.instance_variable_get(:@graph).raw_graph.size

        # Test the copy variant of this function
        @mp_term.focus_graph!
        new_term = @mp_term.remove_parents

        assert new_term.object_id != @mp_term.object_id
        assert_equal 99, new_term.size
        assert_equal 99, new_term.instance_variable_get(:@graph).raw_graph.size
        assert_equal 105, @mp_term.size
        assert_equal 105, @mp_term.instance_variable_get(:@graph).raw_graph.size
      end

      should 'be able to merge in another ontology graph that shares a common root term' do
        # We're going to try and merge this subgraph (for EMAP:3018)
        #
        # * EMAP:0
        #     |---+ EMAP:2636
        #         |---+ EMAP:2822
        #             |---+ EMAP:2987
        #                 |---+ EMAP:3018
        #                     |---+ EMAP:3022
        #                         |---+ EMAP:3023
        #                             |---+ EMAP:3024
        #                                 |---> EMAP:3025
        #                                 |---> EMAP:3026
        #                             |---+ EMAP:3027
        #                                 |---> EMAP:3029
        #                                 |---> EMAP:3028
        #                             |---+ EMAP:3030
        #                                 |---> EMAP:3031
        #                                 |---> EMAP:3032
        #                     |---> EMAP:3019
        #                     |---+ EMAP:3020
        #                         |---> EMAP:3021
        #
        # With this one (for EMAP:3003)
        #
        # * EMAP:0
        #     |---+ EMAP:2636
        #         |---+ EMAP:2822
        #             |---+ EMAP:2987
        #                 |---+ EMAP:3003
        #                     |---> EMAP:3012
        #                     |---+ EMAP:3013
        #                         |---> EMAP:3014
        #                         |---> EMAP:3016
        #                         |---> EMAP:3015
        #                         |---> EMAP:3017
        #                     |---+ EMAP:3004
        #                         |---> EMAP:3005
        #                     |---> EMAP:3006
        #                     |---+ EMAP:3007
        #                         |---> EMAP:3008
        #                         |---> EMAP:3009
        #                     |---+ EMAP:3010
        #                         |---> EMAP:3011
        #
        # To give us...
        #
        # * EMAP:0
        #     |---+ EMAP:2636
        #         |---+ EMAP:2822
        #             |---+ EMAP:2987
        #                 |---+ EMAP:3018
        #                     |---+ EMAP:3022
        #                         |---+ EMAP:3023
        #                             |---+ EMAP:3024
        #                                 |---> EMAP:3025
        #                                 |---> EMAP:3026
        #                             |---+ EMAP:3027
        #                                 |---> EMAP:3029
        #                                 |---> EMAP:3028
        #                             |---+ EMAP:3030
        #                                 |---> EMAP:3031
        #                                 |---> EMAP:3032
        #                     |---> EMAP:3019
        #                     |---+ EMAP:3020
        #                         |---> EMAP:3021
        #                 |---+ EMAP:3003
        #                     |---> EMAP:3012
        #                     |---+ EMAP:3013
        #                         |---> EMAP:3014
        #                         |---> EMAP:3016
        #                         |---> EMAP:3015
        #                         |---> EMAP:3017
        #                     |---+ EMAP:3004
        #                         |---> EMAP:3005
        #                     |---> EMAP:3006
        #                     |---+ EMAP:3007
        #                         |---> EMAP:3008
        #                         |---> EMAP:3009
        #                     |---+ EMAP:3010
        #                         |---> EMAP:3011
        #

        @emap_term.focus_graph!
        assert_equal 19, @emap_term.size

        @emap_term.merge!( OLS.find_by_id('EMAP:3003') )
        assert_equal 34, @emap_term.size

        main_merge_node = @emap_term.root['EMAP:2636']['EMAP:2822']['EMAP:2987']

        assert main_merge_node.is_a?(OLS::Term)
        assert_equal 2, main_merge_node.children.size
        assert main_merge_node.children.map(&:term_id).include? 'EMAP:3003'
        assert main_merge_node.children.map(&:term_id).include? 'EMAP:3018'

        assert_equal 'TS18,perioptic mesenchyme', @emap_term.root['EMAP:2636']['EMAP:2822']['EMAP:2987']['EMAP:3003']['EMAP:3012'].term_name
        assert_equal 'TS18,retina', @emap_term.root['EMAP:2636']['EMAP:2822']['EMAP:2987']['EMAP:3003']['EMAP:3013'].term_name

        # Also check that the internal graph has been merged accordingly
        raw_graph      = @emap_term.instance_variable_get(:@graph).raw_graph
        emap3003_graph = raw_graph['EMAP:3003'][:object].instance_variable_get(:@graph).raw_graph
        assert_equal 34, raw_graph.size
        assert_equal raw_graph.object_id, emap3003_graph.object_id

        another_ont     = OLS.find_by_id('GO:0023034')
        yet_another_ont = OLS.find_by_id('EMAP:3003')

        assert_raise(ArgumentError) { another_ont.merge!(yet_another_ont) }
        assert_raise(TypeError) { another_ont.merge!('EMAP:3003') }
      end

      should 'allow deep copying of objects' do
        @emap_term.focus_graph!
        copy = @emap_term.dup

        assert @emap_term.object_id != copy.object_id
        assert @emap_term.instance_variable_get(:@graph).object_id != copy.instance_variable_get(:@graph).object_id
        assert @emap_term.instance_variable_get(:@graph).raw_graph.object_id != copy.instance_variable_get(:@graph).raw_graph.object_id
        assert_equal @emap_term.size, copy.size
        assert_equal @emap_term.root.term_id, copy.root.term_id
      end

      should 'allow serialization using Marshal' do
        @emap_term.focus_graph!

        OLS.stubs(:request).returns(nil)

        # check the stubbing is okay...
        assert_raise(ArgumentError) { foo = OLS.find_by_id('EMAP:3003') }

        # now get on with testing marshal...
        data = Marshal.dump(@emap_term)
        copy = Marshal.load(data)

        assert_equal @emap_term.term_id, copy.term_id
        assert_equal @emap_term.term_name, copy.term_name
        assert_equal @emap_term.size, copy.size
        assert_equal @emap_term.root.term_id, copy.root.term_id
        assert_equal @emap_term.all_parent_ids, copy.all_parent_ids
        assert_equal @emap_term.all_parent_names, copy.all_parent_names

        OLS.unstub(:request)
      end

      should 'allow users to write image files showing the graph structure' do
        @mp_term.focus_graph!
        assert_silent do
          @mp_term.write_children_to_graphic_file('children')
          @mp_term.write_parentage_to_graphic_file('parentage')
        end
        system("rm children.dot children.png parentage.dot parentage.png")
      end

      should 'allow users to print a graph representation of the graph to STDOUT' do
        @emap_term.focus_graph!
        emap_graph = <<-EMAP
* EMAP:0 - Mouse_anatomy_by_time_xproduct
    |---+ EMAP:2636 - TS18,embryo
        |---+ EMAP:2822 - TS18,organ system
            |---+ EMAP:2987 - TS18,sensory organ
                |---+ EMAP:3018 - TS18,nose
                    |---+ EMAP:3022 - TS18,process,nose
                        |---+ EMAP:3023 - TS18,fronto-nasal process
                            |---+ EMAP:3024 - TS18,frontal process
                                |---> EMAP:3025 - TS18,ectoderm,frontal process
                                |---> EMAP:3026 - TS18,mesenchyme,frontal process
                            |---+ EMAP:3027 - TS18,latero-nasal process
                                |---> EMAP:3029 - TS18,mesenchyme,latero-nasal process
                                |---> EMAP:3028 - TS18,ectoderm,latero-nasal process
                            |---+ EMAP:3030 - TS18,medial-nasal process
                                |---> EMAP:3031 - TS18,ectoderm,medial-nasal process
                                |---> EMAP:3032 - TS18,mesenchyme,medial-nasal process
                    |---> EMAP:3019 - TS18,naso-lacrimal groove
                    |---+ EMAP:3020 - TS18,olfactory pit
                        |---> EMAP:3021 - TS18,nasal epithelium
EMAP

        assert_output(emap_graph.lstrip,nil) do
          @emap_term.root.print_graph(true)
        end
      end
    end
  end
end

