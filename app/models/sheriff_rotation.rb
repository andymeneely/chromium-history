class SheriffRotation < ActiveRecord::Base
	 belongs_to :developer, foreign_key: "id", primary_key: "dev_id"
	 belongs_to :participant, primary_key: "dev_id", foreign_key: "dev_id"
	 belongs_to :reviewer, primary_key: "dev_id", foreign_key: "dev_id"

   def self.on_optimize
     ActiveRecord::Base.connection.add_index :sheriff_rotation, :dev_id, unique: true 
     ActiveRecord::Base.connection.add_index :sheriff_rotation, :start
     ActiveRecord::Base.connection.add_index :sheriff_rotation, :end
     ActiveRecord::Base.connection.add_index :sheriff_rotation, :title
   end

end
