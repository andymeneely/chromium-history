class CodeReviewCveLookup < ActiveRecord::Migration
	def change
		rename_table :cves, :cvenums
		create_table :code_reviews_cvenums, id: false do | t |
		    t.integer :cve
		    t.integer :issue
		end

		add_index :code_reviews_cvenums, [:cve, :issue]
	end
end
