bug_email = "sa...@chromium.org"


#splits the string in name and domain.
splited = bug_email.split("...@")

name = splited[0] 
domain = splited[1]


#regular expression to find the matching email.
reg_exp = "^#{name}[^[:space:]]*@#{domain}"
sql = "SELECT email FROM Developers WHERE email ~ '#{reg_exp}'"

matches = Developer.find_by_sql(sql)

matches.each do |match|
  puts match.email
end
