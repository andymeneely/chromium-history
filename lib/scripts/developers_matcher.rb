class EmailMatcher

  def find_match(email)
    #splits the string in name and domain.
    splited = email.split("...@")

    name = splited[0] 
    domain = splited[1]


    #regular expression to find the matching email.
    reg_exp = "^#{name}[^[:space:]]*@#{domain}"
    sql = "SELECT email FROM Developers WHERE email ~ '#{reg_exp}'"

    return Developer.find_by_sql(sql)    
  end
end


bug_emails = ['sa...@chromium.org',
              'p...@chromium.org',
              'dar..@chromium.org',       
              'b..@chromium.org',         
              'm...@gmail.com',
              'dea...@chromium.org',
              'ndu...@chromium.org',       
              'apa...@chromium.org',    
              'to...@chromium.org',       
              'xi...@chromium.org',       
              'e...@chromium.org',        
              'sk...@chromium.org',     
              'oj...@chromium.org',        
              'to...@chromium.org',   
              'se...@chromium.org'
]


m = EmailMatcher.new


bug_emails.each do |email|
  matches = m.find_match(email)
    
  matches.each do |match|
    puts "#{email} = #{match.email}"
  end    
end

