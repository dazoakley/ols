# encoding: utf-8

module OLS
  class Term
    attr_reader :id, :name

    def initialize(id,name)
      @id = id
      @name = name
    end

    def parents
      []
    end
  end
end
