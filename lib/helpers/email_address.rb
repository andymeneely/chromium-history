class EmailAddress
  attr_reader :local, :domain, :address
  def initialize(email)
    matched_email = /([a-zA-Z0-9%._-]+)@([a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+)/.match email
    @address = matched_email[0]
    @local = matched_email[1]
    @domain = matched_email[2]
  end
end
