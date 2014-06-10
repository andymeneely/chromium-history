class Reviewer < ActiveRecord::Base
	
	belongs_to :code_review, foreign_key: 'issue', primary_key: 'issue'
	belongs_to :developer, foreign_key: "dev_id", primary_key: "id"

	has_many :sheriffs, primary_key: 'dev_id', foreign_key: 'dev_id'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :reviewers, :issue
    ActiveRecord::Base.connection.add_index :reviewers, :dev_id
  end

end
