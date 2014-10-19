require 'treat'
require 'set'
include Treat::Core::DSL


class Corpus

  def initialize 

    # Set paths to stanford libs
    Treat.libraries.stanford.jar_path = ENV['STANFORD_NLP']
    Treat.libraries.stanford.model_path = ENV['STANFORD_NLP']

    # Set path to punkt segmenter models
    Treat.libraries.punkt.model_path = ENV['PUNKT_MODELS']
  end

  # Pass method calls not specified in class to Treat Document class
  def method_missing method_id, *arguments
    @col.send(method_id, *arguments)
  end

  def create doc
    doc.apply :chunk
    doc.apply({:segment => :punkt})
    doc.apply({:tokenize => :punkt})
    doc
  end

  def word_diff a, b
    set_a = clean_vocab a
    set_b = clean_vocab b
    set_a - set_b
  end

  def word_intersect a, b
    set_a = clean_vocab a
    set_b = clean_vocab b
    set_a & set_b
  end

  def clean_vocab wordlist
    result = Set.new
    wordlist.each do |word|
      result.add word.downcase.stem
    end
  end
end 
