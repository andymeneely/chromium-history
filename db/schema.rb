# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140512131450) do

  create_table "blocks", id: false, force: true do |t|
    t.integer "bug_id"
    t.integer "blocking_id"
  end

  create_table "bug_comments", id: false, force: true do |t|
    t.integer  "bug_id"
    t.text     "content"
    t.string   "author_email"
    t.string   "author_uri"
    t.datetime "updated"
  end

  create_table "bug_labels",id: false, force: true do |t|
    t.integer "label_id"
    t.integer "bug_id"
  end

  create_table "bugs", id:false, force: true do |t|
    t.integer  "bug_id"
    t.string   "title",   limit: 500
    t.integer  "stars"
    t.string   "status"
    t.string   "reporter"
    t.datetime "opened" 
    t.datetime "closed"
    t.datetime "modified"
    t.string   "owner_email"
    t.string   "owner_uri" 
    t.text     "content"
  end

  create_table "code_reviews", id: false, force: true do |t|
    t.text     "description"
    t.string   "subject"
    t.datetime "created"
    t.datetime "modified"
    t.integer  "issue",       limit: 8
    t.string   "owner_email"
    t.integer  "owner_id"
    t.string   "commit_hash"
    t.integer  "non_participating_revs"
    t.integer  "total_reviews_with_owner"
    t.integer  "owner_familiarity_gap"
    t.integer  "total_sheriff_hours"
    t.boolean  "cursory"
  end

  create_table "code_reviews_cvenums", id: false, force: true do |t|
    t.string  "cvenum_id"
    t.integer "code_review_id"
  end

  create_table "comments", id: false, force: true do |t|
    t.string   "author_email"
    t.integer  "author_id"
    t.text     "text"
    t.boolean  "draft"
    t.integer  "lineno"
    t.datetime "date"
    t.boolean  "left"
    t.string   "composite_patch_set_file_id", limit: 1000
  end

  create_table "commit_filepaths", force: true do |t|
    t.string "commit_hash"
    t.string "filepath"
  end

  create_table "commits", id: false, force: true do |t|
    t.string   "commit_hash"
    t.string   "parent_commit_hash"
    t.string   "author_email"
    t.integer  "author_id"
    t.text     "message"
    t.string   "bug"
    t.string   "reviewers"
    t.string   "svn_revision"
    t.datetime "created_at"
  end

  create_table "commit_bugs", id: false, force: true do |t|
    t.string  "commit_hash"
    t.integer "bug_id"
  end
 
  create_table "contributors", id: false, force: true do |t|
    t.integer "dev_id"
    t.integer "issue",  limit: 8
  end

  create_table "cvenums", id: false, force: true do |t|
    t.string "cve"
  end

  create_table "developers", force: true do |t|
    t.string "email"
  end

  create_table "filepaths", id: false, force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filepath",   limit: 500
  end

  create_table "labels",id:false, force: true do |t|
    t.integer "label_id"
    t.string  "label"
  end

  create_table "messages", id: false, force: true do |t|
    t.string   "sender"
    t.integer  "sender_id"
    t.text     "text"
    t.boolean  "approval"
    t.boolean  "disapproval"
    t.datetime "date"
    t.integer  "code_review_id", limit: 8
  end

  create_table "participants", id: false, force: true do |t|
    t.integer  "dev_id"
    t.integer  "owner_id"
    t.integer  "issue",                limit: 8
    t.datetime "review_date"
    t.integer  "reviews_with_owner"
    t.boolean  "security_experienced"
    t.integer  "sheriff_hours"
  end

  create_table "patch_set_files", id: false, force: true do |t|
    t.string  "filepath"
    t.string  "status"
    t.integer "num_chunks"
    t.integer "num_added"
    t.integer "num_removed"
    t.boolean "is_binary"
    t.string  "composite_patch_set_id"
    t.string  "composite_patch_set_file_id", limit: 1000
  end

  create_table "patch_sets", id: false, force: true do |t|
    t.datetime "created"
    t.integer  "num_comments"
    t.text     "message"
    t.datetime "modified"
    t.string   "owner_email"
    t.integer  "owner_id"
    t.integer  "code_review_id",         limit: 8
    t.integer  "patchset",               limit: 8
    t.string   "composite_patch_set_id"
  end

  create_table "release_filepaths", id: false, force: true do |t|
    t.string  "release"
    t.string  "thefilepath"
    t.integer "sloc"
    t.integer "churn"
    t.integer "num_reviews"
    t.integer "num_reviewers"
    t.integer "num_participants"
    t.decimal "avg_non_participating_revs"
    t.decimal "perc_three_more_reviewers"
    t.decimal "perc_security_experienced_participants"
    t.decimal "avg_security_experienced_participants"
    t.decimal "avg_reviews_with_owner"
    t.decimal "avg_owner_familiarity_gap"
    t.decimal "perc_fast_reviews"
    t.decimal "perc_overlooked_patchsets"
    t.decimal "avg_sheriff_hours"
    t.boolean "vulnerable"
    t.integer "num_vulnerabilities"
    t.integer "num_bugs"
  end

  create_table "releases", id: false, force: true do |t|
    t.string   "name"
    t.datetime "date"
  end

  create_table "reviewers", id: false, force: true do |t|
    t.integer "issue",  limit: 8
    t.integer "dev_id"
    t.string  "email"
  end

  create_table "sheriff_rotations", force: true do |t|
    t.integer  "dev_id"
    t.datetime "start"
    t.integer  "duration"
    t.string   "title"
  end

end
