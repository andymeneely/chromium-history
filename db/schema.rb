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

ActiveRecord::Schema.define(version: 20140211225817) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "code_reviews", force: true do |t|
    t.text     "description"
    t.string   "subject"
    t.datetime "created"
    t.datetime "modified"
    t.string   "cve"
    t.integer  "issue",       limit: 8
  end

  add_index "code_reviews", ["issue"], name: "index_code_reviews_on_issue", unique: true, using: :btree

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

  add_index "comments", ["author_email"], name: "index_comments_on_author_email", using: :btree
  add_index "comments", ["composite_patch_set_file_id"], name: "index_comments_on_composite_patch_set_file_id", using: :btree
  add_index "comments", ["patch_set_file_id"], name: "index_comments_on_patch_set_file_id", using: :btree

  create_table "commit_filepaths", id: false, force: true do |t|
    t.integer "commit_id",   null: false
    t.integer "filepath_id", null: false
  end

  create_table "commit_files", force: true do |t|
    t.integer "commit_id"
    t.string  "filepath",    limit: 1000
    t.string  "commit_hash"
  end

  create_table "commits", force: true do |t|
    t.string   "commit_hash"
    t.string   "parent_commit_hash"
    t.string   "author_email"
    t.text     "message"
    t.string   "bug"
    t.string   "svn_revision"
    t.datetime "created_at"
    t.integer  "commit_files_id"
    t.integer  "code_review_id",     limit: 8
  end

  add_index "commits", ["author_email"], name: "index_commits_on_author_email", using: :btree
  add_index "commits", ["commit_hash"], name: "index_commits_on_commit_hash", unique: true, using: :btree
  add_index "commits", ["parent_commit_hash"], name: "index_commits_on_parent_commit_hash", using: :btree

  create_table "cves", force: true do |t|
    t.string "cve"
  end

  add_index "cves", ["cve"], name: "index_cves_on_cve", unique: true, using: :btree

  create_table "developers", force: true do |t|
    t.string "name"
    t.string "email"
  end

  add_index "developers", ["email"], name: "index_developers_on_email", unique: true, using: :btree
  add_index "developers", ["name"], name: "index_developers_on_name", using: :btree

  create_table "filepaths", force: true do |t|
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: true do |t|
    t.string   "sender"
    t.text     "text"
    t.boolean  "approval"
    t.boolean  "disapproval"
    t.datetime "date"
    t.integer  "code_review_id", limit: 8
  end

  add_index "messages", ["code_review_id"], name: "index_messages_on_code_review_id", using: :btree
  add_index "messages", ["sender"], name: "index_messages_on_sender", using: :btree

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

  add_index "patch_set_files", ["composite_patch_set_file_id"], name: "index_patch_set_files_on_composite_patch_set_file_id", unique: true, using: :btree
  add_index "patch_set_files", ["composite_patch_set_id"], name: "index_patch_set_files_on_composite_patch_set_id", using: :btree
  add_index "patch_set_files", ["filepath"], name: "index_patch_set_files_on_filepath", using: :btree
  add_index "patch_set_files", ["patch_set_id"], name: "index_patch_set_files_on_patch_set_id", using: :btree

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

  add_index "patch_sets", ["code_review_id"], name: "index_patch_sets_on_code_review_id", using: :btree
  add_index "patch_sets", ["composite_patch_set_id"], name: "index_patch_sets_on_composite_patch_set_id", unique: true, using: :btree
  add_index "patch_sets", ["owner_email"], name: "index_patch_sets_on_owner_email", using: :btree
  add_index "patch_sets", ["patchset"], name: "index_patch_sets_on_patchset", using: :btree

  create_table "reviewers", force: true do |t|
    t.string  "developer"
    t.integer "issue",     limit: 8
  end

end
