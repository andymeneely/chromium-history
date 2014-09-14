require 'treat'
include Treat::Core::DSL


class Corpus

  @doc = nil

  def initialize source
    # Set paths to stanford libs
    Treat.libraries.stanford.jar_path = ENV['STANFORD_NLP']
    Treat.libraries.stanford.model_path = ENV['STANFORD_NLP']

    # Create document from text file, serialized file, or MongoDB key 
    @doc = document source
  end

  # Pass method calls not specified in class to Treat Document class
  def method_missing method_id, *arguments
    @doc.send(method_id, *arguments)
  end

  def word_count file
    word_counts = {}
    unique_words = Set.new
    @doc.words.each do |word| 
      down = word.to_s.downcase
      if unique_words.add? down
        word_counts[down] = p.frequency_of down
      end
    end

    word_popularity = word_counts.sort_by { |key, value| value }.reverse

    if file
      output = File.open file
      output.write word_popularity.inspect
    else
      puts word_popularity.inspect
    end
  end
end 
