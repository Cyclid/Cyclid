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

ActiveRecord::Schema.define(version: 20160211172351) do

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

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email",    null: false
    t.string "password"
    t.string "secret"
  end

end
