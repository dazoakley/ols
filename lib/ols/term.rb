# encoding: utf-8

module OLS
  class Term
    attr_reader :id, :name

    def initialize(id,name)
      @id = id
      @name = name

      @already_fetched_parents  = false
      @already_fetched_children = false
    end

    def parents
      unless @already_fetched_parents
        @parents = []
        response = OLS.request(:get_term_parents) { soap.body = { :termId => self.id } }
        unless response.nil?
          if response[:item].is_a? Array
            response[:item].each { |term| @parents.push( OLS::Term.new(term[:key],term[:value]) ) }
          else
            term = response[:item]
            @parents.push( OLS::Term.new(term[:key],term[:value]) )
          end
        end

        @already_fetched_parents = true
      end

      @parents
    end

    def children
      unless @already_fetched_children
        @children = []
        response = OLS.request(:get_term_children) {
          soap.body = {
            :termId => self.id,
            :distance => 1,
            :relationTypes => [2]
          }
        }
        unless response.nil?
          if response[:item].is_a? Array
            response[:item].each { |term| @children.push( OLS::Term.new(term[:key],term[:value]) ) }
          else
            term = response[:item]
            @children.push( OLS::Term.new(term[:key],term[:value]) )
          end
        end
      end
      @children
    end
  end
end
