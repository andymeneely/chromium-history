class Cvenum < ActiveRecord::Base
  has_and_belongs_to_many :code_reviews
  self.primary_key = :cve

  def self.on_optimize
  	#fix me - problem is in cve loader
    # ActiveRecord::Base.connection.add_index :cvenums, :cve, unique: true
    # ActiveRecord::Base.connection.add_index :code_reviews_cvenums, [:cvenum_id, :code_review_id], unique: true
  end

end
