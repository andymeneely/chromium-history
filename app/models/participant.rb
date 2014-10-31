class Participant < ActiveRecord::Base
	belongs_to :code_review, primary_key: "issue", foreign_key: "issue"
	belongs_to :developer, foreign_key: "dev_id", primary_key: "id"

  def self.optimize
    connection.add_index :participants, :dev_id
    connection.add_index :participants, :issue
    connection.add_index :participants, [:dev_id, :issue], unique: true
    connection.execute "CLUSTER participants USING index_participants_on_dev_id_and_issue"
  end

end
