class BugComment < ActiveRecord::Base
  belongs_to  :bug
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :bug_comments, :bug_id
    ActiveRecord::Base.connection.add_index :bug_comments, :author_email
    ActiveRecord::Base.connection.add_index :bug_comments, :author_uri
    ActiveRecord::Base.connection.add_index :bug_comments, :updated
  end
 
end
