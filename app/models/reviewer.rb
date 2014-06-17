class Reviewer < ActiveRecord::Base
	
	belongs_to :code_review, foreign_key: 'issue', primary_key: 'issue'
	belongs_to :developer, foreign_key: "dev_id", primary_key: "id"

	has_many :sheriffs, primary_key: 'dev_id', foreign_key: 'dev_id'

  def self.on_optimize
    connection.add_index :reviewers, :issue
    connection.add_index :reviewers, :dev_id
    connection.add_index :reviewers, [:issue, :dev_id]
    connection.execute "CLUSTER reviewers USING index_reviewers_on_issue_and_dev_id"
  end

end
