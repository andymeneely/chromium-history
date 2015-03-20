class TechnicalWord < ActiveRecord::Base
  
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :code_reviews
  has_and_belongs_to_many :commits
  has_and_belongs_to_many :acm_categories
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :word
  end
end