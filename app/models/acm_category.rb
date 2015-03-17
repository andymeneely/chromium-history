class AcmCategory < ActiveRecord::Base
  

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :name
  end
end