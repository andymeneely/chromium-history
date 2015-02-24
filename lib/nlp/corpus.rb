require 'set'
require 'oj'

# This class provides a facade for running python nltk scripts
# and basic word set operations
# TODO: Add tagging to tokeninzation process
class Corpus

  @@BROWN_CATEGORIES=[
    'fiction',
    'news',
    'editorial',
    'reviews',
    'religion',
    'hobbies',
    'lore',
    'belles_lettres',
    'government',
    'learned',
    'mystery',
    'science_fiction',
    'adventure',
    'romance',
    'humor',
    'all' # tag for using all categories
  ]

  def initialize raw
    @raw_file = raw
    @words = nil
    @tmp_dir = Rails.configuration.tmpdir
  end

  # Tokenize raw text file given to the constructor
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

  # Remove words found in preset or specified corpuses
  def filter category=Rails.configuration.brown_category
    raise "Unknown category selected: #{category}" unless @@BROWN_CATEGORIES.include? category
    file_path = "#{@tmp_dir}/wordlist.json"
    tmp_file = File.new file_path, 'w+'
    Oj.to_stream tmp_file, words()
    tmp_file.fsync
    path = Rails.root.join 'lib', 'nlp', 'python', 'json_word_diff.py'
    res = nil
    res = `python #{path} #{category} #{file_path}`
    File.unlink file_path
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

  # Turns a word list into a downcased set
  def clean_vocab wordlist
    result = Set.new
    wordlist.each do |word|
      result.add word.downcase
    end
    result
  end
end 
