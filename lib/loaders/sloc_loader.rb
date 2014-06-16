require 'csv'

class SlocLoader

  def load
    datadir =  File.expand_path(Rails.configuration.datadir)
    CSV.foreach("#{datadir}/sloc/sloc.csv") do |line|
      if $. == 1 or $. == 2
        next
      end
      match = line[1].match(/([^\.\/].+)/) #removes ./ from pathname
      update = "UPDATE release_filepaths SET sloc = #{line[4]} WHERE thefilepath = '#{match[1]}'"
      ActiveRecord::Base.connection.execute(update)
    end
  end
end
