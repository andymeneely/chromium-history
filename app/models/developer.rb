require 'mail'

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
			matched_email = /([a-zA-Z0-9%._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+)/.match email
			raise Exception, "Invalid email address: #{email}" unless matched_email
			email = matched_email[0]
			# Performs basic email validation on creation
			# will throw exception for invalid email 
			m = Mail::Address.new(email)
			
			if m.domain.nil?
				raise Exception, "Invalid email address: #{email}"
			end
			
			if m.domain == 'gtempaccount.com'
				match = /^(\w+)\W(\w+.\w+)(?=@gtempaccount.com)/.match m.address
				m = Mail::Address.new(match[1] + '@' + match[2])
			end
			
			if m.domain == 'google.com' 
				m = Mail::Address.new("#{m.local}@chromium.org")
			end
			
			if self.blacklisted_email_local? m.local or self.blacklisted_email_domain? m.domain
				raise Exception, "Blacklisted email!"
			end
			
			return m.address, true
		rescue Exception => e
			return nil, false
		end
	end
	
	def self.blacklisted_email_local? local
		blacklist = ['reply', 'chromium-reviews']
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

  # Get the number of vulnerabilies
  # inspected by this developer leading
  # up to the provided date. Default
  # date is today. There are multiple
  # issues for a Reviewer. The Date param
  # could be a string. 
  #
  # @param- date Time object or string. Str format: "DD-MM-YYYY HH:MM:SS"
  # @return - number of inspected vulnerabilities
  def num_vulnerable_inspects(date=Time.now)


    #if date is a string then convert to Time object
    if date.class == String then date = Time.new(date) end

    #FIXME This is broken. Just returns a result set and not a number
    #query = "SELECT COUNT(c.issue) FROM 
    #        developers d JOIN 
    #        participants p ON 
    #        (d.id = p.dev_id) JOIN 
    #        code_reviews c ON 
    #        (p.issue = c.issue) JOIN 
    #        code_reviews_cvenums e ON 
    #        e.code_review_id = c.issue WHERE
    #        c.created < date '#{date.to_s}'"

    #self.connection.execute(query);
    return 0
  end

end#class
