class BugLabel < ActiveRecord::Base
  belongs_to :bug, primary_key: 'bug_id', foreign_key: 'bug_id'
  belongs_to :label, primary_key: 'label_id', foreign_key: 'label_id'
  
  def self.optimize
    connection.add_index :bug_labels, :label_id
    connection.add_index :bug_labels, :bug_id
  end

end
