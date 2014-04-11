class Developer < ActiveRecord::Base


  has_many :participants, primary_key: 'email', foreign_key: 'email'
  has_many :contributors, primary_key: 'email', foreign_key: 'email'
  has_many :reviewers, primary_key: 'email', foreign_key: 'email'


  belongs_to :cc

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :developers, :email, unique: true
    ActiveRecord::Base.connection.add_index :developers, :name
  end

  # Given an email and name, parses the email and searches to see if the developer
  # is already in the database. If they are, returns the name of the developer.
  # If not, adds the developer's information to database.
  # Params:
  # 	email:: the email address of a developer
  # 	name:: the name of a developer, associated with the email, default is a blank string
  def self.search_or_add(email, name="")
    email.downcase!
  	if (email.index('+') != nil) 
      email = email.slice(0, email.index('+')) + email.slice(email.index('@'), (email.length()-1))
    end #fixing the email

    if (Developer.find_by_email(email) == nil) 
      developer = Developer.new
      developer["email"] = email
      developer["name"] = name
      developer.save
      return developer
    else 
      dobj = Developer.find_by_email(email)
      if (Developer.find_by_name(name) == nil) 
        dobj["name"] = name #if there is already an owner there and they dont match, that a problem
      end #checking if the name exists
      return dobj
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

    reviewer = self.reviewers

    #Are we a reviewer
    if reviewer.size > 0

      vul_count = 0
      reviewer.each do |review| 

        #Do we have a code_reviewer for this reviewer
        if code_review=review.code_review   

          if code_review.created < date

            if code_review.is_inspecting_vulnerability? then vul_count+=1 end

          end#date check

        end#code_review check   

      end#loop

      #return the number of vulnerable inspections
      return vul_count

    else#reviewer check

      #Not a reviewer so no vulnerable inspections
      return 0

    end#reviewer nil check

  end#num_inspected_vulnerables

end#class
