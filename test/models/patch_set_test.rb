require 'test_helper'

class PatchSetTest < ActiveSupport::TestCase
  test "that patchsets are being parsed correctly" do
	
	cr = CodeReview.find_by issue: "23444043"
	
    # The loader is not unit testable in its current form.
	# Should be refactored to receive a mock database and the json documents.
	CodeReviewLoader.new.load_patchsets("23444043", cr, "20001")
	
	ps = PatchSet.where(:patchset => "20001", :code_review_id => cr.id)
	
	assert_equal(2, ps.num_comments)
	assert_equal("Add start refcount + fix potential hang during Stop()",ps.message)
  end
end
