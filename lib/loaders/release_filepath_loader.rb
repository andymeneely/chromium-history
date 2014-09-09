require 'csv'

class ReleaseFilepathLoader

  def load
    #Yes, this is hardcoded to release 11.0 until we begin to analyze multiple releases
    Release.create(name: '11.0', date: DateTime.new(2011,01,28))
    datadir = File.expand_path(Rails.configuration.datadir)

    # Transfer to a new csv by padding with however empty columns we have. 
    # e.g. if we have 5 total columns, the new csv will look like:
    #   11,some/file.c ==> 11,some/file.c,,,
    CSV.open("/tmp/release_filepaths_11.0.csv",'w+') do |csv|
      CSV.foreach("#{datadir}/releases/11.0.csv") do |line|
        if ReleaseFilepath.source_code? line[1]
          out_line = [line[0], line[1]] #release,filepath
          (ReleaseFilepath.columns.count - 2).times { out_line << nil} #pad with emptys
          csv << out_line #append the line to the file
        end
      end
    end

    copy = "COPY release_filepaths FROM '/tmp/release_filepaths_11.0.csv' DELIMITER ',' CSV"
    ActiveRecord::Base.connection.execute(copy)
  end
end
