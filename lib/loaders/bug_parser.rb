# encoding: utf-8
require 'csv'

class BugParser
  
  def parse_and_load_json

    # initalize our attributes up for writing
    tmp = Rails.configuration.tmpdir
    @bug_entries = CSV.open("#{tmp}/bug_entries.csv", 'w+')
    @bug_comments = CSV.open("#{tmp}/bug_comments.csv", 'w+')
    
    # get all json files and iterate over entries and entry's replies
    # and add the data from the json to attributes
    Dir["#{Rails.configuration.datadir}/bugs/json/*.json"].each do |file|
      bug_obj = load_json file
      bug_obj = bug_obj["feed"]["entry"] if bug_obj.include? "feed" #remove feed  envelope.
      bug_obj.each do |entry|
   
        unless entry["issues$owner"].nil?
          owner_name = entry["issues$owner"]["issues$username"]["$t"]
          owner_uri = entry["issues$owner"]["issues$uri"]["$t"]
        else 
          owner_name = nil
          ownder_url = nil
        end

        content = entry["content"].nil? ? '' : entry["content"]["$t"]

        @bug_entries << [entry["issues$id"]["$t"],
                         nil, #title
                         nil, #stars
                         nil, #status
                         nil, #reporter
                         nil, #opened
                         nil, #closed
                         nil, #modified
                         owner_name,
                         owner_uri,
                         content]
        
        unless entry["replies"].nil?
          entry["replies"].each do |comment|
            @bug_comments << [entry["issues$id"]["$t"],
                              comment["content"]["$t"],
                              comment["author"][0]["name"]["$t"],
                              comment["author"][0]["uri"]["$t"],
                              comment["updated"]["$t"]]
          end
        end
      end
    end

    # get everything out to the files  and bulk load to the tables
    @bug_entries.fsync
    @bug_comments.fsync

    begin 
      ActiveRecord::Base.connection.execute("COPY bugs FROM '#{tmp}/bug_entries.csv' DELIMITER ',' CSV ENCODING 'utf-8'")
    rescue Exception => e
      $stderr.puts "COPY bug_entries failed"
      $stderr.puts e.message
      $stderr.puts e.backtrace.inspect
    end

    begin
      ActiveRecord::Base.connection.execute("COPY bug_comments FROM '#{tmp}/bug_comments.csv' DELIMITER ',' CSV ENCODING 'utf-8'")
    rescue Exception => e
      $stderr.puts "COPY bug_comments failed"
      $stderr.puts e.message
      $stderr.puts e.backtrace.inspect
    end
  end

  def parse_and_load_csv
    
    # initalize our attributes up for writing
    tmp = Rails.configuration.tmpdir
    @label_db = Hash.new
    @label_incr = 0
    @bug_blocked = CSV.open("#{tmp}/bug_blocked.csv", 'w+')
    @labels = CSV.open("#{tmp}/labels.csv", 'w+')
    @bug_labels = CSV.open("#{tmp}/bug_labels.csv", 'w+')

    # get all csv files and load data 
    Dir["#{Rails.configuration.datadir}/bugs/csv/*.csv"].each do |file|
      CSV.foreach(file,{:headers=>:first_row}) do |line|
        puts "line[0] is nil at #{file}" if line[0].nil?
        unless line[0].nil? || line[0].starts_with?("This")
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

    ActiveRecord::Base.connection.execute("COPY labels FROM '#{tmp}/labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY bug_labels FROM '#{tmp}/bug_labels.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY blocks FROM '#{tmp}/bug_blocked.csv' DELIMITER ',' CSV")
  end                       

  def load_json(file)
    begin 
      txt = ''
      File.open(file) do |f|
        txt = f.read
          .encode('UTF-16be', :invalid => :replace, :undef => :replace, :replace => '')
          .encode('UTF-8')
        #txt.gsub! /\\u0000/,'' #delete strings that will be INTERPRETED as nulls
      end
      json = Oj.load(txt, {:symbol_keys => false, :mode => :compat})
    rescue Exception => e
      $stderr.puts "COPY parse bugs failed on file #{file}"
      $stderr.puts e.message
    end
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
      label.downcase!
      @label_db[label] ||= (@label_incr+=1) #set to increment if nil
      @bug_labels << [@label_db[label], bug_id]
    end
  end

  def parse_blocked(line)
    bug_id = line[0].to_i
    blocked_on = line[4]
    blocking = line[5]
    
    unless blocking.nil? || bug_id == 0
      blocking.split(",").each do |b|
          @bug_blocked << [bug_id,b] unless b.to_i == 0
      end
    end    
  end

  def dump_labels
    @label_db.each do |label,label_id|
      @labels << [label_id, label]
    end
  end

end#class
