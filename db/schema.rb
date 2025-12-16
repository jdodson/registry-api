# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_12_15_233859) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "ah_packages", primary_key: "package_id", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name"
    t.string "normalized_name"
    t.integer "category"
    t.string "logo_image_id"
    t.integer "stars"
    t.boolean "official", default: false
    t.boolean "cncf"
    t.text "description"
    t.string "version"
    t.string "app_version"
    t.string "license"
    t.boolean "deprecated", default: false
    t.boolean "has_values_schema", default: false
    t.boolean "signed", default: false
    t.boolean "all_containers_images_whitelisted", default: false
    t.integer "production_organizations_count"
    t.bigint "ts"
    t.string "repository_url"
    t.uuid "repository_id"
    t.boolean "signature_prov", default: false
    t.boolean "signature_cosign", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "buildpacks", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "namespace", limit: 250, null: false
    t.string "name", limit: 250, null: false
    t.string "version", limit: 250, null: false
    t.string "addr", limit: 250, null: false
    t.boolean "yanked", default: false
    t.text "description"
    t.text "homepage"
    t.text "licenses", default: [], array: true
    t.text "stacks", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "version_major", limit: 120, default: "0", null: false
    t.string "version_minor", limit: 120, default: "0", null: false
    t.string "version_patch", limit: 120, default: "0", null: false
    t.index ["name", "namespace", "version"], name: "index_buildpacks_on_name_namespace_version", unique: true
  end

end
