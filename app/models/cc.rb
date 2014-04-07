class Cc < ActiveRecord::Base
	belongs_to :code_review
	has_one :developer, foreign_key: "email", primary_key: "email"
	
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :ccs, :issue
    ActiveRecord::Base.connection.add_index :ccs, :email
  end

end
