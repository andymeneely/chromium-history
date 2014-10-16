class BugLabel < ActiveRecord::Base
  belongs_to :bug, primary_key: 'bug_id', foreign_key: 'bug_id'
  belongs_to :label, primary_key: 'label_id', foreign_key: 'label_id'
  
  def self.optimize
    connection.add_index :bug_labels, :label_id
    connection.add_index :bug_labels, :bug_id
    connection.add_index :bug_labels, [:bug_id,:label_id], unique: true
    connection.execute 'CLUSTER bug_labels USING index_bug_labels_on_bug_id_and_label_id'
  end

end
