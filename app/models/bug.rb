class Bug < ActiveRecord::Base
  has_many :bug_labels, primary_key: 'bug_id', foreign_key: 'bug_id'
  has_many :labels, through: :bug_labels

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
     
