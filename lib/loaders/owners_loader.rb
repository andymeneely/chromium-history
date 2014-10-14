require 'csv'

class OwnersLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY release_owners FROM '#{datadir}/owners/parsed_owners.csv' DELIMITER ',' CSV")
  end
  end
