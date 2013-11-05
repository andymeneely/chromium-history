class CommitFile < ActiveRecord::Base
belongs_to :commit

  def self.on_optimize
  end
 

end
