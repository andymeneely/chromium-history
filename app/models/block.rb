class Block < ActiveRecord::Base
  
  belongs_to :blocked_by, primary_key: 'bug_id', foreign_key: 'bug_id',:class_name => "Bug" 
  belongs_to :blocking, primary_key: 'bug_id', foreign_key: 'blocking_id',:class_name => "Bug" 
  
  def self.optimize
    connection.add_index :blocks, :bug_id 
    connection.add_index :blocks, :blocking_id 
  end
end
