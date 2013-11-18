require 'oj'
require_relative 'data_transfer'

class CodeReviewLoader
  # Mix in the DataTransfer module
  include DataTransfer
  
  
  @@CODE_REVIEW_PROPS = [:description, :subject, :created, :modified, :issue]
  def load    
    Dir["#{Rails.configuration.datadir}/codereviews/*.json"].each do |file|
      cobj = Oj.load_file(file)
      CodeReview.transaction do
        c = transfer(CodeReview.new, cobj, @@CODE_REVIEW_PROPS)
        #TODO Bring in connection to the Developer model for owner, cc's, reviewers, and various others.
        #TODO For the Developer connections, ideally look it up first and then make the connection. Maybe check if it's there by email first, then add one if it's not there.
        load_patchsets(file, c, cobj['patchsets'])
        load_messages(file, c, cobj['messages'])
        load_developers(cobj['cc'], cobj['reviewers'], cobj['messages'])
        c.save

        load_developer_names(cobj['owner_email'], cobj['owner'])
      end #code review transaction loop
    end #each json file loop
  end #load method
  



  private  
  
  #param file = the json file we're working with
  #      codereview = code reivew model object
  #      pids = all the patch sets
  @@PATCH_SET_PROPS = [:message, :num_comments, :patchset, :created, :modified, :owner_email]
  def load_patchsets(file, codereview, pids)
    pids.each do |pid|
      pobj = Oj.load_file("#{file.gsub(/\.json$/,'')}/#{pid}.json")
      p = transfer(PatchSet.new, pobj, @@PATCH_SET_PROPS)

      #this new method will load in the owner name and email to the developers table from this patch set
      load_developer_names(pobj['owner_email'], pobj['owner'])

      load_patch_set_files(p, pobj['files'])
      codereview.patch_sets << p
      p.save
    end #patch set loop
  end #load patch set method
  



  #param patchset = patchset model object
  #      psfiles = the files within each patchset
  @@PATCH_SET_FILE_PROPS = [:status,:num_chunks,:no_base_file,:property_changes,:num_added,:num_removed,:is_binary]
  def load_patch_set_files(patchset, psfiles)
    psfiles.each do |psfile|
      psf = transfer(PatchSetFile.new(:filepath => psfile[0].to_s), psfile[1], @@PATCH_SET_FILE_PROPS)
      load_comments(psf, psfile[1]['messages']) unless psfile[1]['messages'].nil? #Yes, Rietveld conflates "messages" with "comments" here
      patchset.files << psf
      psf.save
    end #patch set file loop
  end #load patch set file method
  



  #param patchset = the patchset file that the comments are on
  #      comments = the comments on a particular patch set file 
  @@COMMENT_PROPS = [:author_email,:text,:draft,:lineno,:date,:left]
  def load_comments(patchset_file, comments)
    comments.each do |comment|
      c = transfer(Comment.new, comment, @@COMMENT_PROPS)
      patchset_file.comments << c
      c.save
    end #comments loop
  end #load comments method
  



  #param file = the json file we're working with   DO WE EVEN NEED THIS HERE?
  #      codereview = code reivew model object
  #      msg = the messages sent out (about the review in general as opposed to a specific patch set)
  @@MESSAGE_PROPS = [:sender, :text, :disapproval, :date, :approval]
  def load_messages(file, codereview, msgs)
    msgs.each do |msg|
      m = transfer(Message.new, msg, @@MESSAGE_PROPS)
      codereview.messages << m
      m.save
    end #message loop
  end #load messages method




  #param cc = list of emails CCed on the code review
  #      reviewers = list of emails sent to the reviewers
  #      messages = list of messages on the code review
  def load_developers(cc, reviewers, messages)
    cc.each do |email|
      #get rid of the plus sign and after
      if (email.index('+') != nil) 
        email = email.slice(0, email.index('+')) + email.slice(email.index('@'), (email.length()-1))
      end #fixing the email
      if (Developer.find_by_email(email) == nil) 
        developer = Developer.new
        developer["email"] = email
        developer.save
      end #checking if the email exists
    end #cc loop

    reviewers.each do |email|
      #get rid of the plus sign and after
      if (email.index('+') != nil) 
        email = email.slice(0, email.index('+')) + email.slice(email.index('@'), (email.length()-1))
      end #fixing the email
      if (Developer.find_by_email(email) == nil) 
        developer = Developer.new
        developer["email"] = email
        developer.save
      end #checking if the email exists
    end #reviewers loop

    #possibly this message part should go in the load_messages method????
    messages.each do |message|
      message["recipients"].each do |email|  #the sender is always included in the recipients so theres no need to do that seperately
        #get rid of the plus sign and after
        if (email.index('+') != nil) 
          email = email.slice(0, email.index('+')) + email.slice(email.index('@'), (email.length()-1))
        end #fixing the email
        if (Developer.find_by_email(email) == nil) 
          developer = Developer.new
          developer["email"] = email
          developer.save
        end #checking if the email exists
      end #emails in the messages loop
    end #messages loop
  end #load developers method




  #param email = email of a developer
  #      name = name of the same developer
  def load_developer_names(email, name)
    if (email.index('+') != nil) 
      email = email.slice(0, email.index('+')) + email.slice(email.index('@'), (email.length()-1))
    end #fixing the email
  
    if (Developer.find_by_email(email) == nil) 
      developer = Developer.new
      developer["email"] = email
      developer["name"] = name
      developer.save
    else 
      dobj = Developer.find_by_email(email)
      if (Developer.find_by_name(name) == nil) 
        dobj["name"] = name #if there is already an owner there and they dont match, that a problem
      end #checking if the name exists
    end #checking if the email exists
  end #load developer names method

end
