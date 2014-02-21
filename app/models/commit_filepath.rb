class CommitFilepath < ActiveRecord::Base
	belongs_to :commit
	belongs_to :filepath
	
	def self.on_optimize
		#ActiveRecord::Base.connection.add_index :commits, :commit_id #exception raised
		#ActiveRecord::Base.connection.add_index :filepaths, :filepath_id #exception raised
	end
	
end
