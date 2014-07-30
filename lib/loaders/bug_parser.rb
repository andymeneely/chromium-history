require 'csv'

class BugParser
  
  def parse_and_load_json
    
    @bug_entries = CSV.open("#{Rails.configuration.datadir}/bug_entries.csv", 'w+')
    @bug_comments = CSV.open("#{Rails.configuration.datadir}/bug_comments.csv", 'w+')
    
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
        
        entry["replies"].each do |comment|
          @bug_comments << [entry["issues$id"]["$t"],
                            comment["content"],
                            comment["author"]["name"]["$t"],
                            comment["author"]["uri"]["$t"],
                            comment["updated"]["$t"]]
        end
      end
    end
    @bug_entries.fsync
    @bug_comments.fsync

    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY bugs FROM '#{datadir}/bug_entries.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY bug_comments FROM '#{datadir}/bug_comments.csv' DELIMITER ',' CSV")
  end

  def parse_and_update_csv
    open_csvs
    @labels = CSV.open("#{Rails.configuration.datadir}/labels.csv", 'w+')
    @bug_labels = CSV.open("#{Rails.configuration.datadir}/bug_labels.csv", 'w+')

    CSV.foreach("#{Rails.configuration.datadir}/bugs/*.csv") do |line|
      bug_id = line[0]
      bug_issue = Bug.find_by(bug_id: bug_id)
      if bug_issue.nil?
        $stderr.puts "Bug issue #{bug_id} not found"
      else
        update_bug_issue line, bug_issue
        parse_labels line
        parse_blocked line
      end
    end
    dump_labels
    @labels.fsync
    @bug_labels.fsync
    @bug_blocked.fsync
    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY labels FROM '#{datadir}/labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY bug_labels FROM '#{datadir}/bug_labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY blocks FROM '#{datadir}/bug_blocked.csv' DELIMITER ',' CSV")
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

  def parse_labels(line)
    bug_id = line[0]
    labels = line[2].delete(' ').split(',')
    labels.each do |label|
      @label_db[label] ||= (@label_incr+=1) #set to increment if nil
      @bug_labels << [@label_db[label], bug_id]
    end
  end

  def parse_blocked(line)
    blocked_on = line[4]
    blocking = line[5]
    if blocked_on.nil? and blocking.nil?
    else
      if not blocked_on.nil? and blocking.nil?
        blocking = []
        blocked_on.split(",").zip(blocking).each do |blocked, blocking|
          @bug_blocked << [blocked, blocking]
        end
      elsif not blocking.nil? and blocked_on.nil?
        blocked_on = []
        blocking.split(",").zip(blocked_on).each do |blocking, blocked|
          @bug_blocked << [blocked, blocking]
        end
      else
        blocked_on.split(",").zip(blocking.split(",")).each do |blocked, blocking|
          @bug_blocked << [blocked, blocking]
        end
      end
    end
  end

  def open_csvs
    @label_db = Hash.new
    @label_incr = 0
    @bug_blocked = CSV.open("#{Rails.configuration.datadir}/bug_blocked.csv", 'w+')
  end

  def dump_labels
    @label_db.each do |label,label_id|
      @labels << [label_id, label]
    end
  end
end#class
