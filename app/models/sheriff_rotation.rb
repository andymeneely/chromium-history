class SheriffRotation < ActiveRecord::Base
	 belongs_to :developer, foreign_key: "id", primary_key: "dev_id"

   def self.on_optimize
     ActiveRecord::Base.connection.add_index :sheriff_rotations, :dev_id 
     ActiveRecord::Base.connection.add_index :sheriff_rotations, :start
     ActiveRecord::Base.connection.add_index :sheriff_rotations, :duration
     ActiveRecord::Base.connection.add_index :sheriff_rotations, :title
   end

end
