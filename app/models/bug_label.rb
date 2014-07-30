class BugLabel < ActiveRecord::Base
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :bug_labels, :label_id
    ActiveRecord::Base.connection.add_index :bug_labels, :bug_id
  end

end
