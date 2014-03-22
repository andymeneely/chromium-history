class RemoveCvesInCodeReviews < ActiveRecord::Migration

  def up
    remove_column :code_reviews, :cve
    drop_table :cves
  end

  def down
    create_table :cves do |t|
      t.string :cve
    end 
    add_column :code_reviews, :cve, :string
  end
end
