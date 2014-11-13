# Note: this model represents a message, not a comment. Messages are associated with code reviews, comments are associated with patchset (which are associated with code reviews)
class Message < ActiveRecord::Base
  belongs_to :code_review
  
  def self.optimize
    connection.add_index :messages, :sender
    connection.add_index :messages, :code_review_id
  end

  def self.get_message issue
    Message.select("sender_id, text")
      .where('code_review_id = ?', issue)
      .order('code_review_id')
  end

  def self.get_all_messages result_file=nil, limit=nil
    query = "SELECT code_review_id, string_agg(text, E'\n') 
             FROM messages 
             GROUP BY code_review_id 
             #{if limit then "LIMIT #{limit}" else "" end}"
    if result_file then query = "COPY(SELECT sub.string_agg FROM (#{query}) as sub) TO '#{result_file}' WITH (FORMAT text)" end
    ActiveRecord::Base.connection.execute(query)
  end

  def self.get_developer_messages developer_id=nil, result_file=nil
    query = "SELECT sender_id, string_agg(text, E'\n') 
             FROM messages 
             #{if developer_id then "WHERE sender_id = #{developer_id}" else "" end} 
             GROUP BY sender_id"
    if result_file then query = "COPY(SELECT sub.string_agg FROM (#{query}) as sub) TO '#{result_file}' WITH (FORMAT text)" end
    ActiveRecord::Base.connection.execute(query)
  end
end
