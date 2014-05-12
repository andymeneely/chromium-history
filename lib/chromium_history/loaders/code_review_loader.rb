require 'oj'
require_relative 'data_transfer'
require_relative 'git_log_loader'
require 'set'
require 'csv'

class CodeReviewLoader

  @@BULK_IMPORT_BLOCK_SIZE = 10000
  
  def load_batch(batch)
    @developer_to_save = Hash.new
    @reviewer_to_save = []
    
    start = batch.to_i * @@BULK_IMPORT_BLOCK_SIZE
    list = CodeReview.where(:id => start..(start+@@BULK_IMPORT_BLOCK_SIZE))
    
    list.each do |cobj|
      revList = Reviewer.where(:issue => cobj.issue)
      load_developers(revList, nil, cobj.issue)
      load_developer_names(cobj.owner_email, nil)
    end #each json file loop

    Developer.import @developer_to_save.values
    Reviewer.import @reviewer_to_save

  end #load method




  #private  

  #param reviewers = list of emails sent to the reviewers
  #      messages = list of messages on the code review
  def load_developers(reviewers, messages, issueNumber)
		distinct_reviewers = Set.new
    reviewers.each do |rev|
			email, valid = Developer.sanitize_validate_email rev.email
			next if not valid 
			next if distinct_reviewers.add?(email).nil?
			
      if not @developer_to_save.include?(email)
        dev, found = Developer.search_or_add(email)
        if not found
          @developer_to_save[email] = dev
        end
      else
        dev = @developer_to_save[email]
      end
      
      rev.dev_id = dev.id
      bulk_save Reviewer,rev, @reviewer_to_save
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
    email, valid = Developer.sanitize_validate_email email
    
    if not valid
      return
    end
    
    if not @developer_to_save.include?(email)
      dev, found = 
      Developer.search_or_add(email)
      if not found
        @developer_to_save[email] 
      end
    end

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
