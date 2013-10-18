require 'oj'
require_relative 'data_transfer'

class CodeReviewLoader
  @@CODE_REVIEW_PROPS = [:description, :subject, :created, :modified, :issue]
  @@PATCH_SET_PROPS = [:message, :num_comments, :patchset, :created, :modified]

  # Mix in the DataTransfer module
  include DataTransfer
  
  def load
    Dir["#{Rails.configuration.datadir}/*.json"].each do |file|
      obj = Oj.load_file(file)
      CodeReview.transaction do
        c = transfer(CodeReview.create, obj, @@CODE_REVIEW_PROPS)
        obj['patchsets'].each do |pid| 
          pobj = Oj.load_file("#{file[0..-5]}/#{pid}.json")
          p = transfer(PatchSet.create, pobj, @@PATCH_SET_PROPS)
          #TODO Bring in comments relation
          c.patch_sets << p
        end
        #TODO Bring in messages relation
        #TODO Bring in connection to the Developer model for owner. Look it up first and then make the connection.
      end 
    end
    puts "Loading done."
  end
  
end