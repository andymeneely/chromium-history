class Developer < ActiveRecord::Base
  belongs_to :reviewer
  has_many :participants, primary_key: 'email', foreign_key: 'email'

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

end
