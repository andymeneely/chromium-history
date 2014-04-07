class Reviewer < ActiveRecord::Base
	belongs_to :code_review, primary_key: "issue", foreign_key: "issue"
	belongs_to :developer, foreign_key: "email", primary_key: "email"

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :reviewers, :issue
    ActiveRecord::Base.connection.add_index :reviewers, :email
  end

end
