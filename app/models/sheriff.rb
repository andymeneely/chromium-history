class Sheriff < ActiveRecord::Base
	 belongs_to :developer, foreign_key: "email", primary_key: "email"
	 belongs_to :participant, primary_key: "email", foreign_key: "email"
	 belongs_to :reviewer, primary_key: "email", foreign_key: "email"

   def self.on_optimize
     ActiveRecord::Base.connection.add_index :sheriffs, :email#, unique: true 	#should email be unique? what if there is a 
     																			#developer who has been sheriff for two different
     																			#types of sheriff events? is that possible?
     ActiveRecord::Base.connection.add_index :sheriffs, :start
     ActiveRecord::Base.connection.add_index :sheriffs, :end
     ActiveRecord::Base.connection.add_index :sheriffs, :title
   end

end
