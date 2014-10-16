class Cvenum < ActiveRecord::Base
  has_and_belongs_to_many :code_reviews
  self.primary_key = :cve

  def self.optimize
    connection.add_index :cvenums, :cve, unique: true
    connection.add_index :code_reviews_cvenums, [:cvenum_id, :code_review_id], unique: true
    connection.execute 'CLUSTER code_reviews_cvenums USING index_code_reviews_cvenums_on_cvenum_id_and_code_review_id'
  end

end
