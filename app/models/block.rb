class Block < ActiveRecord::Base
  
  belongs_to :bug, primary_key: 'bug_id', foreign_key: 'bug_id' 
#  belongs_to :blocking_bug, primary_key: 'blocking_id', foreign_key: 'bug_id'
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :blocks, :bug_id 
    ActiveRecord::Base.connection.add_index :blocks, :blocking_id 
  end
end
