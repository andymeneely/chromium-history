class Comment < ActiveRecord::Base
  belongs_to :patch_set_file
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :comments, :composite_patch_set_file_id
  end
end
