class SwithIntToStringCveLink < ActiveRecord::Migration
  def change
  	change_column :code_reviews_cvenums, :cvenum_id, :string
  end
end
