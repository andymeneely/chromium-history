require 'csv'

class OwnersLoader

  def load
    tmp = File.expand_path(Rails.configuration.tmpdir)
    ActiveRecord::Base.connection.execute("COPY release_owners FROM '#{tmp}/parsed_owners.csv' DELIMITER ',' CSV")
  end
  end
