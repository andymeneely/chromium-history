require 'mail'

class Developer < ActiveRecord::Base


  has_many :participants, primary_key: 'email', foreign_key: 'email'
  has_many :contributors, primary_key: 'email', foreign_key: 'email'
  has_many :reviewers, primary_key: 'email', foreign_key: 'email'
  has_many :sheriffs, primary_key: 'email', foreign_key: 'email'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :developers, :email, unique: true
    ActiveRecord::Base.connection.add_index :developers, :name
  end
	
	
	def self.sanitize_validate_email email 
		begin
			email.gsub!(/\+\w+(?=@)/, '')
			email.gsub!(')', '')
			email.downcase!

			# Performs basic email validation on creation
			# will throw exception for invalid email 
			m = Mail::Address.new(email)
			
			if m.domain.nil?
				raise Exception, "Invalid email address: #{email}"
			end
			
			if m.domain == 'gtempaccount.com'
				match = /^(\w+)\W(\w+.\w+)(?=@gtempaccount.com)/.match m.address
				m = Mail::Address.new(match[1] + match[2])
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
	
	def self.blacklisted_email? email
		blacklist = [/\Areply@/, /@googlegroups...\w\z/]
		blacklist.each do |pattern|
			if not pattern.match(email).nil?
				puts email
				return true 
			end
		end
		false
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
      # developer.save
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

    query = "SELECT COUNT(c.issue) FROM 
            developers d JOIN 
            participants p ON 
            (d.email = p.email) JOIN 
            code_reviews c ON 
            (p.issue = c.issue) JOIN 
            code_reviews_cvenums e ON 
            e.code_review_id = c.id WHERE
            c.created < date $1;"

    self.connection.prepare('date', query)
    result = self.connection.exec_prepared('date', date)
    conn.close
    
    result 
  end

end#class
