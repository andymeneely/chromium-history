class Developer < ActiveRecord::Base
  has_many :code_reviews
  belongs_to :reviewer
  belongs_to :cc

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :developers, :email, unique: true
    ActiveRecord::Base.connection.add_index :developers, :name
  end

end
