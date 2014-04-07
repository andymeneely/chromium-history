require 'oj'
require_relative 'data_transfer'
require_relative 'git_log_loader'


class CodeReviewLoader
  # Mix in the DataTransfer module
  include DataTransfer

  @@BULK_IMPORT_BLOCK_SIZE = 10000

  @@CODE_REVIEW_PROPS = [:description, :subject, :created, :modified, :issue]
  def load
    @codereviews_to_save = []
    @patchsets_to_save = []
    @patchset_files_to_save = []
    @comments_to_save = []
    @messages_to_save = []
    @cc_to_save = []
    @reviewer_to_save = []


    Dir["#{Rails.configuration.datadir}/codereviews/*.json"].each do |file|
      cobj = Oj.load_file(file)
      c = transfer(CodeReview.new, cobj, @@CODE_REVIEW_PROPS)
      bulk_save CodeReview,c, @codereviews_to_save
      load_patchsets(file, c.issue, cobj['patchsets'])
      load_messages(file, c.issue, cobj['messages'])
      load_developers(cobj['cc'], cobj['reviewers'], cobj['messages'], cobj['issue'])
      load_developer_names(cobj['owner_email'], cobj['owner'])
    end #each json file loop

    CodeReview.import @codereviews_to_save
    PatchSet.import @patchsets_to_save
    PatchSetFile.import @patchset_files_to_save
    Comment.import @comments_to_save
    Message.import @messages_to_save
    Cc.import @cc_to_save
    Reviewer.import @reviewer_to_save

  end #load method




  private  



  #param file = the json file we're working with
  #      codereview = code reivew model object
  #      pids = all the patch sets
  @@PATCH_SET_PROPS = [:message, :num_comments, :patchset, :created, :modified, :owner_email]
  def load_patchsets(file, code_review_id, pids)
    pids.each do |pid|
      patchset_file = "#{file.gsub(/\.json$/,'')}/#{pid}.json"
      if File.exists? patchset_file
        pobj = Oj.load_file(patchset_file)
        p = transfer(PatchSet.new, pobj, @@PATCH_SET_PROPS)
        p.composite_patch_set_id = "#{code_review_id}-#{p.patchset}"
        p.code_review_id = code_review_id
        bulk_save PatchSet,p, @patchsets_to_save
        #this new method will load in the owner name and email to the developers table from this patch set
        load_developer_names(pobj['owner_email'], pobj['owner'])
        load_patch_set_files(p.composite_patch_set_id, pobj['files'])
      else
        $stderr.puts "Patchset file should exist but doesn't: #{patchset_file}"
      end
    end #patch set loop
  end #load patch set method




  #param patchset = patchset model object
  #      psfiles = the files within each patchset
  @@PATCH_SET_FILE_PROPS = [:status,:num_chunks,:num_added,:num_removed,:is_binary]
  def load_patch_set_files(composite_patch_set_id, psfiles)
    psfiles.each do |psfile|
      psf = transfer(PatchSetFile.new, psfile[1], @@PATCH_SET_FILE_PROPS)
      psf.filepath = psfile[0].to_s
      psf.composite_patch_set_id = composite_patch_set_id
      psf.composite_patch_set_file_id = "#{composite_patch_set_id}-#{psf.filepath}"
      bulk_save PatchSetFile,psf, @patchset_files_to_save
      load_comments(psf.composite_patch_set_file_id, psfile[1]['messages']) unless psfile[1]['messages'].nil? #Yes, Rietveld conflates "messages" with "comments" here
    end #patch set file loop
  end #load patch set file method

  #param patchset = the patchset file that the comments are on
  #      comments = the comments on a particular patch set file 
  @@COMMENT_PROPS = [:author_email,:text,:draft,:lineno,:date,:left]
  def load_comments(composite_patch_set_file_id, comments)
    comments.each do |comment|
      c = transfer(Comment.new, comment, @@COMMENT_PROPS)
      c.composite_patch_set_file_id = composite_patch_set_file_id
      bulk_save Comment,c, @comments_to_save
    end #comments loop
  end #load comments method




  #param file = the json file we're working with   DO WE EVEN NEED THIS HERE?
  #      codereview = code reivew model object
  #      msg = the messages sent out (about the review in general as opposed to a specific patch set)
  @@MESSAGE_PROPS = [:sender, :text, :disapproval, :date, :approval]
  def load_messages(file, code_review_id, msgs)
    msgs.each do |msg|
      m = transfer(Message.new, msg, @@MESSAGE_PROPS)
      m.code_review_id = code_review_id
      bulk_save Message,m, @messages_to_save
    end #message loop
  end #load messages method




  #param cc = list of emails CCed on the code review
  #      reviewers = list of emails sent to the reviewers
  #      messages = list of messages on the code review
  def load_developers(cc, reviewers, messages, issueNumber)
    cc.each do |email|
      dev = Developer.search_or_add(email)
      ccTable = Cc.new  #creates a new CC table object
      ccTable["email"] = dev.email
      ccTable["issue"] = issueNumber #and the issue to which they were CCed
      bulk_save Cc,ccTable,@cc_to_save
    end #cc loop

    reviewers.each do |email|
      dev= Developer.search_or_add(email)
      reviewerTable = Reviewer.new  #creates a new Reviewer table object
      reviewerTable["email"] = dev.email #adds the developer getting reviewed
      reviewerTable["issue"] = issueNumber #and the issue to which they were reviewed
      bulk_save Reviewer,reviewerTable, @reviewer_to_save
    end #reviewers loop

    #possibly this message part should go in the load_messages method????
    # For some reason this code was slowing down the build - disabling for now to see how it goes tonight. -Andy
    #messages.each do |message|
    #  message["recipients"].each do |email|  
    #   Developer.search_or_add(email)
    #  end #emails in the messages loop
    #  Developer.search_or_add(message["sender"])  # putting the sender in
    #end #messages loop
  end #load developers method




  #param email = email of a developer
  #      name = name of the same developer
  def load_developer_names(email, name)
    Developer.search_or_add(email, name);
  end #load developer names method



  # Queue a model to be saved.
  # @param model_class = 
  # @param model - the model to be saved
  # @param to_save - the @model_to_save (e.g. @codereviews_to_save)
  def bulk_save(model_class, model, to_save)
    to_save << model
    if to_save.size >= @@BULK_IMPORT_BLOCK_SIZE
      model_class.import to_save
      to_save.clear
    end
  end

end
