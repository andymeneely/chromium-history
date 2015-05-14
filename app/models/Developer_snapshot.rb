class DeveloperSnapshot < ActiveRecord::Base
  
  def self.optimize
    connection.add_index :developer_snapshots, :dev_id	
    connection.add_index :developer_snapshots, :degree
    connection.add_index :developer_snapshots, :centrality	
    connection.add_index :developer_snapshots, :shriff_hrs	
    connection.add_index :developer_snapshots, :sec_exp	
    connection.add_index :developer_snapshots, :bugsec_exp	
    connection.add_index :developer_snapshots, :own_count	
    connection.add_index :developer_snapshots, :start_date
    connection.add_index :developer_snapshots, :end_date
    connection.execute 'CLUSTER developer_snapshots USING index_developer_snapshots_on_start'
	
  end
end
