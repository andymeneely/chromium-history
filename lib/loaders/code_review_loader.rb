require 'set'
require 'csv'

class CodeReviewLoader

  def copy_parsed_tables 
    tmp = Rails.configuration.tmpdir
    [
      'code_reviews',
      'reviewers',
      'patch_sets', 
      'patch_set_files', 
      'messages', 
      'comments', 
      'developers', 
      'participants', 
      'contributors'
    ].each do |table|
      PsqlUtil.copy_from_file table, "#{tmp}/#{table}.csv"
    end
    ActiveRecord::Base.connection.execute("SELECT setval('developers_id_seq', (SELECT MAX(id) FROM developers)+1 )")
  end

  def add_primary_keys
    [
      'reviewers',
      'patch_sets', 
      'patch_set_files', 
      'messages', 
      'comments',  
      'participants', 
      'contributors'
    ].each do |table|
      PsqlUtil.add_auto_increment_key table
    end
    PsqlUtil.add_index 'code_reviews', 'issue', 'hash'   
  end

end #class
