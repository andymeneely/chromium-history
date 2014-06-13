require 'csv'

class SlocLoader

  def load
    datadir =  File.expand_path(Rails.configuration.datadir)
    CSV.foreach("#{datadir}/sloc/sloc.csv") do |line|
      if $. == 1 or $. == 2
        next
      end
      match = line[1].match(/([^\.\/].+)/) #removes ./ from pathname
      out_line = [match[1], line[4]] #filepath, sloc
    end
  end
end
