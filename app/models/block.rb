class Block < ActiveRecord::Base
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :blocks, :blocked_on_id 
    ActiveRecord::Base.connection.add_index :blocks, :blocking_id 
  end
end
