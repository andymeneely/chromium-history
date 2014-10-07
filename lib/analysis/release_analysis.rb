# For each file in a given release, populate the necessary metrics
class ReleaseAnalysis

  def populate
    Release.all.each do |r|
      r.release_filepaths.find_each do |rf|
        rf.num_reviews = rf.filepath.code_reviews(r.date).size
        rf.num_reviewers = rf.filepath.reviewers(r.date).size
        rf.num_participants = rf.filepath.participants(r.date).size
        rf.perc_three_more_reviewers = rf.filepath.perc_three_more_reviewers(r.date)
        rf.perc_security_experienced_participants = rf.filepath.perc_security_exp_part(r.date)
        rf.avg_security_experienced_participants = rf.filepath.avg_security_exp_part(r.date)
        rf.avg_non_participating_revs = rf.filepath.avg_non_participating_revs(r.date)
        rf.avg_reviews_with_owner = rf.filepath.avg_reviews_with_owner(r.date)
        rf.avg_owner_familiarity_gap = rf.filepath.avg_owner_familiarity_gap(r.date)
        rf.perc_fast_reviews = rf.filepath.perc_fast_reviews(r.date)
        rf.perc_overlooked_patchsets = rf.filepath.perc_overlooked_patchsets(r.date)
        rf.avg_sheriff_hours = rf.filepath.avg_sheriff_hours(r.date)
        rf.vulnerable = rf.filepath.vulnerable?(r.date)
        rf.num_vulnerabilities = rf.filepath.cves(r.date).count
        rf.num_bugs = rf.filepath.bugs(r.date).count
        
        
        #pre_ metrics
        rf.num_pre_features = rf.filepath.bugs(r.date,'type-feature').count
        rf.num_pre_compatibility_bugs = rf.filepath.bugs(r.date,'type-compat').count
        rf.num_pre_regression_bugs = rf.filepath.bugs(r.date,'type-bug-regression').count
        rf.num_pre_security_bugs = rf.filepath.bugs(r.date,'type-bug-regression').count
        rf.num_pre_tests_fails_bugs = rf.filepath.bugs(r.date,'cr-tests-fails').count
        rf.num_pre_stability_crash_bugs = rf.filepath.bugs(r.date,'stability-crash').count
        rf.num_pre_build_bugs = rf.filepath.bugs(r.date,'build').count
        
        rf.save
      end
    end
  end

end
