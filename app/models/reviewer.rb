class Reviewer < ActiveRecord::Base
	
	belongs_to :code_review, foreign_key: 'issue', primary_key: 'issue'

	has_one :developer, foreign_key: "email", primary_key: "email"

  def self.on_optimize
  end

end
