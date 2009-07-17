class CreateRegistrants < ActiveRecord::Migration
  def self.up
    create_table "registrants" do |t|
      t.string      "status"
      t.string      "locale", :limit => 2

      t.date        "date_of_birth"
      t.string      "email_address"
      t.boolean     "first_registration"
      t.string      "home_zip_code", :limit => 10
      t.boolean     "us_citizen"

      t.string      "name_title"
      t.string      "first_name"
      t.string      "middle_name"
      t.string      "last_name"
      t.string      "name_suffix"
      t.string      "home_address"
      t.string      "home_address2"
      t.string      "home_city"
      t.integer     "home_state_id"
      t.string      "mailing_address"
      t.string      "mailing_address2"
      t.string      "mailing_city"
      t.integer     "mailing_state_id"
      t.string      "mailing_zip_code", :limit => 10
      t.string      "party"
      t.string      "race"

      t.string      "state_id_number"
      t.string      "phone"
      t.string      "phone_type"
      t.string      "prev_name_title"
      t.string      "prev_first_name"
      t.string      "prev_middle_name"
      t.string      "prev_last_name"
      t.string      "prev_name_suffix"
      t.string      "prev_address"
      t.string      "prev_address2"
      t.string      "prev_city"
      t.integer     "prev_state_id"
      t.string      "prev_zip_code", :limit => 10

      t.boolean     "opt_in_email"
      t.boolean     "opt_in_sms"

      t.boolean     "attest_true"
      t.boolean     "attest_eligible"

      t.timestamps
    end
  end

  def self.down
    drop_table "registrants"
  end
end
