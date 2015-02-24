class TechnicalWord < ActiveRecord::Base
  
  has_and_belongs_to_many :messages

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :word
  end
end