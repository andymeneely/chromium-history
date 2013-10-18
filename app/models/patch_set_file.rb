class PatchSetFile < ActiveRecord::Base
  belongs_to :patch_set
  has_many :comments
end
