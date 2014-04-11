class AddReviewsWithOwnerToParticipants < ActiveRecord::Migration
  def change
    add_column :participants, :reviews_with_owner, :integer
  end
end
