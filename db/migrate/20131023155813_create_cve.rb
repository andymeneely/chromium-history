class CreateCve < ActiveRecord::Migration
  def change
    create_table :cves do |t|
      t.string :cve
    end
  end
end
