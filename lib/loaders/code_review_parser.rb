# encoding: utf-8
require 'csv'

class CodeReviewParser

  def parse
    open_csvs #initalize our attributes for writing

    Dir["#{Rails.configuration.datadir}/codereviews/*.json"].each do |file|
      json = load_json file
      json.each do |cobj|
        owner_id = get_dev_id(cobj['owner_email'])

        @prtp_set  = Set.new
        @contrb_set = Set.new
        @revs_dict = Hash.new

        parse_reviewers(cobj, owner_id)

        cobj['patchsets'].each do |pid|
          if not cobj['patchset_data'][pid.to_s] == nil
            parse_patchsets(cobj['patchset_data'][pid.to_s], cobj['issue'])
          end
        end

        parse_messages(file, cobj['issue'], cobj['messages'])

        @non_participating_revs = (@revs_dict.keys.to_set) - (@prtp_set)
        
        @crs << [cobj['description'],
                 cobj['subject'], 
                 cobj['created'], 
                 cobj['modified'], 
                 cobj['issue'], 
                 cobj['owner_email'],
                 owner_id,
                 "", #empty commit hash for now
                 @non_participating_revs.size,
                 nil, # for total_reviews_with_owner
                 nil, # for owner_familiarity_gap
                 nil, # for total_sheriff_hours
                 nil] # for cursory

        @prtp_set.each {|p| @prtps << [p,owner_id,cobj['issue'],cobj['created'],nil,nil,nil,nil,nil,nil,nil,nil]}
        @contrb_set.each {|c| @contrbs << [c,cobj['issue']]}
        @revs_dict.each {|id, email| @revs << [cobj['issue'],id, email]}


      end # do |file|
    end #do |chunk|
    dump_developers #put our dev cache out to CSV
    flush_csvs #get everything out to the files

  end #method

  def open_csvs
    @dev_db = Hash.new
    @dev_incr = 0
    tmp = Rails.configuration.tmpdir
    @crs = CSV.open("#{tmp}/code_reviews.csv", 'w+')
    @revs = CSV.open("#{tmp}/reviewers.csv", 'w+')
    @ps = CSV.open("#{tmp}/patch_sets.csv", 'w+')
    @msgs = CSV.open("#{tmp}/messages.csv", 'w+')
    @psf = CSV.open("#{tmp}/patch_set_files.csv", 'w+')
    @coms = CSV.open("#{tmp}/comments.csv", 'w+')
    @devs = CSV.open("#{tmp}/developers.csv", 'w+')
    @prtps = CSV.open("#{tmp}/participants.csv", 'w+')
    @contrbs = CSV.open("#{tmp}/contributors.csv", 'w+')
  end

  def flush_csvs
    @crs.fsync
    @revs.fsync
    @ps.fsync
    @msgs.fsync
    @psf.fsync
    @coms.fsync
    @devs.fsync
    @prtps.fsync
    @contrbs.fsync
  end

  def ordered_array(keyOrder, source)
    result = Array.new
    keyOrder.each do |key|
      result << source[key.to_s]
    end
    result
  end

  def load_json(file)
    txt = ''
    File.open(file) do |f|
      txt = f.read
        .encode('UTF-16be', :invalid => :replace, :undef => :replace, :replace => '')
        .encode('UTF-8')
      txt.gsub! /\\u0000/,'' #delete strings that will be INTERPRETED as nulls
    end
    json = Oj.load(txt, {symbol_keys: false, mode: :compat})
    return json
  end

  # Hit our own Developer cache to figure out distinct developers
  # 
  # This is essentially our own implementation of the DB cache, only it's just 
  # developers so it's super small in memory. 
  #
  def get_dev_id(raw_email)
    email,valid = Developer.sanitize_validate_email raw_email  
    return -1 unless valid
    @dev_db[email] ||= (@dev_incr+=1) #set to increment if nil
  end


  def parse_reviewers(cobj, owner_id) 
                      cobj['reviewers'].each do |email|
    dev_id = get_dev_id(email)
    unless owner_id == dev_id #doesn't add owner as a reviewer
      unless dev_id == -1 
        clean_email, valid = Developer.sanitize_validate_email email
        @revs_dict[dev_id] = clean_email
      end
    end
  end
  end

  @@PATCH_SET_PROPS = [:created, :num_comments, :message, :modified, :owner_email, :owner_id, :code_review_id, :patchset, :composite_patch_set_id]
  def parse_patchsets(pobj, code_review_id)
    pobj['composite_patch_set_id'] = "#{code_review_id}-#{pobj['patchset']}"
    pobj['code_review_id'] = code_review_id
    pobj['owner_id'] = get_dev_id(pobj['owner_email'])
    @ps << ordered_array(@@PATCH_SET_PROPS, pobj)
    parse_patch_set_files(pobj['composite_patch_set_id'], pobj['files'], code_review_id)
  end

  @@PATCH_SET_FILE_PROPS = [:filepath, :status, :num_chunks,:num_added, :num_removed, :is_binary, :composite_patch_set_id, :composite_patch_set_file_id]
  def parse_patch_set_files(composite_patch_set_id, psfiles, code_review_id)
    psfiles.each do |psfile|
      psf = psfile[1]
      psf['filepath'] = psfile[0].to_s
      psf['composite_patch_set_id'] = composite_patch_set_id
      psf['composite_patch_set_file_id'] = "#{composite_patch_set_id}-#{psf['filepath']}"
      @psf << ordered_array(@@PATCH_SET_FILE_PROPS, psf)
      parse_comments(psf['composite_patch_set_file_id'], psfile[1]['messages'],code_review_id) unless psfile[1]['messages'].nil? #Yes, Rietveld conflates "messages" with "comments" here
    end #patch set file loop
  end #load patch set file method

  #param patchset = the patchset file that the comments are on
  #      comments = the comments on a particular patch set file 
  @@COMMENT_PROPS = [:author_email,:author_id,:text,:draft,:lineno,:date,:left ,:composite_patch_set_file_id]
  def parse_comments(composite_patch_set_file_id, comments,code_review_id)
    comments.each do |comment|
      comment['composite_patch_set_file_id'] = composite_patch_set_file_id
      comment['author_id'] = get_dev_id(comment["author_email"])
      @coms << ordered_array(@@COMMENT_PROPS, comment)
      @prtp_set << comment['author_id'] unless comment['author_id'] == -1
      if Contributor.contribution? comment['text']
        @contrb_set << comment['author_id'] unless comment['author_id'] == -1
      end
    end #comments loop
  end #load comments method

  #param file = the json file we're working with   DO WE EVEN NEED THIS HERE?
  #      codereview = code reivew model object
  #      msg = the messages sent out (about the review in general as opposed to a specific patch set)
  @@MESSAGE_PROPS = [:sender, :sender_id, :text, :approval, :disapproval, :date, :code_review_id]
  def parse_messages(file, code_review_id, msgs)
    msgs.each do |msg|
      msg['code_review_id'] = code_review_id
      msg['sender_id'] = get_dev_id(msg['sender'])
      @msgs << ordered_array(@@MESSAGE_PROPS, msg)
      @prtp_set << msg['sender_id'] unless msg['sender_id'] == -1
      if Contributor.contribution? msg['text']
        @contrb_set << msg['sender_id'] unless msg['sender_id'] == -1
      end
    end #message loop
  end #load messages method

  # Given our in-memory @dev_db cache, let's now just dump it to a csv
  def dump_developers
    @dev_db.each do |email,dev_id|
      positive_infinity = "2050/01/01 00:00:00"
      @devs << [dev_id, 
                email,
                positive_infinity,
                positive_infinity,
                positive_infinity,
                positive_infinity,
                positive_infinity,
                positive_infinity]
    end
  end

end#class
