class FilepathConsolidator

  # Given all locations of filepaths that we know of, make one Filepath table
  def consolidate
    query=<<-eos
    INSERT INTO filepaths (filepath) 
      SELECT DISTINCT filepath FROM(
        SELECT filepath FROM commit_filepaths
        UNION
        SELECT filepath FROM patch_set_files
        UNION 
        SELECT filepath from release_filepaths
      ) all_filepath
    eos
    ActiveRecord::Base.connection.execute query
  end

end
