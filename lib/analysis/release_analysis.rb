# For each file in a given release, populate the necessary metrics
class ReleaseAnalysis

  def populate
    r = Release.find_by(name: '11.0') #hard-coded to Release 11 for now
    r.release_filepaths.find_each do |rf|
      rf.num_reviews = rf.filepath.code_reviews.size
      rf.num_reviewers = rf.filepath.reviewers.size
      rf.num_participants = rf.filepath.participants.size
      rf.perc_security_experienced_participants = rf.filepath.perc_security_exp_part(r.date)
      rf.vulnerable = rf.filepath.vulnerable?(r.date)
      rf.save
    end
  end

end
