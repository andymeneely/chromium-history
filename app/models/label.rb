class Label < ActiveRecord::Base
  has_many :bug_labels, primary_key: 'label_id', foreign_key: 'label_id'
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :labels, :label_id
    ActiveRecord::Base.connection.add_index :labels, :label
  end
end
