class Comment < ActiveRecord::Base
  belongs_to :patch_set_file

end
