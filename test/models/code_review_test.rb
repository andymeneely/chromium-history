require 'test_helper'

class CodeReviewTest < ActiveSupport::TestCase
  test "that code reviews are being parsed correctly" do
	# The loader is not unit testable in its current form.
	# Should be refactored to receive a mock database and the json documents.
	CodeReviewLoader.new.load
	cr = CodeReview.find(1)
    assert_equal(10854242, cr.issue)
	assert_equal("Make shared memory segments writable only by their rightful owners.

BUG=143859
TEST=Chrome's UI still works on Linux and Chrome OS
Committed: https://src.chromium.org/viewvc/chrome?view=rev&revision=158289", cr.description)
	assert_equal("Make shared memory segments writable only by their rightful owners.",cr.subject)
  end
end
