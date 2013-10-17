require 'oj'

class CodeReviewLoader

def self.load
  obj = Oj.load_file("#{Rails.configuration.datadir}/9141024.json")
    c = CodeReview.create(description: obj['description'], subject: obj['subject'], created: obj['created'], modified: obj['modified'], issue: obj['issue'])
    obj['patchsets'].each do |id| 
      pobj = Oj.load_file("test/data/9141024/#{id}.json")
      p = PatchSet.create(message: pobj['message'], num_comments: pobj['num_comments'], patchset: pobj['patchset'], created: obj['created'], modified: obj['modified'])
      c.patch_sets << p
    end
    puts "Loading done."
end

end