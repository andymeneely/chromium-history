require 'csv'
require 'developer'


class EmailMatcher

  def find_match(email)
    
    email.downcase!
    
    #splits the string in name and domain.
    splited = email.split("...@")

    name = splited[0] 
    domain = splited[1]


    #regular expression to find the matching email.
    #reg_exp = "^#{name}[^[:space:]]*@#{domain}"
    reg_exp = "^#{name}[\\w]*@#{domain}"
    sql = "SELECT email FROM Developers WHERE email ~ '#{reg_exp}'"
    
    #disable active record logger.
    ActiveRecord::Base.logger = nil
    
    return Developer.find_by_sql(sql)    
  end
end


bug_emails = ['sa...@chormium.org',
              'p...@chromium.org',
              'dar..@google.org',       
              'b..@chromium.org',         
              'm...@google.com',
              'simon%g...@gtempaccount.com',
              'ndu...@chromium.org',       
              'apa...@chromium.org',    
              'to...@chromium.org',       
              'xi...@chromium.org',       
              'e...@chromium.org',        
              'sk...@chromium.org',     
              'oj...@chromium.org',        
              'to...@chromium.org',   
              'se...@chromium.org',
              'aa@google.com'
]


m = EmailMatcher.new


bug_emails.each do |email|
  puts Developer.sanitize_validate_email(email)
  matches = m.find_match(email)
    
  matches.each do |match|
   # puts "#{email} = #{match.email}"
  end    
end

