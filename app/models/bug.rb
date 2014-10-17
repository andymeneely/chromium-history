class Bug < ActiveRecord::Base
  has_many :bug_labels, primary_key: 'bug_id', foreign_key:'bug_id'
  has_many :labels, through: :bug_labels
  
  has_many :blocks, primary_key: 'bug_id', foreign_key: 'bug_id'
  has_many :blocking, :through => :blocks

  has_many :commit_bugs, primary_key: 'bug_id', foreign_key:'bug_id'
  
  has_many :blocked, primary_key: 'bug_id', foreign_key: 'blocking_id',:class_name => "Block"
  has_many :blocked_by, :through => :blocked
  
  has_many :bug_comments, foreign_key: "bug_id", primary_key: "bug_id"
  
  self.primary_key = :bug_id

  def self.optimize
    connection.add_index :bugs, :bug_id
    connection.add_index :bugs, :title
    connection.add_index :bugs, :stars
    connection.add_index :bugs, :status
    connection.add_index :bugs, :reporter
    connection.add_index :bugs, :opened
    connection.add_index :bugs, :closed
    connection.add_index :bugs, :modified
    connection.add_index :bugs, :owner_email
    connection.add_index :bugs, :owner_uri
    connection.execute "CLUSTER bugs USING index_bugs_on_opened"
  end

  def is_real_bug?
    real_bug_labels = ['Type-Bug','Type-Bug-Regression']
    bug_labels = self.labels.pluck(:label)

    return (bug_labels & real_bug_labels).present?
  end
end
