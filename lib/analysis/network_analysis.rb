
class NetworkAnalysis

  def run
    db   = Rails.configuration.database_configuration[Rails.env]["database"]
    user = Rails.configuration.database_configuration[Rails.env]["username"]
    dir  = File.dirname(__FILE__) # assume our script in the same dir as this script
    output = `python #{dir}/createNetwork.py #{user} #{db}`
    puts output
  end


end
