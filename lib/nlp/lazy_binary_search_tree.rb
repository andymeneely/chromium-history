class LazyBinarySearchTree

  def initialize words
    @root = Parent.new nil, words
  end

  def search vector
    @root.search vector
  end

  class Node 
    def initialize words
      @words = words
    end

    def in? vector
      result = ActiveRecord::Base.connection.execute "SELECT to_tsvector('#{vector}') @@ '#{query}' AS found"
      result[0]['found'] == 't'
    end

    def search vector
      raise "Must override this method"
    end

    def query
      raise "Must override this method"
    end
  end

  class Parent < Node
    def initialize parent, words
      super words
      if parent
        @parent = parent 
      else
        @parent = nil
      end
      @left = nil
      @right = nil
    end

    def query
      return @query if @query
      words  = @words.map {|word| word['word']}
      @query = words.join(' | ')
    end

    def left 
      unless @left
        @left = make_child @words.slice(0, (@words.size/2).round)
      end
      @left
    end

    def right
      unless @right
        @right = make_child @words.slice((@words.size/2).round, @words.size)
      end
      @right
    end

    def make_child chunk
      if chunk.size == 1
        return Leaf.new self, chunk
      else
        return Parent.new self, chunk
      end
    end

    def search vector
      if in? vector
        l = left().search vector
        return l if l
        r = right().search vector
        return r if r
      end
      nil
    end
  end

  class Leaf < Node
    def initialize parent, word
      super word
      @parent = parent
      @id = word[0]['id']
    end

    def search vector
      return @words[0] if in? vector
      nil
    end

    def query
      return @query if @query
      @query = @words[0]['word']
    end
  end

end