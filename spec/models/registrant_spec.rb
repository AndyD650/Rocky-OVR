require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ActionView::Helpers::UrlHelper

describe Registrant do
  describe "backfill data" do
    it "backfills the age even when redacted" do
      assert_equal 0, Registrant.find(:all, :conditions => "age IS NOT NULL").size
      5.times { Factory.create(:step_5_registrant, :date_of_birth => 241.months.ago.to_date.to_s(:db)) }
      4.times { Factory.create(:step_5_registrant, :date_of_birth => 239.months.ago.to_date.to_s(:db)) }
      Registrant.update_all("age = NULL")
      Registrant.update_all("state_id_number = NULL")
      Registrant.backfill_data
      assert_equal 5, Registrant.find_all_by_age(20).size
      assert_equal 4, Registrant.find_all_by_age(19).size
    end

    it "backfills the official_party_name even when redacted" do
      assert_equal 0, Registrant.find(:all, :conditions => "party IS NOT NULL").size
      5.times { Factory.create(:step_5_registrant, :home_zip_code => "94103", :party => "Green") }
      5.times { Factory.create(:step_5_registrant, :home_zip_code => "94103", :party => "Verde", :locale => "es") }
      4.times { Factory.create(:step_5_registrant, :home_zip_code => "94103", :party => "Decline to State") }
      4.times { Factory.create(:step_5_registrant, :home_zip_code => "94103", :party => "Se niega a declarar", :locale => "es") }
      assert_equal 18, Registrant.find(:all, :conditions => "party IS NOT NULL").size
      Registrant.update_all("official_party_name = NULL")
      Registrant.update_all("state_id_number = NULL")
      Registrant.backfill_data
      assert_equal 10, Registrant.find_all_by_official_party_name("Green").size
      assert_equal 8, Registrant.find_all_by_official_party_name("None").size
    end
  end

  describe "to_param hides id" do
    it "should be nil for new records" do
      reg = Registrant.new
      assert_nil reg.to_param
    end

    it "should be non nil for saved records" do
      reg = Factory.create(:step_1_registrant)
      assert_not_nil reg.to_param
    end

    it "should not be the record id" do
      reg = Factory.create(:step_1_registrant)
      assert_not_equal reg.id.to_s, reg.to_param
    end
  end

  describe "find_by_param" do
    it "should find record by url param" do
      reg = Factory.create(:step_1_registrant)
      assert_equal reg, Registrant.find_by_param(reg.to_param)
    end

    it "should raise AbandonedRecord when registrant is abandoned" do
      reg = Factory.create(:step_1_registrant, :abandoned => true)
      assert_raise Registrant::AbandonedRecord do
        Registrant.find_by_param(reg.to_param)
      end
    end

    it "should attach registrant to AbandonedRecord exception" do
      reg = Factory.create(:step_1_registrant, :abandoned => true)
      begin
        Registrant.find_by_param(reg.to_param)
      rescue Registrant::AbandonedRecord => exception
        assert_equal reg, exception.registrant
      end
    end
  end

  describe "localization" do
    it "finds the state localization" do
      reg = Factory.create(:step_5_registrant)
      loc = StateLocalization.find(:first, :conditions => {:state_id => reg.home_state_id, :locale => reg.locale})
      assert_equal loc, reg.localization
    end

    it "finds nothing if no home state or locale" do
      assert_nil Registrant.new.localization
      assert_nil Registrant.new(:home_state_id => 1).localization
      assert_nil Registrant.new(:locale => "en").localization
    end
  end

  describe "any step" do
    it "blanks party unless requires party" do
      reg = Factory.build(:maximal_registrant)
      stub(reg).requires_party? { false }
      assert reg.valid?, reg.errors.full_messages
      assert_nil reg.party
    end

    it "parses date of birth before validation" do
      reg = Factory.build(:step_1_registrant)
      reg.date_of_birth = "08/27/1978"
      assert reg.valid?
      assert_equal Date.parse("Aug 27, 1978"), reg.date_of_birth
      reg.date_of_birth = "5/3/1978"
      assert reg.valid?
      assert_equal Date.parse("May 3, 1978"), reg.date_of_birth
      reg.date_of_birth = "5-3-1978"
      assert reg.valid?
      assert_equal Date.parse("May 3, 1978"), reg.date_of_birth

      reg.date_of_birth = "1978/5/3"
      assert reg.valid?
      assert_equal Date.parse("May 3, 1978"), reg.date_of_birth
      reg.date_of_birth = "1978-5-3"
      assert reg.valid?
      assert_equal Date.parse("May 3, 1978"), reg.date_of_birth

      reg.date_of_birth = "2/30/1978"
      assert reg.invalid?
      assert reg.errors.on(:date_of_birth)
      assert_equal "2/30/1978", reg.date_of_birth_before_type_cast
      reg.date_of_birth = "5-3-78"
      assert reg.invalid?
      assert reg.errors.on(:date_of_birth)
      assert_equal "5-3-78", reg.date_of_birth_before_type_cast
      reg.date_of_birth = "May 3, 1978"
      assert reg.invalid?
      assert reg.errors.on(:date_of_birth)
      assert_equal "May 3, 1978", reg.date_of_birth_before_type_cast
    end
  end

  describe "step 1" do
    it "should require personal info" do
      assert_attribute_invalid_with(:step_1_registrant, :partner_id => nil)
      assert_attribute_invalid_with(:step_1_registrant, :locale => nil)
      assert_attribute_invalid_with(:step_1_registrant, :email_address => nil)
      assert_attribute_invalid_with(:step_1_registrant, :home_zip_code => nil, :home_state_id => nil)
      assert_attribute_invalid_with(:step_1_registrant, :home_zip_code => '00000')
      assert_attribute_invalid_with(:step_1_registrant, :date_of_birth => nil)
      assert_attribute_invalid_with(:step_1_registrant, :us_citizen => nil)
    end

    it "should limit number of simultaneous errors on home_zip_code" do
      reg = Factory.build(:step_1_registrant, :home_zip_code => nil)
      reg.invalid?

      assert_equal ["Required"], [reg.errors.on(:home_zip_code)].flatten
    end

    it "should check format of home_zip_code" do
      reg = Factory.build(:step_1_registrant, :home_zip_code => 'ABCDE')
      reg.invalid?

      assert_equal ["Use ZIP or ZIP+4"], [reg.errors.on(:home_zip_code)].flatten
    end

    it "should not require contact information" do
      assert_attribute_valid_with(:step_1_registrant, :name_title => nil)
      assert_attribute_valid_with(:step_1_registrant, :first_name => nil)
      assert_attribute_valid_with(:step_1_registrant, :last_name => nil)
      assert_attribute_valid_with(:step_1_registrant, :home_address => nil)
      assert_attribute_valid_with(:step_1_registrant, :home_city => nil)
    end

    it "should require email address is valid" do
      assert_attribute_invalid_with(:step_1_registrant, :email_address => "bogus")
      assert_attribute_invalid_with(:step_1_registrant, :email_address => "bogus@bogus")
      assert_attribute_invalid_with(:step_1_registrant, :email_address => "bogus@bogus.")
      assert_attribute_invalid_with(:step_1_registrant, :email_address => "@bogus.com")
    end

    it "should be ineligible when in state that doesn't participate" do
      reg = Factory.build(:step_1_registrant, :home_zip_code => '58001')  # North Dakota
      assert reg.valid?
      assert reg.ineligible?
      assert reg.ineligible_non_participating_state?
      reg = Factory.build(:step_1_registrant, :home_zip_code => '94101')  # California
      assert reg.valid?
      assert reg.eligible?
      assert !reg.ineligible_non_participating_state?
    end

    it "should be ineligible when too young" do
      reg = Factory.build(:step_1_registrant, :date_of_birth => 10.years.ago.to_date.to_s(:db))
      assert reg.valid?
      assert reg.ineligible?
      assert reg.ineligible_age?
      reg = Factory.build(:step_1_registrant, :date_of_birth => 20.years.ago.to_date.to_s(:db))
      assert reg.valid?
      assert reg.eligible?
      assert !reg.ineligible_age?
    end

    it "should be ineligible when not a citizen" do
      reg = Factory.build(:step_1_registrant, :us_citizen => false)
      assert reg.valid?
      assert reg.ineligible?
      assert reg.ineligible_non_citizen?
      reg = Factory.build(:step_1_registrant, :us_citizen => true)
      assert reg.valid?
      assert reg.eligible?
      assert !reg.ineligible_non_citizen?
    end
  end

  describe "step 2" do
    it "should require contact information" do
      assert_attribute_invalid_with(:step_2_registrant, :name_title => nil)
      assert_attribute_invalid_with(:step_2_registrant, :first_name => nil)
      assert_attribute_invalid_with(:step_2_registrant, :last_name => nil)
      assert_attribute_invalid_with(:step_2_registrant, :home_address => nil)
      assert_attribute_invalid_with(:step_2_registrant, :home_city => nil)
    end

    it "should not require state id" do
      assert_attribute_valid_with(:step_2_registrant, :state_id_number => nil)
    end

    it "requires mailing address fields if has_mailing_address" do
      assert_attribute_invalid_with(:step_2_registrant, :has_mailing_address => true, :mailing_address => nil)
      assert_attribute_invalid_with(:step_2_registrant, :has_mailing_address => true, :mailing_city => nil)
      assert_attribute_invalid_with(:step_2_registrant, :has_mailing_address => true, :mailing_state_id => nil)
      assert_attribute_invalid_with(:step_2_registrant, :has_mailing_address => true, :mailing_zip_code => nil)
    end

    it "should check format of mailing_zip_code" do
      reg = Factory.build(:step_2_registrant, :has_mailing_address => true, :mailing_zip_code => 'ABCDE')
      reg.invalid?

      assert_equal ["Use ZIP or ZIP+4"], [reg.errors.on(:mailing_zip_code)].flatten
    end

    it "should limit number of simultaneous errors on mailing_zip_code" do
      reg = Factory.build(:step_2_registrant, :has_mailing_address => true, :mailing_zip_code => nil)
      reg.invalid?

      assert_equal ["Required"], [reg.errors.on(:mailing_zip_code)].flatten
    end

    it "blanks mailing address fields unless has_mailing_address" do
      reg = Factory.build(:maximal_registrant, :has_mailing_address => false)
      assert reg.valid?, reg.errors.full_messages
      assert_nil reg.mailing_address
      assert_nil reg.mailing_unit
      assert_nil reg.mailing_city
      assert_nil reg.mailing_state_id
      assert_nil reg.mailing_zip_code
    end

    it "should require race but only for certain states" do
      reg = Factory.build(:step_2_registrant, :race => nil)
      stub(reg).requires_race? {true}
      assert reg.invalid?
      assert reg.errors.on(:race)
    end

    it "should not require race for some states" do
      reg = Factory.build(:step_2_registrant, :race => nil)
      stub(reg).requires_race? {false}
      assert reg.valid?
    end
  end

  describe "step 3" do
    it "should require valid state id" do
      assert_attribute_invalid_with(:step_3_registrant, :state_id_number => nil)

      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "NONE")
      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "none")

      assert_attribute_invalid_with(:step_3_registrant, :state_id_number => "123")
      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "1234")
      assert_attribute_invalid_with(:step_3_registrant, :state_id_number => "12345")
      assert_attribute_invalid_with(:step_3_registrant, :state_id_number => "123456")
      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "1234567")
      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "1"*42)
      assert_attribute_invalid_with(:step_3_registrant, :state_id_number => "1"*43)

      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "A234567")
      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "1-234567")
      assert_attribute_valid_with(  :step_3_registrant, :state_id_number => "*234567")
      assert_attribute_invalid_with(:step_3_registrant, :state_id_number => "$234567")
    end

    it "should upcase state id" do
      reg = Factory.build(:step_3_registrant, :state_id_number => "abc12345")
      assert reg.valid?
      assert_equal "ABC12345", reg.state_id_number
    end

    it "should format phone as ###-###-####" do
      reg = Factory.build(:step_3_registrant, :phone => "1234567890", :phone_type => "mobile")
      assert reg.valid?
      assert_equal "123-456-7890", reg.phone
    end

    it "should require previous name fields if change_of_name" do
      assert_attribute_invalid_with(:step_3_registrant, :change_of_name => true, :prev_name_title => nil)
      assert_attribute_invalid_with(:step_3_registrant, :change_of_name => true, :prev_first_name => nil)
      assert_attribute_invalid_with(:step_3_registrant, :change_of_name => true, :prev_last_name => nil)
    end

    it "requires previous address fields if change_of_address" do
      assert_attribute_invalid_with(:step_3_registrant, :change_of_address => true, :prev_address => nil)
      assert_attribute_invalid_with(:step_3_registrant, :change_of_address => true, :prev_city => nil)
      assert_attribute_invalid_with(:step_3_registrant, :change_of_address => true, :prev_state_id => nil)
      assert_attribute_invalid_with(:step_3_registrant, :change_of_address => true, :prev_zip_code => nil)
      assert_attribute_invalid_with(:step_3_registrant, :change_of_address => true, :prev_zip_code => '00000')
    end

    it "should not require attestations" do
      assert_attribute_valid_with(:step_3_registrant, :attest_true => nil)
    end

    it "should check format of prev_zip_code" do
      reg = Factory.build(:step_3_registrant, :change_of_address => true, :prev_zip_code => 'ABCDE')
      reg.invalid?

      assert_equal ["Use ZIP or ZIP+4"], [reg.errors.on(:prev_zip_code)].flatten
    end

    it "should limit number of simultaneous errors on prev_zip_code" do
      reg = Factory.build(:step_3_registrant, :change_of_address => true, :prev_zip_code => nil)
      reg.invalid?

      assert_equal ["Required"], [reg.errors.on(:prev_zip_code)].flatten
    end

    it "blanks previous name fields unless change_of_name" do
      reg = Factory.build(:maximal_registrant, :change_of_name => false)
      assert reg.valid?
      assert_nil reg.prev_name_title
      assert_nil reg.prev_first_name
      assert_nil reg.prev_middle_name
      assert_nil reg.prev_last_name
      assert_nil reg.prev_name_suffix
    end

    it "blanks previous address fields unless change_of_address" do
      reg = Factory.build(:maximal_registrant, :change_of_address => false)
      assert reg.valid?
      assert_nil reg.prev_address
      assert_nil reg.prev_unit
      assert_nil reg.prev_city
      assert_nil reg.prev_state_id
      assert_nil reg.prev_zip_code
    end

    it "should not require phone number" do
      reg = Factory.build(:step_3_registrant, :phone => "")
      assert reg.valid?
    end

    it "should require a valid phone number" do
      reg = Factory.build(:step_3_registrant, :phone_type => "Mobile")
      reg.phone = "1234567890"
      assert reg.valid?

      reg.phone = "123-456-7890"
      assert reg.valid?, reg.errors.full_messages

      reg.phone = "(123) 456 7890x123"
      assert reg.valid?

      reg.phone = "123.456.7890 ext 123"
      assert reg.valid?

      reg.phone = "asdfg"
      assert !reg.valid?

      reg.phone = "555-1234"
      assert !reg.valid?
    end
    
    it "should not require phone type when registrant does not provide phone" do
      reg = Factory.build(:step_3_registrant, :phone_type => "")
      assert reg.valid?
    end
    
    it "should require phone type when registrant provides phone" do
      reg = Factory.build(:step_3_registrant, :phone_type => "", :phone => "123-456-7890")
      assert !reg.valid?
    end
  end

  describe "step 5" do
    it "requires attestations" do
      assert_attribute_invalid_with(:step_5_registrant, :attest_true => "0")
    end
  end


  describe "home state name" do
    it "gets name for state" do
      new_york = GeoState['NY']
      reg = Factory.build(:step_1_registrant, :home_zip_code => "00501")
      assert_equal new_york.name, reg.home_state_name
    end
  end

  describe "states by abbreviation" do
    it "sets state by abbreviation" do
      new_york = GeoState['NY']
      reg = Factory.build(:step_1_registrant, :mailing_state_abbrev => "NY", :prev_state_abbrev => "NY")
      assert_equal new_york.id, reg.mailing_state_id
      assert_equal new_york.id, reg.prev_state_id
    end

    it "gets abbrev for state" do
      new_york = GeoState['NY']
      reg = Factory.build(:step_1_registrant, :mailing_state => new_york, :prev_state => new_york)
      assert_equal new_york.abbreviation, reg.mailing_state_abbrev
      assert_equal new_york.abbreviation, reg.prev_state_abbrev
    end
  end

  describe "state parties" do
    it "gets parties by locale when required" do
      reg = Factory.build(:step_2_registrant, :locale => 'en', :home_zip_code => '94101')
      state = reg.home_state
      reg.localization.update_attributes(:parties => %w(red green blue), :no_party => "black")
      assert_equal %w(red green blue black), reg.state_parties
      reg.locale = 'es'
      reg.instance_variable_set(:@localization, nil)  # registrant memoizes localization so we have to clear it
      reg.localization.update_attributes(:parties => %w(red green blue), :no_party => "black")
      assert_equal %w(red green blue black), reg.state_parties
    end

    it "gets no parties when not required" do
      reg = Factory.build(:step_2_registrant, :home_state => GeoState["PA"])
      assert_equal nil, reg.state_parties
    end

    it "included in validations when required by state" do
      reg = Factory.build(:step_2_registrant, :party => "bogus")
      stub(reg).requires_party? { true }
      stub(reg).state_parties { %w[Democratic Republican] }
      assert reg.invalid?
      assert reg.errors.on(:party)
    end

    it "not included in validations when not required by state" do
      reg = Factory.build(:step_2_registrant, :party => nil)
      stub(reg).requires_party? { false }
      assert reg.valid?
    end
  end

  describe "calculate age" do
    it "sets age at time of application" do
      assert_age 17, 17.years + 1.day
      assert_age 17, 17.years
      assert_age 16, 17.years - 1.day
    end

    it "sets age when record is saved" do
      reg = Factory.create(:step_1_registrant, :date_of_birth => (18.years + 1.day).ago.to_date.strftime("%m/%d/%Y"))
      assert_equal 18, reg.age
    end
  end

  def assert_age(years, born_on)
    reg = Factory.build(:step_1_registrant, :date_of_birth => born_on.ago.to_date.strftime("%m/%d/%Y"))
    reg.created_at = Time.now.utc   # TODO: change to a US time zone
    reg.calculate_age
    assert_equal years, reg.age
  end

  describe "set official party name" do
    it "uses party attribute when in English locale" do
      reg = Factory.build(:step_5_registrant, :locale => "en", :home_zip_code => "94103", :party => "Green")
      assert reg.valid?
      assert_equal "Green", reg.official_party_name
    end

    it "maps Spanish party name to English" do
      reg = Factory.build(:step_5_registrant, :locale => "es", :home_zip_code => "94103", :party => "Verde")
      assert reg.valid?
      assert_equal "Green", reg.official_party_name
    end

    it "handles Decline to State" do
      reg = Factory.build(:step_5_registrant, :locale => "en", :home_zip_code => "94103", :party => "Decline to State")
      assert reg.valid?
      assert_equal "None", reg.official_party_name
    end

    it "handles Decline to State in Spanish" do
      reg = Factory.build(:step_5_registrant, :locale => "es", :home_zip_code => "94103", :party => "Se niega a declarar")
      assert reg.valid?
      assert_equal "None", reg.official_party_name
    end

    it "sets to None for states which do not require party" do
      reg = Factory.build(:maximal_registrant, :locale => "en", :home_zip_code => "02134", :party => nil)
      assert !reg.home_state.requires_party?
      assert reg.valid?
      assert_equal "None", reg.official_party_name
    end
  end

  describe "under_18_instructions_for_home_state" do
    it "shows instructions with state name and localized rule" do
      reg = Factory.build(:step_1_registrant)
      text = reg.under_18_instructions_for_home_state
      assert_match Regexp.compile(reg.home_state.name), text
      assert_match Regexp.compile(reg.localization.sub_18), text
    end
  end

  describe "at least step N" do
    it "should say whether step is at least N" do
      reg = Factory.build(:step_2_registrant)
      assert reg.at_least_step_1?
      assert reg.at_least_step_2?
      assert !reg.at_least_step_3?

    end
  end

  describe "#abandon!" do
    it "should mark as abandoned" do
      reg = Factory.create(:step_1_registrant)
      assert !reg.abandoned?
      reg.abandon!
      assert reg.abandoned?
    end
    
    it "should clear sensitive data" do
      reg = Factory.create(:step_4_registrant)
      assert_not_nil reg.state_id_number
      reg.abandon!
      assert_nil reg.state_id_number
    end
  end

  describe "stale records" do
    it "should become abandoned" do
      stale_rec = Factory.create(:step_4_registrant, :updated_at => (Registrant::STALE_TIMEOUT + 10).seconds.ago)
      fresh_rec = Factory.create(:step_4_registrant, :updated_at => (Registrant::STALE_TIMEOUT - 10).seconds.ago)
      complete_rec = Factory.create(:maximal_registrant, :updated_at => (Registrant::STALE_TIMEOUT + 10).seconds.ago)
      
      Registrant.abandon_stale_records
      
      assert stale_rec.reload.abandoned?
      assert !fresh_rec.reload.abandoned?
      assert !complete_rec.reload.abandoned?
    end
  end

  describe "PDF" do
    describe "template path" do
      it "determined by state and locale" do
        registrant = Factory.build(:maximal_registrant, :home_zip_code => "00501", :locale => 'es')
        assert_match(/_es_ny\.pdf/, registrant.nvra_template_path)
      end
    end

    describe "merge" do
      before(:each) do
        @registrant = Factory.create(:maximal_registrant)
        stub(@registrant).merge_pdf { `touch #{@registrant.pdf_file_path}` }
      end

      it "generates PDF with merged data" do
        `rm -f #{@registrant.pdf_file_path}`
        assert_difference(%Q{Dir[File.join(RAILS_ROOT, "pdf/#{@registrant.bucket_code}/*")].length}) do
          @registrant.generate_pdf
        end
      end

      it "returns PDF if already exists" do
        `touch #{@registrant.pdf_file_path}`
        assert_no_difference(%Q{Dir[File.join(RAILS_ROOT, "pdf/#{@registrant.bucket_code}/*")].length}) do
          @registrant.generate_pdf
        end
      end

      it "sets pdf_ready if file exists or is generated" do
        assert !@registrant.pdf_ready?
        @registrant.generate_pdf
        assert @registrant.pdf_ready?
      end

      after do
        `rm #{@registrant.pdf_file_path}`
        `rmdir #{File.dirname(@registrant.pdf_file_path)}`
      end
    end
  end

  describe "CSV" do
    it "renders minimal CSV" do
      reg = Factory.build(:step_1_registrant)
      assert_equal [ "Step 1",
                     "English",
                     reg.date_of_birth.to_s(:month_day_year),
                     reg.email_address,
                     "No",
                     "Yes",
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     "PA",
                     "15215",
                     "No",
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     nil,
                     "Yes",
                     "Yes",
                     nil,
                     nil,
                     "No",  # volunteer
                     nil,
                     nil], 
                  reg.to_csv_array
    end

    it "renders maximal CSCV" do
      reg = Factory.create(:maximal_registrant)
      reg.update_attributes :home_zip_code => "94110", :party => "Democratic"
      assert_equal [ "Complete",
                     "English",
                     reg.date_of_birth.to_s(:month_day_year),
                     "citizen@example.com",
                     "No",
                     "Yes",
                     "Mrs.",
                     "Susan",
                     "Brownell",
                     "Anthony",
                     "III",
                     "123 Civil Rights Way",
                     "Apt 2",
                     "West Grove",
                     "CA",
                     "94110",
                     "Yes",
                     "10 Main St",
                     "Box 5",
                     "Adams",
                     "AL",
                     "02135",
                     "Democratic",
                     "White (not Hispanic)",
                     "123-456-7890",
                     "Mobile",
                     "Yes",
                     "Yes",
                     "blue",
                     "fido",
                     "Yes",
                     nil,
                     reg.created_at && reg.created_at.to_s(:month_day_year)
                     ],
                 reg.to_csv_array
    end
    
    it "renders ineligible CSV" do
      reg = Factory.create(:step_1_registrant, :us_citizen => false)
      assert_equal "Not a US citizen", reg.to_csv_array[-2]
    end
    
    it "has a CSV header" do
      assert_not_nil Registrant::CSV_HEADER

      reg = Factory.build(:maximal_registrant)
      assert_equal Registrant::CSV_HEADER.size, reg.to_csv_array.size
    end
  end

  describe "wrapping up" do
    it "should transition to complete state" do
      reg = Factory.create(:step_5_registrant)
      mock(reg).complete_registration
      reg.wrap_up
      assert reg.reload.complete?
    end

    it "clears out sensitive data" do
      reg = Factory.create(:step_5_registrant, :state_id_number => "1234567890")
      stub(reg).generate_pdf                  # avoid messy out-of-band action in tests
      stub(reg).deliver_confirmation_email    # avoid messy out-of-band action in tests
      stub(reg).enqueue_reminder_emails       # avoid messy out-of-band action in tests
      reg.complete_registration
      assert_nil reg.state_id_number
    end

    it "sets system locale using registrant's locale" do
      reg = Factory.create(:step_5_registrant, :state_id_number => "1234567890")
      stub(reg).generate_pdf                  # avoid messy out-of-band action in tests
      stub(reg).deliver_confirmation_email    # avoid messy out-of-band action in tests
      stub(reg).enqueue_reminder_emails       # avoid messy out-of-band action in tests

      reg.locale = 'en'
      reg.complete_registration
      assert_equal :en, I18n.locale

      reg.locale = 'es'
      reg.complete_registration
      assert_equal :es, I18n.locale
    end
  end

  describe "deliver_confirmation_email" do
    it "should deliver an email" do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        Factory.create(:maximal_registrant).deliver_confirmation_email
      end
    end
  end

  describe "reminder emails" do
    it "on incomplete registrant, it should be 0" do
      assert_equal 0, Factory.build(:step_4_registrant).reminders_left
    end

    it "should know how many reminder emails are left" do
      assert_equal Registrant::REMINDER_EMAILS_TO_SEND, Factory.build(:maximal_registrant, :reminders_left => Registrant::REMINDER_EMAILS_TO_SEND).reminders_left
    end

    it "should queue series of reminder emails" do
      reg = Factory.create(:maximal_registrant, :reminders_left => 0)
      assert_difference('Delayed::Job.count', 1) do
        reg.enqueue_reminder_emails
        assert_equal Registrant::REMINDER_EMAILS_TO_SEND, reg.reload.reminders_left
      end
    end

    describe "delivery" do
      it "should send an email" do
        assert_difference('ActionMailer::Base.deliveries.size', 1) do
          reg = Factory.create(:maximal_registrant, :reminders_left => 1)
          reg.deliver_reminder_email
        end
      end

      it "should not send an email if no reminders left" do
        assert_no_difference('ActionMailer::Base.deliveries.size') do
          reg = Factory.create(:maximal_registrant, :reminders_left => 0)
          reg.deliver_reminder_email
        end
      end

      it "should decrement reminders left" do
        reg = Factory.create(:maximal_registrant, :reminders_left => 3)
        reg.deliver_reminder_email
        assert_equal 2, reg.reload.reminders_left
      end

      it "should enqueue another reminder email" do
        assert_difference('Delayed::Job.count', 1) do
          reg = Factory.create(:maximal_registrant, :reminders_left => 3)
          reg.deliver_reminder_email
        end
      end

      it "should not enqueue another reminder email if on last email" do
        assert_no_difference('Delayed::Job.count') do
          reg = Factory.create(:maximal_registrant, :reminders_left => 1)
          reg.deliver_reminder_email
        end
      end

      it "should log an error to HopToad if something blows up" do
        reg = Factory.create(:maximal_registrant, :reminders_left => 1)
        stub(reg).valid? { false }

        stub(HoptoadNotifier).notify
        reg.deliver_reminder_email
        HoptoadNotifier.should have_received.notify(is_a(Hash))
      end
    end
  end

  describe "shared_text" do
    describe "when complete" do
      it "says I voted" do
        reg = Factory.build(:completed_registrant)
        assert_match Regexp.new(Regexp.escape("I+just+registered+to+vote+and+you+can+too")), reg.status_text
      end
    end
    describe "when under 18" do
      it "says registering is easy" do
        reg = Factory.build(:under_18_finished_registrant)
        assert_match Regexp.new(Regexp.escape("Make+sure+you+register+to+vote")), reg.status_text
      end
    end
  end

  describe "tell-a-friend emails" do
    attr_accessor :reg
    before(:each) do
      @reg = Factory.build( :completed_registrant,
                            :name_title => "Mr.",
                            :first_name => "John", :middle_name => "Queue", :last_name => "Public",
                            :name_suffix => "Jr.",
                            :email_address => "jqp@example.com" )
    end

    describe "attributes for form fields have smart defaults" do
      it "has tell_from" do
        assert_equal "John Public", reg.tell_from
        reg.tell_from = "J. Public"
        assert_equal "J. Public", reg.tell_from
      end

      it "has tell_email" do
        assert_equal "jqp@example.com", reg.tell_email
        reg.tell_email = "jqp@gmail.com"
        assert_equal "jqp@gmail.com", reg.tell_email
      end

      it "has tell_subject" do
        assert_equal "I just registered to vote and you should too", reg.tell_subject
        reg.tell_subject = "This is super cool"
        assert_equal "This is super cool", reg.tell_subject
      end

      it "has tell_subject default for under 18" do
        reg = Factory.build(:under_18_finished_registrant)
        assert_equal "Register to vote!", reg.tell_subject
        reg.tell_subject = "This is super cool"
        assert_equal "This is super cool", reg.tell_subject
      end
    end

    describe "enqueue emails when registrant has valid tell-a-friend params" do
      before(:each) do
        @tell_params = {
          :telling_friends => true,
          :tell_from => "Bob Dobbs",
          :tell_email => "bob@example.com",
          :tell_recipients => "arnold@example.com, obo@example.com, slack@example.com",
          :tell_subject => "Register to vote the easy way",
          :tell_message => "I registered to vote and you can too."
        }
      end

      it "enqueues email when valid" do
        reg.attributes = @tell_params
        assert_difference "Delayed::Job.count" do
          assert reg.valid?
        end
      end

      it "does not enqueue when invalid" do
        reg.attributes = @tell_params.merge(:tell_recipients => "")
        assert_difference "Delayed::Job.count", 0 do
          assert reg.invalid?
        end
      end

      it "sends one email per recipient" do
        mock(Notifier).deliver_tell_friends(anything).times(3)
        Registrant.deliver_tell_friends_emails(@tell_params)
      end
    end
  end

  def assert_attribute_invalid_with(model, attributes)
    reg = Factory.build(model, attributes)
    reg.invalid?
    assert attributes.keys.any? { |attr_name| reg.errors.on(attr_name) }
  end

  def assert_attribute_valid_with(model, attributes)
    reg = Factory.build(model, attributes)
    assert reg.valid?
  end
end
