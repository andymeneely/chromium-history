# This is a mixin for dynamically loading attributes from a hash of hashes (i.e. from an Oj json object) into an ActiveRecord model

module DataTransfer
  # Given a model, a json object, and a list of symbol properties, transfer the same attributes
  def transfer(model, json, properties)
    properties.each do |p|
      model[p] = json[p.to_s]
    end
    model.save
    model
  end
  
end
  
  
