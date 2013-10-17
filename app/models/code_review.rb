class CodeReview < ActiveRecord::Base
  has_many :patch_sets
end
