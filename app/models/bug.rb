class Bug < ActiveRecord::Base
  has_many :bug_labels, primary_key: 'bug_id', foreign_key:'bug_id'
  has_many :labels, through: :bug_labels
  
  has_many :blocks, primary_key: 'bug_id', foreign_key: 'bug_id'
  has_many :blocking, :through => :blocks

  
  has_many :blocked, primary_key: 'bug_id', foreign_key: 'blocking_id',:class_name => "Block"
  has_many :blocked_by, :through => :blocked
  
  has_many :bug_comments, foreign_key: "bug_id", primary_key: "bug_id"

  self.primary_key = :bug_id

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :bugs, :bug_id
    ActiveRecord::Base.connection.add_index :bugs, :title
    ActiveRecord::Base.connection.add_index :bugs, :stars
    ActiveRecord::Base.connection.add_index :bugs, :status
    ActiveRecord::Base.connection.add_index :bugs, :reporter
    ActiveRecord::Base.connection.add_index :bugs, :opened
    ActiveRecord::Base.connection.add_index :bugs, :closed
    ActiveRecord::Base.connection.add_index :bugs, :modified
    ActiveRecord::Base.connection.add_index :bugs, :owner_email
    ActiveRecord::Base.connection.add_index :bugs, :owner_uri
    ActiveRecord::Base.connection.add_index :bugs, :content
  end
end
