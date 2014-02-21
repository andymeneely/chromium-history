class FilepathConsolidator

  # Given all locations of filepaths that we know of, make one Filepath table
  def consolidate
    query=<<-eos
    INSERT INTO filepaths(filepath) (
      SELECT DISTINCT filepath FROM(
        SELECT filepath from commit_filepaths
        UNION
        SELECT filepath from patch_set_files
      ) all_filepaths
    )
    eos
    ActiveRecord::Base.connection.execute query
  end

end
