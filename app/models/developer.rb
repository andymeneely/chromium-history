class Developer < ActiveRecord::Base
  has_many :code_reviews

  def self.on_optimize
    
  end

end