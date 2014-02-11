class PatchSetFile < ActiveRecord::Base
  belongs_to :patch_set, primary_key: 'composite_patch_set_id'
  has_many :comments, foreign_key: 'composite_patch_set_file_id', primary_key: 'composite_patch_set_file_id'
end
