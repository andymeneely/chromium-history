class AcmCategory < ActiveRecord::Base
  
  has_and_belongs_to_many :technical_words
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :name
  end
end