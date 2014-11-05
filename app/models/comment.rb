class Comment < ActiveRecord::Base
  belongs_to :patch_set_file
  
  def self.optimize
    connection.add_index :comments, :composite_patch_set_file_id
  end

  def self.get_convo issue
    Comment.select("author_id, text")
      .where('code_review_id = ?', issue)
      .order('code_review_id')
  end

  def self.get_all_convo result_file=nil, limit=nil
    query = "SELECT code_review_id, string_agg(text, E'\n') 
             FROM Comments 
             GROUP BY code_review_id 
             #{if limit then "LIMIT #{limit}" else "" end}"
    if result_file then query = "COPY(#{query}) TO '#{result_file}' WITH (FORMAT text)" end
    ActiveRecord::Base.connection.execute(query)
  end

  def self.get_developer_comments developer_id=nil, result_file=nil
    query = "SELECT author_id, string_agg(text, E'\n') 
             FROM Comments 
             #{if developer_id then "WHERE author_id = #{developer_id}" else "" end} 
             GROUP BY author_id"
    if result_file then query = "COPY(#{query}) TO '#{result_file}' WITH (FORMAT text)" end
    ActiveRecord::Base.connection.execute(query)
  end
end
