require 'csv'

class InteractiveChurn
  def parse_and_load
    datadir = File.expand_path(Rails.configuration.datadir)
    
    CSV.foreach("#{datadir}/churnlog.csv",{:headers=>:first_row}) do |line|
      release = line[0]
      filepath = line [1]
      CommitFilepath.where(commit_hash: release, filepath: filepath).update_all(lines_added: line[3],lines_deleted_self: line[5], lines_deleted_other: line[6], num_authors_affected: line[7]) 
    end
  end
end
