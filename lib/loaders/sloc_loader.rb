require 'csv'

class SlocLoader

  def load
   Dir["#{Rails.configuration.datadir}/sloc/*.csv"].each do |file|
      release_num = file.match(/\d+.\d/).to_s
      datadir =  File.expand_path(Rails.configuration.datadir)
      CSV.foreach(file) do |line|
        match = line[1].match(/([^\.\/].+)/) #removes ./ from pathname
        ReleaseFilepath.where(release: release_num, thefilepath: match[1].to_s).update_all(sloc: line[4])
      end
    end
  end
end
