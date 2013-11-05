class CreateCommits < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.string :commit_hash
      t.string :parent_commit_hash
      t.string :author_email
      t.string :author_name
      t.string :committer_email
      t.string :committer_name
      t.text :message
      t.string :filepaths
      t.string :bug
      t.string :reviewers
      t.string :test
      t.string :svn_revision
    end
  end
end
