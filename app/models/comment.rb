class Comment < ActiveRecord::Base
  belongs_to :patch_set_file
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :comments, :composite_patch_set_file_id
  end

  def get_convo issue
    Comment.select("author_id, text")
      .where('code_review_id = ?', issue)
      .order('code_review_id')
  end

  def get_all_convo resultFile, limit
    ActiveRecord::Base.connection.execute("COPY(SELECT string_agg(text, E'\n') FROM Comments GROUP BY code_review_id LIMIT #{limit}) TO '#{resultFile}' WITH (FORMAT text)")
  end
end
