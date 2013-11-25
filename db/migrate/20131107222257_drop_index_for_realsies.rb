class DropIndexForRealsies < ActiveRecord::Migration
  def change
    remove_index :code_reviews,:issue if index_exists? :code_reviews,:issue
  end
end
