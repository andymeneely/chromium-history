class Block < ActiveRecord::Base
  
  belongs_to :blocked_on, primary_key: 'blocked_on_id', foreign_key: 'bug_id' 
  belongs_to :blocking_bug, primary_key: 'blocking_id', foreign_key: 'bug_id'
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :blocks, :blocked_on_id 
    ActiveRecord::Base.connection.add_index :blocks, :blocking_id 
  end
end
