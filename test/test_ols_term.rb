require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Term object' do
    setup do
      VCR.insert_cassette('test_ols_term')
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
        assert_equal 'abnormal skeleton extremities morphology', @mp_term.term_name
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
        assert_equal 'any structural anomaly of the limb, autopod or tail bones', @mp_term.definition

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

        mp_term_parent_term_ids = @mp_term.parents.map(&:term_id)

        assert_equal 2, @mp_term.parents.size
        assert mp_term_parent_term_ids.include?('MP:0000545')
        assert mp_term_parent_term_ids.include?('MP:0009250')
      end

      should 'be able to generate a flat list of ALL parents (up the ontology)' do
        assert @emap_term.all_parents.is_a? Array
        assert @emap_term.all_parents.first.is_a? OLS::Term
        assert_equal 4, @emap_term.all_parents.size
        assert_equal 'EMAP:0', @emap_term.all_parents.first.term_id

        assert @mp_term.all_parents.is_a? Array
        assert @mp_term.all_parents.first.is_a? OLS::Term
        assert_equal 7, @mp_term.all_parents.size
        assert_equal 'MP:0000001', @mp_term.all_parents.first.term_id
        assert_equal 'MP:0000001', @mp_term.all_parents[2].term_id
        assert @mp_term.all_parents.last.term_id =~ /MP:0000545|MP:0009250/
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
        assert_equal 3, @emap_term.children.size
        emap3022_included = false
        @emap_term.children.each do |child|
          emap3022_included = true if child.term_id.eql?('EMAP:3022')
        end
        assert emap3022_included
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
    end
  end
end

