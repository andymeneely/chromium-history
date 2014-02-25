class Cc < ActiveRecord::Base
	belongs_to :code_review
	has_one :developer, foreign_key: "id", primary_key: "developer"
	
  def self.on_optimize
  end

end