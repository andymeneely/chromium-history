class DiediedieIndex < ActiveRecord::Migration
  def up
    remove_index :code_reviews,:issue if index_exists? :code_reviews,:issue
  end

  def down
    add_index :code_reviews, :issue
  end
end
