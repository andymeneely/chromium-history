class CodeReview < ActiveRecord::Base
  has_many :patch_sets
  has_many :messages
end
