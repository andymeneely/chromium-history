class Cvenum < ActiveRecord::Base
  #belongs_to :code_review
  has_and_belongs_to_many :code_reviews, foreign_key: 'cve', association_foreign_key: 'issue'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :cvenums, :cve, unique: true
  end

end
