# Note: this model represents a message, not a comment. Messages are associated with code reviews, comments are associated with patchset (which are associated with code reviews)
class Message < ActiveRecord::Base
  belongs_to :code_review
  
  def self.optimize
    connection.add_index :messages, :sender
    connection.add_index :messages, :code_review_id
  end
end
