class CommitFilepath < ActiveRecord::Base
	belongs_to :commit
	belongs_to :filepath

end
