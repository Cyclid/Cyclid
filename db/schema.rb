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

ActiveRecord::Schema.define(version: 20160715161156) do

  create_table "job_records", force: :cascade do |t|
    t.string   "job_name"
    t.string   "job_version"
    t.datetime "started"
    t.datetime "ended"
    t.integer  "status"
    t.text     "log"
    t.text     "job"
    t.integer  "organization_id"
    t.integer  "user_id"
  end

  add_index "job_records", ["job_name"], name: "index_job_records_on_job_name"
  add_index "job_records", ["organization_id"], name: "index_job_records_on_organization_id"
  add_index "job_records", ["user_id"], name: "index_job_records_on_user_id"

  create_table "organizations", force: :cascade do |t|
    t.string "name",                                      null: false
    t.string "owner_email",                               null: false
    t.binary "rsa_private_key",                           null: false
    t.binary "rsa_public_key",                            null: false
    t.string "salt",            default: "0",             null: false
  end

  create_table "organizations_users", id: false, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "user_id"
  end

  add_index "organizations_users", ["organization_id"], name: "index_organizations_users_on_organization_id"
  add_index "organizations_users", ["user_id"], name: "index_organizations_users_on_user_id"

  create_table "plugin_configs", force: :cascade do |t|
    t.string  "plugin"
    t.string  "version"
    t.text    "config"
    t.integer "organization_id"
  end

  add_index "plugin_configs", ["organization_id"], name: "index_plugin_configs_on_organization_id"

  create_table "stages", force: :cascade do |t|
    t.string  "name",                              null: false
    t.string  "version",         default: "0.0.1", null: false
    t.integer "organization_id"
  end

  add_index "stages", ["organization_id"], name: "index_stages_on_organization_id"

  create_table "steps", force: :cascade do |t|
    t.integer "sequence", null: false
    t.text    "action"
    t.integer "stage_id"
  end

  add_index "steps", ["stage_id"], name: "index_steps_on_stage_id"

  create_table "userpermissions", force: :cascade do |t|
    t.boolean "admin",           default: false, null: false
    t.boolean "write",           default: false, null: false
    t.boolean "read",            default: false, null: false
    t.integer "user_id"
    t.integer "organization_id"
  end

  add_index "userpermissions", ["organization_id"], name: "index_userpermissions_on_organization_id"
  add_index "userpermissions", ["user_id"], name: "index_userpermissions_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email",    null: false
    t.string "password"
    t.string "secret"
    t.string "name"
  end

end
