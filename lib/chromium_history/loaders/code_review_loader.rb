require 'oj'

class CodeReviewLoader

  def self.load
    obj = Oj.load_file("#{Rails.configuration.datadir}/9141024.json")
      CodeReview.transaction do
        c = CodeReview.create
        transfer(c, obj, [:description, :subject, :created, :modified, :issue])
        obj['patchsets'].each do |id| 
          pobj = Oj.load_file("test/data/9141024/#{id}.json")
          p = PatchSet.create(message: pobj['message'], num_comments: pobj['num_comments'], patchset: pobj['patchset'], created: obj['created'], modified: obj['modified'])
          c.patch_sets << p
        end
      end 
      puts "Loading done."
  end

  def self.transfer(model, json, properties)
    properties.each do |p|
      model[p] = json[p.to_s]
    end
    model.save
  end
  
end