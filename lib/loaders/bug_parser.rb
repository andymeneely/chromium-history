require 'csv'

class BugParser
  
  def parse_and_load_json
    
    @bug_entries = CSV.open("#{Rails.configuration.datadir}/bug_entries.csv", 'w+')
    
    Dir["#{Rails.configuration.datadir}/bugs/*.json"].each do |file|
      bug_obj = load_json file
      bug_obj["feed"]["entry"].each do |entry|
        
        @bug_entries << [entry["issues$id"]["$t"],
                         nil, #title
                         nil, #stars
                         nil, #status
                         nil, #reporter
                         nil, #opened
                         nil, #closed
                         nil, #modified
                         entry["issues$owner"]["issues$username"]["$t"],
                         entry["issues$owner"]["issues$uri"]["$t"],
                         entry["content"]["$t"]]
      end
    end
    @bug_entries.fsync    
    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY bugs FROM '#{datadir}/bug_entries.csv' DELIMITER ',' CSV")
  end

  def parse_and_update_csv
    @labels = CSV.open("#{Rails.configuration.datadir}/labels.csv", 'w+')
    @bug_labels = CSV.open("#{Rails.configuration.datadir}/bug_labels.csv", 'w+')
    label_id = 1

    CSV.foreach("#{Rails.configuration.datadir}/bugs/bug_sample.csv") do |line|
      bug_id = line[0]
      bug_issue = Bug.find_by(bug_id: bug_id)
      if bug_issue.nil?
        $stderr.puts "Bug issue #{bug_id} not found"
      else
        update_bug_issue line, bug_issue
        parse_labels label_id, line
      end
    end  
    @labels.fsync
    @bug_labels.fsync
    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY labels FROM '#{datadir}/labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY bug_labels FROM '#{datadir}/bug_labels.csv' DELIMITER ',' CSV")
  end                       

  def load_json(file)
    txt = ''
    File.open(file) do |f|
      txt = f.read
    end
    json = Oj.load(txt, {:symbol_keys => false, :mode => :compat})
    return json
  end

  def update_bug_issue(line, bug_issue)
    bug_issue.title = line[1]
    bug_issue.stars = line[6]
    bug_issue.status = line[7]
    bug_issue.reporter = line[8]
    bug_issue.opened = DateTime.strptime(line[10],'%s')
    bug_issue.closed = DateTime.strptime(line[12],'%s')
    bug_issue.modified = DateTime.strptime(line[14],'%s')
    bug_issue.save
  end

  def parse_labels(label_id, line)
    bug_id = line[0]
    labels = line[2].delete(' ').split(',')
    labels.each do |label|
      @labels << [label_id, label]
      @bug_labels << [label_id, bug_id]
      label_id += 1
    end
  end
  
  def open_csvs
   # @bug_comments = CSV.open("#{Rails.configuration.datadir}/bug_comments.csv", 'w+')
   # @bug_blocked = CSV.open("#{Rails.configuration.datadir}/bug_blocked.csv", 'w+')
  end

  def flush_csvs
   # @bug_comments.fsync
   # @bug_blocked.fsync
  end

  def copy_to_db
    #ActiveRecord::Base.connection.execute("COPY bugs FROM '#{datadir}/bug_comments.csv' DELIMITER ',' CSV")
    #ActiveRecord::Base.connection.execute("COPY bugs FROM '#{datadir}/bug_blokced.csv' DELIMITER ',' CSV")
  end
end#class
