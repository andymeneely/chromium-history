class Cve < ActiveRecord::Base
  #belongs_to :code_review

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :cves, :cve, unique: true
  end

end
