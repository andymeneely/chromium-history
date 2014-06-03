class ReleaseFilepathLoader

  def load
    #Yes, this is hardcoded to release 11.0 until we begin to analyze multiple releases
    Release.create(name: '11.0', date: DateTime.new(2011,01,28))
    datadir = File.expand_path(Rails.configuration.datadir)
    copy = "COPY release_filepaths FROM '#{datadir}/releases/11.0.csv' DELIMITER ',' CSV"
    ActiveRecord::Base.connection.execute(copy)
  end
end
