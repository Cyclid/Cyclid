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

ActiveRecord::Schema.define(version: 20160216165454) do

  create_table "organizations", force: :cascade do |t|
    t.string "name",        null: false
    t.string "owner_email", null: false
  end

  create_table "organizations_users", id: false, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "user_id"
  end

  add_index "organizations_users", ["organization_id"], name: "index_organizations_users_on_organization_id"
  add_index "organizations_users", ["user_id"], name: "index_organizations_users_on_user_id"

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
  end

end
