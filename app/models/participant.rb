class Participant < ActiveRecord::Base
	belongs_to :code_review, primary_key: "issue", foreign_key: "issue"
	belongs_to :developer, foreign_key: "email", primary_key: "email"

	has_many :sheriffs, primary_key: 'email', foreign_key: 'email'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :participants, :email
    ActiveRecord::Base.connection.add_index :participants, :issue
    ActiveRecord::Base.connection.add_index :participants, [:email, :issue], unique: true
  end

end
