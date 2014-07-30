class Label < ActiveRecord::Base
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :labels, :label_id
    ActiveRecord::Base.connection.add_index :labels, :label
  end
end
