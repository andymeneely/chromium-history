class CodeReview < ActiveRecord::Base
  has_many :patch_sets
  has_many :messages
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :code_reviews, :issue, unique: true
  end
end
