require File.dirname(__FILE__) + '/../spec_helper'

describe Partner do
  describe "#primary?" do
    it "is true for primary partner" do
      assert Partner.find(Partner.default_id).primary?
    end

    it "is false for non-primary partner" do
      assert !Factory.build(:partner).primary?
    end
  end

  describe "#logo_image_url" do
    it "is saved for non-primary partner" do
      url = "http://example.com/logo.jpg"
      assert_equal url, Factory.create(:partner, :logo_image_url => url).logo_image_url
    end
    it "is local for primary partner" do
      assert_match /^reg/, Partner.find(Partner.default_id).logo_image_url
    end
  end

  describe "CSV" do
    it "can generate CSV of all registrants" do
      partner = Factory.create(:partner)
      registrants = []
      3.times { registrants << Factory.create(:maximal_registrant, :partner => partner) }
      registrants << Factory.create(:step_1_registrant, :partner => partner)

      other_partner = Factory.create(:partner)
      registrants << Factory.create(:maximal_registrant, :partner => other_partner)

      csv = FasterCSV.parse(partner.generate_registrants_csv)
      assert_equal 5, csv.length # including header
      assert_equal Registrant::CSV_HEADER, csv[0]
      assert_equal registrants[0].to_csv_array, csv[1]
      assert_equal registrants[1].to_csv_array, csv[2]
      assert_equal registrants[2].to_csv_array, csv[3]
      assert_equal registrants[3].to_csv_array, csv[4]
    end
  end

  describe "registration statistics" do
    describe "by state" do
      it "should tally registrants by state" do
        partner = Factory.create(:partner)
        3.times do
          reg = Factory.create(:maximal_registrant, :partner => partner)
          reg.update_attributes(:home_zip_code => "32001", :party => "Decline to State")
        end
        2.times do
          reg = Factory.create(:maximal_registrant, :partner => partner)
          reg.update_attributes!(:home_zip_code => "94101", :party => "Decline to State")
        end
        stats = partner.registration_stats_state
        assert_equal 2, stats.length
        assert_equal "Florida", stats[0][:state_name]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "California", stats[1][:state_name]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "only uses completed/step_5 registrations for stats" do
        partner = Factory.create(:partner)
        3.times do
          reg = Factory.create(:maximal_registrant, :partner => partner)
          reg.update_attributes(:home_zip_code => "32001", :party => "Decline to State")
        end
        3.times do
          reg = Factory.create(:step_4_registrant, :partner => partner)
          reg.update_attributes(:home_zip_code => "32001", :party => "Decline to State")
        end
        2.times do
          reg = Factory.create(:step_5_registrant, :partner => partner)
          reg.update_attributes(:home_zip_code => "94101", :party => "Decline to State")
        end
        stats = partner.registration_stats_state
        assert_equal 2, stats.length
        assert_equal "Florida", stats[0][:state_name]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "California", stats[1][:state_name]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end
    end

    describe "by race" do
      it "should tally registrants by race" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Hispanic") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Multi-racial") }
        stats = partner.registration_stats_race
        assert_equal 2, stats.length
        assert_equal "Hispanic", stats[0][:race]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Multi-racial", stats[1][:race]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "should treat race names in different languages as equivalent" do
        partner = Factory.create(:partner)
        4.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Hispanic") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :race => "es Hispanic", :locale => "es") }
        3.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Multi-racial") }
        1.times { Factory.create(:maximal_registrant, :partner => partner, :race => "es Multi-racial", :locale => "es") }
        stats = partner.registration_stats_race
        assert_equal 2, stats.length
        assert_equal "Hispanic", stats[0][:race]
        assert_equal 6, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Multi-racial", stats[1][:race]
        assert_equal 4, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "doesn't need both English and Spanish results" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Hispanic") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :race => "es Multi-racial", :locale => "es") }
        stats = partner.registration_stats_race
        assert_equal 2, stats.length
        assert_equal "Hispanic", stats[0][:race]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Multi-racial", stats[1][:race]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "when the race is blank it is called 'Unknown'" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :race => "") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Multi-racial") }
        stats = partner.registration_stats_race
        assert_equal 2, stats.length
        assert_equal "Unknown", stats[0][:race]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Multi-racial", stats[1][:race]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "only uses completed/step_5 registrations for stats" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :race => "Hispanic") }
        2.times { Factory.create(:step_4_registrant, :partner => partner, :race => "Hispanic") }
        2.times { Factory.create(:step_5_registrant, :partner => partner, :race => "Multi-racial") }
        stats = partner.registration_stats_race
        assert_equal 2, stats.length
        assert_equal "Hispanic", stats[0][:race]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Multi-racial", stats[1][:race]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end
    end

    describe "by gender" do
      it "should tally registrants by gender based on name_title" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Mr.") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Ms.") }
        stats = partner.registration_stats_gender
        assert_equal 2, stats.length
        assert_equal "Male", stats[0][:gender]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Female", stats[1][:gender]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "should treat race names in different languages as equivalent" do
        partner = Factory.create(:partner)
        4.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Mr.") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Sr.") }
        3.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Ms.") }
        1.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Sra.") }
        stats = partner.registration_stats_gender
        assert_equal 2, stats.length
        assert_equal "Male", stats[0][:gender]
        assert_equal 6, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Female", stats[1][:gender]
        assert_equal 4, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "doesn't need both English and Spanish results" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Mr.") }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Sra.") }
        stats = partner.registration_stats_gender
        assert_equal 2, stats.length
        assert_equal "Male", stats[0][:gender]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Female", stats[1][:gender]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end

      it "only uses completed/step_5 registrations for stats" do
        partner = Factory.create(:partner)
        3.times { Factory.create(:maximal_registrant, :partner => partner, :name_title => "Mr.") }
        2.times { Factory.create(:step_4_registrant, :partner => partner, :name_title => "Mr.") }
        2.times { Factory.create(:step_5_registrant, :partner => partner, :name_title => "Sra.") }
        stats = partner.registration_stats_gender
        assert_equal 2, stats.length
        assert_equal "Male", stats[0][:gender]
        assert_equal 3, stats[0][:registrations_count]
        assert_equal 0.6, stats[0][:registrations_percentage]
        assert_equal "Female", stats[1][:gender]
        assert_equal 2, stats[1][:registrations_count]
        assert_equal 0.4, stats[1][:registrations_percentage]
      end
    end

    describe "by registration date" do
      it "should tally registrants by date bucket" do
        partner = Factory.create(:partner)
        8.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.hours.ago) }
        5.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.days.ago) }
        4.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.weeks.ago) }
        2.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.months.ago) }
        1.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.years.ago) }
        stats = partner.registration_stats_completion_date
        assert_equal  8, stats[:day_count]
        assert_equal 13, stats[:week_count]
        assert_equal 17, stats[:month_count]
        assert_equal 19, stats[:year_count]
        assert_equal 20, stats[:total_count]
      end

      it "should not include incomplete registrations in counts" do
        partner = Factory.create(:partner)
        8.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.hours.ago) }
        8.times { Factory.create(:step_4_registrant,  :partner => partner, :created_at => 2.hours.ago) }
        stats = partner.registration_stats_completion_date
        assert_equal  8, stats[:day_count]
      end

      it "should show percent complete" do
        partner = Factory.create(:partner)
        8.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.hours.ago) }
        8.times { Factory.create(:step_4_registrant,  :partner => partner, :created_at => 2.hours.ago) }
        stats = partner.registration_stats_completion_date
        assert_equal 0.5, stats[:percent_complete]
      end

      it "should not include :initial state registrants in calculations" do
        partner = Factory.create(:partner)
        5.times { Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.days.ago) }
        5.times { Factory.create(:step_4_registrant,  :partner => partner, :created_at => 2.days.ago) }
        5.times { Factory.create(:step_1_registrant,  :partner => partner, :created_at => 2.days.ago, :status => :initial) }
        stats = partner.registration_stats_completion_date
        assert_equal   5, stats[:week_count]
        assert_equal 0.5, stats[:percent_complete]
      end
      
      it "should only include data for this partner" do
        partner = Factory.create(:partner)
        other_partner = Factory.create(:partner)
        Factory.create(:maximal_registrant, :partner => partner, :created_at => 2.days.ago)
        Factory.create(:step_4_registrant,  :partner => partner, :created_at => 2.days.ago)
        Factory.create(:maximal_registrant, :partner => other_partner, :created_at => 2.days.ago)
        stats = partner.registration_stats_completion_date
        assert_equal   1, stats[:week_count]
        assert_equal 0.5, stats[:percent_complete]
      end
    end
  end
end

