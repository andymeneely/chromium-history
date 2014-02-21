class CodeReviewCveLookup < ActiveRecord::Migration
	def change
		rename_table :cves, :cvenums
		create_table :code_reviews_cvenums, id: false do | t |
		    t.integer :cvenum_id
		    t.integer :code_review_id
		end

		add_index :code_reviews_cvenums, [:cvenum_id, :code_review_id]
	end
end
