require 'set'
require 'oj'

class Corpus

  def initialize raw
    @raw_file = raw
    @words = nil
    @tmp_dir = Rails.configuration.tmpdir
  end

  def words
    if @words
      return @words
    else
      path = Rails.root.join 'lib', 'nlp', 'python', 'tokenizer.py'
      res = `python #{path} #{@raw_file}`
      @words = Oj.load(res)
      return @words
    end
  end

  def filter
    Oj.to_file @tmp_dir + '/wordlist.json', words()
    path = Rails.root.join 'lib', 'nlp', 'python', 'json_word_diff.py'
    res = `python #{path} #{@tmp_dir}/wordlist.json`
    @words = Oj.load(res)
  end

  def word_diff other
    set_a = clean_vocab words()
    set_b = clean_vocab other
    set_a - set_b
  end

  def word_intersect other
    set_a = clean_vocab words()
    set_b = clean_vocab other
    set_a & set_b
  end

  def clean_vocab wordlist
    result = Set.new
    wordlist.each do |word|
      result.add word.downcase
    end
    result
  end
end 
