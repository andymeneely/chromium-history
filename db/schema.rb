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

ActiveRecord::Schema.define(version: 20140318142229) do

  create_table "ccs", force: true do |t|
    t.integer "issue", limit: 8
    t.string  "email"
  end

  create_table "code_reviews", force: true do |t|
    t.text     "description"
    t.string   "subject"
    t.datetime "created"
    t.datetime "modified"
    t.string   "cve"
    t.integer  "issue",       limit: 8
  end

  create_table "code_reviews_cvenums", id: false, force: true do |t|
    t.integer "cvenum_id"
    t.integer "code_review_id"
  end

  create_table "comments", force: true do |t|
    t.string   "author_email"
    t.text     "text"
    t.boolean  "draft"
    t.integer  "lineno"
    t.datetime "date"
    t.boolean  "left"
    t.integer  "patch_set_file_id",           limit: 8
    t.string   "composite_patch_set_file_id", limit: 1000
  end

  create_table "commit_filepaths", force: true do |t|
    t.string "commit_hash"
    t.string "filepath"
  end

  create_table "commits", force: true do |t|
    t.string   "commit_hash"
    t.string   "parent_commit_hash"
    t.string   "author_email"
    t.text     "message"
    t.string   "bug"
    t.string   "reviewers"
    t.string   "svn_revision"
    t.datetime "created_at"
    t.integer  "commit_files_id"
    t.integer  "code_review_id",     limit: 8
  end

  create_table "contributors", force: true do |t|
    t.string  "email"
    t.integer "issue", limit: 8
  end

  create_table "cvenums", force: true do |t|
    t.string "cve"
  end
  
  create_table "cves", force: true do |t|
    t.string "cve"
  end

  create_table "developers", force: true do |t|
    t.string "name"
    t.string "email"
  end

  create_table "filepaths", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filepath",   limit: 500
  end


  create_table "messages", force: true do |t|
    t.string   "sender"
    t.text     "text"
    t.boolean  "approval"
    t.boolean  "disapproval"
    t.datetime "date"
    t.integer  "code_review_id", limit: 8
  end

  create_table "participants", force: true do |t|
    t.string  "email"
    t.integer "issue", limit: 8
  end

  create_table "patch_set_files", force: true do |t|
    t.string  "filepath"
    t.string  "status"
    t.integer "num_chunks"
    t.integer "num_added"
    t.integer "num_removed"
    t.boolean "is_binary"
    t.integer "patch_set_id",                limit: 8
    t.string  "composite_patch_set_id"
    t.string  "composite_patch_set_file_id", limit: 1000
  end

  create_table "patch_sets", force: true do |t|
    t.datetime "created"
    t.integer  "num_comments"
    t.text     "message"
    t.datetime "modified"
    t.string   "owner_email"
    t.integer  "code_review_id",         limit: 8
    t.integer  "patchset",               limit: 8
    t.string   "composite_patch_set_id"
  end

  create_table "reviewers", force: true do |t|
    t.integer "issue", limit: 8
    t.string  "email"
  end

end
