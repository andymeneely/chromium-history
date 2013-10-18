require 'oj'
require_relative 'data_transfer'

class CodeReviewLoader
  # Mix in the DataTransfer module
  include DataTransfer
  
  @@CODE_REVIEW_PROPS = [:description, :subject, :created, :modified, :issue]
  def load
    Dir["#{Rails.configuration.datadir}/*.json"].each do |file|
      cobj = Oj.load_file(file)
      CodeReview.transaction do
        c = transfer(CodeReview.create, cobj, @@CODE_REVIEW_PROPS)
        load_patchsets(file, c, cobj['patchsets'])
        load_messages(file, c, cobj['messages'])
        #TODO Bring in messages relation
        #TODO Bring in connection to the Developer model for owner, cc's, reviewers, and various others.
        #TODO For the Developer connections, ideally look it up first and then make the connection. Maybe check if it's there by email first, then add one if it's not there.
      end 
    end
    puts "Loading done."
  end
  
  private  
  
  @@PATCH_SET_PROPS = [:message, :num_comments, :patchset, :created, :modified]
  def load_patchsets(file, codereview, pids)
    pids.each do |pid| 
      pobj = Oj.load_file("#{file[0..-5]}/#{pid}.json")
      p = transfer(PatchSet.create, pobj, @@PATCH_SET_PROPS)
      #TODO Bring in comments relation here
      codereview.patch_sets << p
    end
  end
  
  @@MESSAGE_PROPS = [:sender, :text, :disapproval, :date, :approval]
  def load_messages(file, codereview, msgs)
    msgs.each do |msg|
      codereview.messages << transfer(Message.create, msg, @@MESSAGE_PROPS)
    end
  end
end