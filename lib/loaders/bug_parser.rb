require 'csv'

class BugParser
  
  def parse_and_load_json

    # initalize our attributes up for writing
    @bug_entries = CSV.open("#{Rails.configuration.datadir}/tmp/bug_entries.csv", 'w+')
    @bug_comments = CSV.open("#{Rails.configuration.datadir}/tmp/bug_comments.csv", 'w+')
    
    # get all json files and iterate over entries and entry's replies
    # and add the data from the json to attributes
    Dir["#{Rails.configuration.datadir}/bugs/json/*.json"].each do |file|
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
                            comment["content"]["$t"],
                            comment["author"][0]["name"]["$t"],
                            comment["author"][0]["uri"]["$t"],
                            comment["updated"]["$t"]]
        end
      end
    end

    # get everything out to the files  and bulk load to the tables
    @bug_entries.fsync
    @bug_comments.fsync

    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY bugs FROM '#{datadir}/tmp/bug_entries.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY bug_comments FROM '#{datadir}/tmp/bug_comments.csv' DELIMITER ',' CSV")
  end

  def parse_and_load_csv
    
    # initalize our attributes up for writing
    @label_db = Hash.new
    @label_incr = 0
    @bug_blocked = CSV.open("#{Rails.configuration.datadir}/tmp/bug_blocked.csv", 'w+')
    @labels = CSV.open("#{Rails.configuration.datadir}/tmp/labels.csv", 'w+')
    @bug_labels = CSV.open("#{Rails.configuration.datadir}/tmp/bug_labels.csv", 'w+')

    # get all csv files and load data 
    Dir["#{Rails.configuration.datadir}/bugs/csv/*.csv"].each do |file|
      CSV.foreach(file,{:headers=>:first_row}) do |line|
        unless line[0].starts_with?("This")
          bug_id = line[0]
          bug_issue = Bug.find_by(bug_id: bug_id) # match the json issue num with the csv issue num 
       
          if bug_issue.nil?
           $stderr.puts "Bug issue #{bug_id} not found" 
          else
           update_bug_issue line, bug_issue # update nil fields in the bugs table
           parse_labels line  
           parse_blocked line
          end
        end
      end
    end

    # get everything out to the files  and bulk load to the tables
    dump_labels
    @labels.fsync
    @bug_labels.fsync
    @bug_blocked.fsync

    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY labels FROM '#{datadir}/tmp/labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY bug_labels FROM '#{datadir}/tmp/bug_labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY blocks FROM '#{datadir}/tmp/bug_blocked.csv' DELIMITER ',' CSV")
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
    if blocked_on.nil? and blocking.nil? #both blocked_on and blocking are empty
    else
      if not blocked_on.nil? and blocking.nil? # if only blocking is empty
        blocking = []
        blocked_on.split(",").zip(blocking).each do |blocked, blocking|
          @bug_blocked << [blocked, blocking]
        end
      elsif not blocking.nil? and blocked_on.nil? # if only blocked is empty
        blocked_on = []
        blocking.split(",").zip(blocked_on).each do |blocking, blocked|
          @bug_blocked << [blocked, blocking]
        end
      else # if blocked and blocking both have data
        blocked_on.split(",").zip(blocking.split(",")).each do |blocked, blocking|
          @bug_blocked << [blocked, blocking]
        end
      end
    end
  end

  def dump_labels
    @label_db.each do |label,label_id|
      @labels << [label_id, label]
    end
  end
end#class
