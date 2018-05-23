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

ActiveRecord::Schema.define(version: 20180523165128) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "batches", force: :cascade do |t|
    t.boolean  "processing"
    t.boolean  "done"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rows", force: :cascade do |t|
    t.integer  "batch_id"
    t.string   "name"
    t.string   "school"
    t.string   "business"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "profiles"
    t.boolean  "checked",    default: false
    t.boolean  "unique"
    t.string   "jobtitle"
    t.string   "city"
    t.string   "pro_path"
    t.string   "firstname"
    t.string   "lastname"
  end

end
