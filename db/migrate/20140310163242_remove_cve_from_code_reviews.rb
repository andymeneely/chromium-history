class RemoveCveFromCodeReviews < ActiveRecord::Migration
  def change
  	change_table :code_reviews do |t|
	  t.remove :cve
	end
  end
end
