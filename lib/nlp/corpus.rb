require 'treat'
include Treat::Core::DSL


class Corpus

  @col = nil
  @db = nil

  # attr_accessor :doc
  def initialize source, db
    @db = db

    # Set paths to stanford libs
    Treat.libraries.stanford.jar_path = ENV['STANFORD_NLP']
    Treat.libraries.stanford.model_path = ENV['STANFORD_NLP']

    # Set path to punkt segmenter models
    Treat.libraries.punkt.model_path = ENV['PUNKT_MODELS']

    # Set mongodb configs
    Treat.databases.mongo.db = @db
    Treat.databases.mongo.host = 'localhost'
    Treat.databases.mongo.port = '27017'

    # Create collection from text file, serialized file, or MongoDB key 
    @col = collection source
  end

  # Pass method calls not specified in class to Treat Document class
  def method_missing method_id, *arguments
    @col.send(method_id, *arguments)
  end

  def word_count output_file = nil
    word_counts = {}
    @col.documents.each do |document|
      raise 'Document needs to be tokenized before words are available' unless document.words
      document.words.each do |word| 
        down = word.to_s.downcase
        word_counts[down] ||= 0
        word_counts[down] +=1
      end
    end
    word_counts.sort_by { |key, value| value }.reverse
  end

  def export_to_mongo
    @col.documents.each do | doc |
      doc.serialize  :mongo, db: @db
    end
  end
end 
