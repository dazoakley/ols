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
        @term = OLS.find_by_id('EMAP:3018')
      end

      should 'have an id/term and a name' do
        assert_equal 'EMAP:3018', @term.term_id
        assert_equal 'TS18,nose', @term.term_name
      end

      should 'be able to represent itself as a string' do
        assert_equal 'EMAP:3018 - TS18,nose', @term.to_s
      end

      should 'be able to report its parents' do
        assert_equal 1, @term.parents.size
        assert_equal 'EMAP:2987', @term.parents.first.term_id
      end

      should 'be able to generate a flat list of ALL parents (up the ontology)' do
        assert @term.all_parents.is_a? Array
        assert @term.all_parents.first.is_a? OLS::Term
        assert_equal 4, @term.all_parents.size
        assert_equal 'EMAP:0', @term.all_parents.first.term_id
      end

      should 'be able to generate a flat list of ALL parent terms/names' do
        assert @term.all_parent_ids.is_a? Array
        assert_equal 4, @term.all_parent_ids.size
        assert_equal 'EMAP:0', @term.all_parent_ids.first

        assert @term.all_parent_names.is_a? Array
        assert_equal 4, @term.all_parent_names.size
        assert_equal 'Mouse_anatomy_by_time_xproduct', @term.all_parent_names.first
      end

      should 'be able to report its children' do
        assert_equal 3, @term.children.size
        emap3022_included = false
        @term.children.each do |child|
          emap3022_included = true if child.term_id.eql?('EMAP:3022')
        end
        assert emap3022_included
      end

      should 'be able to generate a flat list of ALL children (down the ontology)' do
        assert @term.all_children.is_a? Array
        assert @term.all_children.first.is_a? OLS::Term
        assert_equal 14, @term.all_children.size
        emap3032_included = false
        @term.all_children.each do |child|
          emap3032_included = true if child.term_id.eql?('EMAP:3032')
        end
      end

      should 'be able to generate a flat list of ALL child terms/names' do
        assert @term.all_child_ids.is_a? Array
        assert_equal 14, @term.all_child_ids.size
        assert @term.all_child_ids.include?('EMAP:3032')

        assert @term.all_child_names.is_a? Array
        assert_equal 14, @term.all_child_names.size
        assert @term.all_child_names.include?('TS18,mesenchyme,medial-nasal process')
      end

      should "be able to say if it's a root/leaf node" do
        assert_equal false, @term.is_root?
        assert_equal false, @term.is_leaf?

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

