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
        c.save
      end
    end
  end
  
  private  
  
  @@PATCH_SET_PROPS = [:message, :num_comments, :patchset, :created, :modified]
  def load_patchsets(file, codereview, pids)
    pids.each do |pid| 
      pobj = Oj.load_file("#{file[0..-5]}/#{pid}.json")
      p = transfer(PatchSet.new, pobj, @@PATCH_SET_PROPS)
      load_patch_set_files(p, pobj['files'])
      codereview.patch_sets << p
      p.save
    end
  end
  
  @@PATCH_SET_FILE_PROPS = [:status,:num_chunks,:no_base_file,:property_changes,:num_added,:num_removed,:is_binary]
  def load_patch_set_files(patchset, psfiles)
    psfiles.each do |psfile|
      psf = transfer(PatchSetFile.new(:filepath => psfile[0].to_s), psfile[1], @@PATCH_SET_FILE_PROPS)
      load_comments(psf, psfile[1]['messages']) unless psfile[1]['messages'].nil? #Yes, Rietveld conflates "messages" with "comments" here
      patchset.files << psf
      psf.save
    end
  end
  
  @@COMMENT_PROPS = [:author_email,:text,:draft,:lineno,:date,:left]
  def load_comments(patchset_file, comments)
    comments.each do |comment|
      c = transfer(Comment.new, comment, @@COMMENT_PROPS)
      patchset_file.comments << c
      c.save
    end
  end
  
  @@MESSAGE_PROPS = [:sender, :text, :disapproval, :date, :approval]
  def load_messages(file, codereview, msgs)
    msgs.each do |msg|
      m = transfer(Message.new, msg, @@MESSAGE_PROPS)
      codereview.messages << m
      m.save
    end
  end
end