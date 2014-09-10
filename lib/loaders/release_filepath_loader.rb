require 'csv'

class ReleaseFilepathLoader

  def load
    # Transfer to a new csv by padding with however empty columns we have. 
    # e.g. if we have 5 total columns, the new csv will look like:
    #   11,some/file.c ==> 11,some/file.c,,,
    tmp = Rails.configuration.tmpdir
    CSV.open("#{tmp}/release_filepaths.csv",'w+') do |csv|
      Dir["#{Rails.configuration.datadir}/releases/*.csv"].each do |rcsv|
        name,date = '',''
        CSV.foreach(rcsv) do |line|
          name,date = line[0],line[1] #save the last one
          if ReleaseFilepath.source_code? line[2]
            out_line = [line[0], line[2]] #release,filepath
            (ReleaseFilepath.columns.count - 2).times { out_line << nil} #pad with emptys
            csv << out_line #append the line to the file
          end
        end
        Release.create(name: name, date: date)
      end
    end

    copy = "COPY release_filepaths FROM '#{tmp}/release_filepaths.csv' DELIMITER ',' CSV"
    ActiveRecord::Base.connection.execute(copy)
  end
end
