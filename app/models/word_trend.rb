class WordTrend < ActiveRecord::Base
  belongs_to :technical_word, foreign_key: 'word', primary_key: 'word'
end
