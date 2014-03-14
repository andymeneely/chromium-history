class FilepathConsolidator

  # Given all locations of filepaths that we know of, make one Filepath table
  def consolidate
    query=<<-eos
    INSERT INTO filepaths (path) 
      SELECT DISTINCT filepath AS joined_paths FROM(
        SELECT filepath FROM commit_filepaths
        UNION
        SELECT filepath FROM patch_set_files
      ) WHERE NOT EXISTS (SELECT * FROM filepaths WHERE path = joined_paths)
    eos
    ActiveRecord::Base.connection.execute query
  end

end
