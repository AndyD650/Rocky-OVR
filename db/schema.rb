# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100331171944) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "geo_states", :force => true do |t|
    t.string   "name",              :limit => 21
    t.string   "abbreviation",      :limit => 2
    t.boolean  "requires_race"
    t.boolean  "requires_party"
    t.boolean  "participating"
    t.integer  "id_length_min"
    t.integer  "id_length_max"
    t.string   "registrar_address"
    t.string   "registrar_phone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "partners", :force => true do |t|
    t.string   "username",                                           :null => false
    t.string   "email",                                              :null => false
    t.string   "crypted_password",                                   :null => false
    t.string   "password_salt",                                      :null => false
    t.string   "persistence_token",                                  :null => false
    t.string   "perishable_token",                   :default => "", :null => false
    t.string   "name"
    t.string   "organization"
    t.string   "url"
    t.string   "address"
    t.string   "city"
    t.integer  "state_id"
    t.string   "zip_code",             :limit => 10
    t.string   "phone"
    t.string   "logo_image_url"
    t.string   "survey_question_1_en"
    t.string   "survey_question_1_es"
    t.string   "survey_question_2_en"
    t.string   "survey_question_2_es"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ask_for_volunteers"
    t.string   "widget_image"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
  end

  add_index "partners", ["email"], :name => "index_partners_on_email"
  add_index "partners", ["perishable_token"], :name => "index_partners_on_perishable_token"
  add_index "partners", ["persistence_token"], :name => "index_partners_on_persistence_token"
  add_index "partners", ["username"], :name => "index_partners_on_username"

  create_table "registrants", :force => true do |t|
    t.string   "status"
    t.string   "locale",                             :limit => 2
    t.integer  "partner_id"
    t.string   "uid"
    t.integer  "reminders_left",                                   :default => 0
    t.date     "date_of_birth"
    t.string   "email_address"
    t.boolean  "first_registration"
    t.string   "home_zip_code",                      :limit => 10
    t.boolean  "us_citizen"
    t.string   "name_title"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "name_suffix"
    t.string   "home_address"
    t.string   "home_unit"
    t.string   "home_city"
    t.integer  "home_state_id"
    t.boolean  "has_mailing_address"
    t.string   "mailing_address"
    t.string   "mailing_unit"
    t.string   "mailing_city"
    t.integer  "mailing_state_id"
    t.string   "mailing_zip_code",                   :limit => 10
    t.string   "party"
    t.string   "race"
    t.string   "state_id_number"
    t.string   "phone"
    t.string   "phone_type"
    t.boolean  "change_of_name"
    t.string   "prev_name_title"
    t.string   "prev_first_name"
    t.string   "prev_middle_name"
    t.string   "prev_last_name"
    t.string   "prev_name_suffix"
    t.boolean  "change_of_address"
    t.string   "prev_address"
    t.string   "prev_unit"
    t.string   "prev_city"
    t.integer  "prev_state_id"
    t.string   "prev_zip_code",                      :limit => 10
    t.boolean  "opt_in_email"
    t.boolean  "opt_in_sms"
    t.string   "survey_answer_1"
    t.string   "survey_answer_2"
    t.boolean  "ineligible_non_participating_state"
    t.boolean  "ineligible_age"
    t.boolean  "ineligible_non_citizen"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "abandoned",                                        :default => false, :null => false
    t.boolean  "volunteer"
    t.string   "tracking_source"
    t.boolean  "under_18_ok"
    t.boolean  "remind_when_18"
    t.integer  "age"
    t.string   "official_party_name"
  end

  add_index "registrants", ["official_party_name"], :name => "index_registrants_on_official_party_name"
  add_index "registrants", ["uid"], :name => "index_registrants_on_uid"

  create_table "state_localizations", :force => true do |t|
    t.integer  "state_id"
    t.string   "locale",                    :limit => 2
    t.string   "parties"
    t.string   "no_party"
    t.string   "not_participating_tooltip", :limit => 1024
    t.string   "race_tooltip",              :limit => 1024
    t.string   "id_number_tooltip",         :limit => 1024
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "party_tooltip",             :limit => 1024
    t.string   "sub_18"
  end

  add_index "state_localizations", ["state_id"], :name => "index_state_localizations_on_state_id"

end
