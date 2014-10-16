class Contributor < ActiveRecord::Base
	belongs_to :code_review, primary_key: "issue", foreign_key: "issue"
	belongs_to :developer, foreign_key: "dev_id", primary_key: "id"

  def self.optimize
    connection.add_index :contributors, :dev_id
    connection.add_index :contributors, :issue
    # ActiveRecord::Base.connection.add_index :contributors, [:email, :issue], unique: true
  end

  def self.contribution?(txt)
    txt_filtered = ''
    txt.to_s.each_line do |line| 
       txt_filtered << line unless (line[0] == '>' \
                                    or (line.start_with?("On ") and line.include?(" wrote:")) \
                                    or (line.starts_with?("https://codereview.chromium.org/")) \
                                    or (line.starts_with?("http://codereview.chromium.org/")))
    end
    return txt_filtered.length > 50
  end
  
  def self.filter_text(text)
    text_filtered = ''
    text.to_s.each_line do |line| 
    text_filtered << line unless (line[0] == '>' or (line.start_with?("On ") and line.include?(" wrote:")) \
                                  or (line.starts_with?("https://codereview.chromium.org/")) \
                                  or (line.starts_with?("http://codereview.chromium.org/")) \
                                  or (line.starts_with?("Retried try job too often")) \
                                  or (line.include?("Failed to apply patch")) \
                                  or (line.include?("CQ is trying da patch")))
    end
    return text_filtered
  end
end

