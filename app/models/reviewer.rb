class Reviewer < ActiveRecord::Base
	belongs_to :code_review

  def self.on_optimize
  end

end