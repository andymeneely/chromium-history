require 'csv'

class SlocLoader

  def load
    datadir =  File.expand_path(Rails.configuration.datadir)
    CSV.foreach("#{datadir}/sloc/sloc.csv") do |line|
      match = line[1].match(/([^\.\/].+)/) #removes ./ from pathname
      ReleaseFilepath.where(thefilepath: match[1].to_s).update_all(sloc: line[4])
    end
  end
end
