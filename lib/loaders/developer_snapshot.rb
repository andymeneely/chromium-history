require 'csv'

class DeveloperSnapshot
	
  def parse_and_load
    tmp = Rails.configuration.tmpdir	
    Dir["#{tmp}/graph_degree_files/*.csv"].each do |file|
      @devs = CSV.open("#{tmp}/dev_snapshot.csv", w+)
		
      # gets from the csv file (in order)
      #dev_id, degree, centrality, shriff_hrs, sec_exp, bugsec_exp, own_count, start_date, end_date
      CSV.parse(file.drop(2).join) do |row|
        @devs << [line[0],line[1],line[2],line[3],line[4],line[5], line[6],line[7],line[8]]
      end 
      @devs.fsync
      PsqlUtil.copy_from_file 'developer_snapshot', "#{tmp}/dev_snapshot.csv"
    end	
  end
end
