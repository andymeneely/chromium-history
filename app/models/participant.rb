class Participant < ActiveRecord::Base
	belongs_to :code_review, primary_key: "issue", foreign_key: "issue"
	belongs_to :developer, foreign_key: "dev_id", primary_key: "id"

	has_many :sheriffs, primary_key: 'email', foreign_key: 'email'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :participants, :dev_id
    ActiveRecord::Base.connection.add_index :participants, :issue
    ActiveRecord::Base.connection.add_index :participants, [:dev_id, :issue], unique: true
  end

end
