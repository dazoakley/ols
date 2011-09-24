require 'test_helper'

class OLSTermTest < Test::Unit::TestCase
  context 'An OLS::Term object' do
    context 'once created' do
      setup do
        @term = OLS.find_by_id('EMAP:3018')
      end

      should 'be able to report its parents' do
        assert_equal 1, @term.parents.size
        assert_equal 'EMAP:2987', @term.parents.first.id
      end

      should 'be able to report its children' do
        assert_equal 3, @term.children.size
        emap3022_included = false
        @term.children.each do |child|
          emap3022_included = true if child.id.eql?('EMAP:3022')
        end
        assert emap3022_included
      end
    end
  end
end

