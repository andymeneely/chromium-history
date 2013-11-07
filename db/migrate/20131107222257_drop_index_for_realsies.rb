class DropIndexForRealsies < ActiveRecord::Migration
  def change
    remove_index :code_reviews, :issue
  end
end
