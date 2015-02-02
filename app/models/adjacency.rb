class Adjacency < ActiveRecord:Base
  has_and_belongs_to_many :participants, primary_key: "dev_id", foreign_key: "adjacency_id"

  def self.optimize
    connection.add_index :participants, :dev_id
    connection.add_index :participants, :adjacency_id
  end
end