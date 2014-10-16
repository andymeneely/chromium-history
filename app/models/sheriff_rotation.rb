class SheriffRotation < ActiveRecord::Base
	 belongs_to :developer, foreign_key: "id", primary_key: "dev_id"

   def self.optimize
     connection.add_index :sheriff_rotations, :dev_id 
     connection.add_index :sheriff_rotations, :start
     connection.add_index :sheriff_rotations, :duration
     connection.add_index :sheriff_rotations, :title
   end

end
