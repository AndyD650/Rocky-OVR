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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20180710231408) do

  create_table "admins", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

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
    t.string   "queue"
  end

  create_table "email_templates", :force => true do |t|
    t.integer  "partner_id", :null => false
    t.string   "name",       :null => false
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject"
  end

  add_index "email_templates", ["partner_id", "name"], :name => "index_email_templates_on_partner_id_and_name", :unique => true

  create_table "geo_states", :force => true do |t|
    t.string   "name",                    :limit => 21
    t.string   "abbreviation",            :limit => 2
    t.boolean  "requires_race"
    t.boolean  "requires_party"
    t.boolean  "participating"
    t.integer  "id_length_min"
    t.integer  "id_length_max"
    t.string   "registrar_address"
    t.string   "registrar_phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "registrar_url"
    t.string   "online_registration_url"
  end

  create_table "grommet_requests", :force => true do |t|
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.text     "request_params"
  end

  create_table "partners", :force => true do |t|
    t.string   "username",                                                            :null => false
    t.string   "email",                                                               :null => false
    t.string   "crypted_password",                                                    :null => false
    t.string   "password_salt",                                                       :null => false
    t.string   "persistence_token",                                                   :null => false
    t.string   "perishable_token",                                 :default => "",    :null => false
    t.string   "name"
    t.string   "organization"
    t.string   "url"
    t.string   "address"
    t.string   "city"
    t.integer  "state_id"
    t.string   "zip_code",                           :limit => 10
    t.string   "phone"
    t.string   "survey_question_1_en"
    t.string   "survey_question_1_es"
    t.string   "survey_question_2_en"
    t.string   "survey_question_2_es"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ask_for_volunteers",                               :default => false
    t.string   "widget_image"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.boolean  "whitelabeled",                                     :default => false
    t.boolean  "partner_ask_for_volunteers",                       :default => false
    t.boolean  "rtv_email_opt_in",                                 :default => true
    t.boolean  "partner_email_opt_in",                             :default => false
    t.boolean  "rtv_sms_opt_in",                                   :default => true
    t.boolean  "partner_sms_opt_in",                               :default => false
    t.string   "api_key",                            :limit => 40, :default => ""
    t.string   "privacy_url"
    t.string   "from_email"
    t.string   "finish_iframe_url"
    t.boolean  "csv_ready",                                        :default => false
    t.string   "csv_file_name"
    t.boolean  "is_government_partner",                            :default => false
    t.integer  "government_partner_state_id"
    t.text     "government_partner_zip_codes"
    t.text     "survey_question_1"
    t.text     "survey_question_2"
    t.text     "external_tracking_snippet"
    t.string   "registration_instructions_url"
    t.text     "pixel_tracking_codes"
    t.datetime "from_email_verified_at"
    t.datetime "from_email_verification_checked_at"
    t.boolean  "enabled_for_grommet",                              :default => false, :null => false
    t.text     "branding_update_request"
    t.boolean  "active",                                           :default => true,  :null => false
    t.text     "external_conversion_snippet"
    t.text     "replace_system_css"
    t.string   "pa_api_key"
  end

  add_index "partners", ["email"], :name => "index_partners_on_email"
  add_index "partners", ["perishable_token"], :name => "index_partners_on_perishable_token"
  add_index "partners", ["persistence_token"], :name => "index_partners_on_persistence_token"
  add_index "partners", ["username"], :name => "index_partners_on_username"
  add_index "partners", ["whitelabeled"], :name => "index_partners_on_whitelabeled"

  create_table "pdf_generations", :force => true do |t|
    t.integer  "registrant_id"
    t.boolean  "locked",        :default => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "pdf_generations", ["locked"], :name => "index_pdf_generations_on_locked"

  create_table "priority_pdf_generations", :force => true do |t|
    t.integer  "registrant_id"
    t.boolean  "locked",        :default => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "priority_pdf_generations", ["locked"], :name => "index_priority_pdf_generations_on_locked"

  create_table "registrant_statuses", :force => true do |t|
    t.integer  "registrant_id"
    t.string   "state_transaction_id"
    t.string   "state_status"
    t.string   "state_status_details"
    t.integer  "geo_state_id"
    t.datetime "state_application_date"
    t.text     "state_data"
    t.integer  "admin_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "registrant_statuses", ["state_transaction_id", "geo_state_id"], :name => "registrant_statues_state_id_index"

  create_table "registrants", :force => true do |t|
    t.string   "status"
    t.string   "locale",                             :limit => 64
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
    t.boolean  "opt_in_email",                                     :default => false
    t.boolean  "opt_in_sms",                                       :default => false
    t.string   "survey_answer_1"
    t.string   "survey_answer_2"
    t.boolean  "ineligible_non_participating_state"
    t.boolean  "ineligible_age"
    t.boolean  "ineligible_non_citizen"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "abandoned",                                        :default => false, :null => false
    t.boolean  "volunteer",                                        :default => false
    t.string   "tracking_source"
    t.boolean  "under_18_ok"
    t.boolean  "remind_when_18"
    t.integer  "age"
    t.string   "official_party_name"
    t.boolean  "pdf_ready"
    t.string   "barcode",                            :limit => 12
    t.boolean  "partner_opt_in_email",                             :default => false
    t.boolean  "partner_opt_in_sms",                               :default => false
    t.boolean  "partner_volunteer",                                :default => false
    t.boolean  "has_state_license"
    t.boolean  "using_state_online_registration",                  :default => false
    t.boolean  "javascript_disabled",                              :default => false
    t.string   "tracking_id"
    t.boolean  "finish_with_state",                                :default => false
    t.string   "original_survey_question_1"
    t.string   "original_survey_question_2"
    t.boolean  "send_confirmation_reminder_emails",                :default => false
    t.boolean  "building_via_api_call",                            :default => false
    t.boolean  "short_form",                                       :default => false
    t.string   "collect_email_address"
    t.boolean  "will_be_18_by_election"
    t.text     "state_ovr_data"
    t.integer  "remote_partner_id"
    t.string   "remote_uid"
    t.string   "remote_pdf_path"
    t.string   "custom_stop_reminders_url"
    t.boolean  "pdf_downloaded",                                   :default => false
    t.datetime "pdf_downloaded_at"
    t.boolean  "final_reminder_delivered",                         :default => false
    t.boolean  "is_fake",                                          :default => false
    t.boolean  "has_ssn"
    t.string   "home_county"
    t.string   "prev_county"
    t.string   "mailing_county"
    t.string   "open_tracking_id"
  end

  add_index "registrants", ["abandoned", "status"], :name => "registrant_stale"
  add_index "registrants", ["abandoned"], :name => "index_registrants_on_abandoned"
  add_index "registrants", ["age"], :name => "index_registrants_on_age"
  add_index "registrants", ["created_at"], :name => "index_registrants_on_created_at"
  add_index "registrants", ["finish_with_state", "partner_id", "status", "created_at"], :name => "index_registrants_for_stats"
  add_index "registrants", ["finish_with_state", "partner_id", "status", "home_state_id"], :name => "index_registrants_by_state"
  add_index "registrants", ["finish_with_state", "partner_id", "status"], :name => "index_registrants_for_started_count"
  add_index "registrants", ["home_state_id"], :name => "index_registrants_on_home_state_id"
  add_index "registrants", ["name_title"], :name => "index_registrants_on_name_title"
  add_index "registrants", ["official_party_name"], :name => "index_registrants_on_official_party_name"
  add_index "registrants", ["partner_id", "status"], :name => "index_registrants_by_partner_and_status"
  add_index "registrants", ["partner_id"], :name => "index_registrants_on_partner_id"
  add_index "registrants", ["race"], :name => "index_registrants_on_race"
  add_index "registrants", ["reminders_left", "updated_at"], :name => "index_registrants_on_reminders_left_and_updated_at"
  add_index "registrants", ["remote_partner_id"], :name => "index_registrants_on_remote_partner_id"
  add_index "registrants", ["remote_uid"], :name => "index_registrants_on_remote_uid"
  add_index "registrants", ["status", "partner_id", "age"], :name => "index_registrants_by_age"
  add_index "registrants", ["status", "partner_id", "name_title"], :name => "index_registrants_by_gender"
  add_index "registrants", ["status", "partner_id", "official_party_name"], :name => "index_registrants_by_party"
  add_index "registrants", ["status", "partner_id", "race"], :name => "index_registrants_by_race"
  add_index "registrants", ["status"], :name => "index_registrants_on_status"
  add_index "registrants", ["uid"], :name => "index_registrants_on_uid"

  create_table "settings", :force => true do |t|
    t.string   "var",                       :null => false
    t.text     "value"
    t.integer  "target_id"
    t.string   "target_type", :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["target_type", "target_id", "var"], :name => "index_settings_on_target_type_and_target_id_and_var", :unique => true

  create_table "state_localizations", :force => true do |t|
    t.integer  "state_id"
    t.string   "locale",                    :limit => 64
    t.string   "parties",                   :limit => 1024
    t.string   "no_party"
    t.string   "not_participating_tooltip", :limit => 1024
    t.string   "race_tooltip",              :limit => 1024
    t.string   "id_number_tooltip",         :limit => 1024
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "party_tooltip",             :limit => 1024
    t.string   "sub_18",                    :limit => 1024
    t.string   "registration_deadline",     :limit => 1024
    t.string   "pdf_instructions",          :limit => 1024
    t.string   "email_instructions",        :limit => 1024
    t.string   "pdf_other_instructions",    :limit => 1024
  end

  add_index "state_localizations", ["state_id"], :name => "index_state_localizations_on_state_id"

  create_table "state_registrants_pa_registrants", :force => true do |t|
    t.string   "email"
    t.boolean  "confirm_us_citizen"
    t.boolean  "confirm_will_be_18"
    t.date     "date_of_birth"
    t.string   "name_title"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "name_suffix"
    t.boolean  "change_of_name"
    t.string   "previous_first_name"
    t.string   "previous_last_name"
    t.string   "registration_address_1"
    t.string   "registration_address_2"
    t.string   "registration_unit_type"
    t.string   "registration_unit_number"
    t.string   "registration_city"
    t.string   "registration_zip_code"
    t.string   "registration_county"
    t.boolean  "has_mailing_address"
    t.string   "mailing_address"
    t.string   "mailing_city"
    t.string   "mailing_state"
    t.string   "mailing_zip_code"
    t.boolean  "change_of_address"
    t.string   "previous_address"
    t.string   "previous_city"
    t.string   "previous_state"
    t.string   "previous_zip_code"
    t.string   "previous_county"
    t.boolean  "opt_in_email"
    t.boolean  "opt_in_sms"
    t.string   "phone"
    t.string   "party"
    t.string   "other_party"
    t.boolean  "change_of_party"
    t.string   "race"
    t.string   "penndot_number"
    t.string   "ssn4"
    t.boolean  "confirm_no_dl_or_ssn"
    t.text     "voter_signature_image",                :limit => 255
    t.boolean  "has_assistant"
    t.string   "assistant_name"
    t.string   "assistant_address"
    t.string   "assistant_phone"
    t.boolean  "confirm_assistant_declaration"
    t.boolean  "confirm_declaration"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.string   "registrant_id"
    t.string   "locale"
    t.string   "status"
    t.boolean  "confirm_no_penndot_number"
    t.boolean  "pa_submission_complete"
    t.string   "pa_transaction_id"
    t.text     "pa_submission_error"
    t.string   "previous_middle_name"
    t.string   "phone_type"
    t.string   "signature_method"
    t.string   "sms_number_for_continue_on_device"
    t.string   "email_address_for_continue_on_device"
  end

  create_table "state_registrants_va_registrants", :force => true do |t|
    t.boolean  "confirm_voter_record_update"
    t.boolean  "confirm_us_citizen"
    t.string   "ssn"
    t.boolean  "confirm_no_ssn"
    t.string   "dln"
    t.boolean  "confirm_no_dln"
    t.date     "date_of_birth"
    t.string   "name_title"
    t.string   "first_name"
    t.string   "middle_name"
    t.boolean  "confirm_no_middle_name"
    t.string   "last_name"
    t.string   "name_suffix"
    t.boolean  "change_of_name"
    t.string   "previous_first_name"
    t.string   "previous_last_name"
    t.string   "previous_middle_name"
    t.string   "previous_name_suffix"
    t.string   "registration_address_1"
    t.string   "registration_address_2"
    t.string   "registration_city"
    t.string   "registration_zip_code"
    t.string   "registration_locality"
    t.string   "email"
    t.string   "phone"
    t.boolean  "opt_in_email"
    t.boolean  "opt_in_sms"
    t.boolean  "convicted_of_felony"
    t.boolean  "right_to_vote_restored"
    t.boolean  "is_military"
    t.boolean  "is_law_enforcement"
    t.boolean  "is_court_protected"
    t.boolean  "is_confidentiality_program"
    t.boolean  "is_being_stalked"
    t.boolean  "no_usps_address"
    t.string   "mailing_address_1"
    t.string   "mailing_address_2"
    t.string   "mailing_city"
    t.string   "mailing_state"
    t.string   "mailing_zip_code"
    t.string   "mailing_address_locality"
    t.boolean  "registered_in_other_state"
    t.string   "other_registration_state_abbrev"
    t.boolean  "interested_in_being_poll_worker"
    t.datetime "submitted_at"
    t.boolean  "confirm_voter_fraud_warning"
    t.boolean  "confirm_affirm_privacy_notice"
    t.boolean  "confirm_will_be_18"
    t.string   "registrant_id"
    t.string   "locale"
    t.string   "status"
    t.boolean  "va_check_complete"
    t.string   "va_check_voter_id"
    t.boolean  "va_check_is_registered_voter"
    t.boolean  "va_check_has_dmv_signature"
    t.boolean  "va_check_error"
    t.text     "va_check_response"
    t.boolean  "va_submission_complete"
    t.string   "va_transaction_id"
    t.text     "va_submission_error"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "has_mailing_address"
    t.boolean  "confirm_register_to_vote"
    t.string   "phone_type"
  end

  create_table "tracking_events", :force => true do |t|
    t.string   "tracking_event_name"
    t.string   "source_tracking_id"
    t.string   "partner_tracking_id"
    t.string   "open_tracking_id"
    t.text     "geo_location"
    t.text     "tracking_data"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "tracking_events", ["open_tracking_id"], :name => "index_tracking_events_on_open_tracking_id"
  add_index "tracking_events", ["partner_tracking_id"], :name => "index_tracking_events_on_partner_tracking_id"
  add_index "tracking_events", ["source_tracking_id"], :name => "index_tracking_events_on_source_tracking_id"

  create_table "zip_code_county_addresses", :force => true do |t|
    t.integer  "geo_state_id"
    t.string   "zip"
    t.string   "address"
    t.text     "county",              :limit => 255
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.text     "cities"
    t.text     "unacceptable_cities"
    t.datetime "last_checked"
  end

  add_index "zip_code_county_addresses", ["geo_state_id"], :name => "index_zip_code_county_addresses_on_geo_state_id"
  add_index "zip_code_county_addresses", ["zip"], :name => "index_zip_code_county_addresses_on_zip"

end
