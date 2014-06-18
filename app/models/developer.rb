class Developer < ActiveRecord::Base

  has_many :participants, primary_key: 'id', foreign_key: 'dev_id'
  has_many :contributors, primary_key: 'id', foreign_key: 'dev_id'
  has_many :reviewers, primary_key: 'id', foreign_key: 'dev_id'
  has_many :sheriffs, primary_key: 'id', foreign_key: 'dev_id'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :developers, :email, unique: true
    # ActiveRecord::Base.connection.add_index :developers, :name
  end
	
	
  def self.sanitize_validate_email dirty_email 
    begin
      email = dirty_email.gsub(/\+\w+(?=@)/, '') #strips any tags on the email
      email.downcase!
      matched_email = /([a-zA-Z0-9%._-]+)@([a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+)/.match email #groups local and domain and checks for match
      return nil, false unless matched_email  #returns [nil,false] if matched_email is invalid (nil)
      email_address = matched_email[0]
      email_local = matched_email[1]
      email_domain = matched_email[2]
			
      if email_domain == 'gtempaccount.com'
        #     e.g. john-doe%gmail.com@gtempaccount.com
        match = /^([\w\-]+)%(\w+.\w{3})(?=@gtempaccount.com)/.match email_address
	      email_address = (match[1] + '@' + match[2])
        email_local = match[1]
        email_domain = match[2]
      end
		
      bad_domains = ['chromioum.org','chroimum.org','chromium.com','chromoium.org','chromium.rg','chromum.org','chormium.org','chromimum.org','chromium.orf','chromiu.org','chroium.org','chcromium.org','chromuim.org','google.com']
      if bad_domains.include? email_domain 
        email_address = email_local + "@chromium.org"
      end
			
      return nil, false if self.blacklisted_email_local? email_local or self.blacklisted_email_domain? email_domain
      return email_address, true
    end
  end
	
  def self.blacklisted_email_local? local
    blacklist = ['reply', 'chromium-reviews','commit-bot']
    blacklist.include? local
  end
	
  def self.blacklisted_email_domain? domain
    blacklist = ['googlegroups.com']
    blacklist.include? domain
  end
	
  # Given an email and name, parses the email and searches to see if the developer
  # is already in the database. If they are, returns the name of the developer.
  # If not, adds the developer's information to database.
  # Params:
  # 	email:: the email address of a developer
  # 	name:: the name of a developer, associated with the email, default is a blank string
  def self.search_or_add(email, name="")
    if (Developer.find_by_email(email).nil?) 
      developer = Developer.new
      developer["email"] = email
      developer["name"] = name
      developer.save
      return developer, false
    else 
      dobj = Developer.find_by_email(email)
      if (Developer.find_by_name(name) == nil) 
        dobj["name"] = name 
      end #checking if the name exists
      return dobj, true
    end #checking if the email exists
  	# returns the developer object either way
  end

end#class
