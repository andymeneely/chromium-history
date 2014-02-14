class AddCveRietveldLookup < ActiveRecord::Migration
	def change
		create_table :cve_rietveld do | t |
	    t.string 	:cve
	    t.integer :issue_id
		end

		add_index :cve_rietveld, [:cve, :issue_id] 

		create_table :gcode do | t |
			t.integer :gcode_id
		end

		add_index :gcode, [:gcode_id], unique: true

		create_table :gcode_rietveld do | t |
			t.integer	:gcode_id
			t.integer :issue_id
		end

		add_index :cve_rietveld, [:gcode, :issue_id]
	end
end
