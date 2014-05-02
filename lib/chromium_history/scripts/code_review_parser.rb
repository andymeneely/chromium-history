#!/usr/bin/env ruby
require 'csv'

class CodeReviewParser

  def parse
    @crs = CSV.open("/home/vagrant/chromium-history/code_reviews.csv", 'w+')
    @revs = CSV.open("/home/vagrant/chromium-history/reviewers.csv", 'w+')
    @ps = CSV.open("/home/vagrant/chromium-history/patch_sets.csv", 'w+')
    @msgs = CSV.open("/home/vagrant/chromium-history/messages.csv", 'w+')
    @psf = CSV.open("/home/vagrant/chromium-history/patch_set_files.csv", 'w+')
    @coms = CSV.open("/home/vagrant/chromium-history/comments.csv", 'w+')
    
    Dir["#{Rails.configuration.datadir}/codereviews/*.json"].each do |file|
      cobj = load_json file
      @crs << [cobj['description'], cobj['subject'], cobj['created'], cobj['modified'], cobj['issue'], cobj['owner_email']]
      cobj['reviewers'].each do |email|
        @revs << [cobj['issue'], email]
      end
      cobj['patchsets'].each do |pid|
        patchset_file = "#{file.gsub(/\.json$/,'')}/#{pid}.json" 
        if File.exists? patchset_file
          parse_patchsets(patchset_file, cobj['issue'])
        else
          $stderr.puts "Patchset file should exist but doesn't: #{patchset_file}"
        end
      end
      parse_messages(file, cobj['issue'], cobj['messages'])  
    end
  end
  
  def ordered_array(keyOrder, source)
    result = Array.new
    keyOrder.each do |key|
      result << source[key.to_s]
    end
    result
  end
  
  def load_json(file)
    Oj.load_file(file, {:symbol_keys => false, :mode => :compat})
  end
  
  @@PATCH_SET_PROPS = [:created, :num_comments, :message, :modified, :owner_email, :code_review_id, :patchset, :composite_patch_set_id]
  def parse_patchsets(patchset_file, code_review_id)
    pobj = load_json(patchset_file)
    pobj['composite_patch_set_id'] = "#{code_review_id}-#{pobj['patchset']}"
    pobj['codereview_id'] = code_review_id
    @ps << ordered_array(@@PATCH_SET_PROPS, patchset_file)
    parse_patch_set_files(pobj['composite_patch_set_id'], pobj['files'])
  end
  
  @@PATCH_SET_FILE_PROPS = [:filepath, :status, :num_chunks,:num_added, :num_removed, :is_binary, :composite_patch_set_id, :composite_patch_set_file_id]
  def parse_patch_set_files(composite_patch_set_id, psfiles)
    psfiles.each do |psfile|
      psf = psfile[1]
      psf['filepath'] = psfile[0].to_s
      psf['composite_patch_set_id'] = composite_patch_set_id
      psf['composite_patch_set_file_id'] = "#{composite_patch_set_id}-#{psf['filepath']}"
      @psf << ordered_array(@@PATCH_SET_FILE_PROPS, psf)
      parse_comments(psf['composite_patch_set_file_id'], psfile[1]['messages']) unless psfile[1]['messages'].nil? #Yes, Rietveld conflates "messages" with "comments" here
    end #patch set file loop
  end #load patch set file method
  
  #param patchset = the patchset file that the comments are on
  #      comments = the comments on a particular patch set file 
  @@COMMENT_PROPS = [:author_email,:text,:draft,:lineno,:date,:left ,:composite_patch_set_file_id]
  def parse_comments(composite_patch_set_file_id, comments)
    comments.each do |comment|
      comment['composite_patch_set_file_id'] = composite_patch_set_file_id
      @coms << ordered_array(@@COMMENT_PROPS, comment)
    end #comments loop
  end #load comments method
  
  #param file = the json file we're working with   DO WE EVEN NEED THIS HERE?
  #      codereview = code reivew model object
  #      msg = the messages sent out (about the review in general as opposed to a specific patch set)
  @@MESSAGE_PROPS = [:sender, :text, :approval, :disapproval, :date,:code_review_id]
  def parse_messages(file, code_review_id, msgs)
    msgs.each do |msg|
      msg['code_review_id'] = code_review_id
      @msgs << ordered_array(@@MESSAGE_PROPS, msg)
    end #message loop
  end #load messages method
end
