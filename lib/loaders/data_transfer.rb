# This is a mixin for dynamically loading attributes from a hash of hashes (i.e. from an Oj json object) into an ActiveRecord model

module DataTransfer
  # Given a model, a json object, and a list of symbol properties, transfer the same attributes
  def transfer(model, json, properties)
    properties.each do |p|
      model[p] = json[p.to_s]
    end
    model
  end

  #Given a model, a hash, and a list of symbol properties, transfer the same attributees
  def parse_transfer(model, hash, properties)
  	properties.each do |p|
  		model[p] = hash[p]
  	end
  	model
  end

  def ordered_array(keyOrder, source)
    result = Array.new
    keyOrder.each do |key|
      result << source[key.to_s]
    end
    result
  end
  
end
  
  
