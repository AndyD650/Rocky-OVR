Feature: Step 3
  In order to provide id and changes
  As a registrant
  I want to enter id and

  Background:

    Scenario: enter basic data
     Given I have completed step 2
      When I go to the step 3 page
       And I fill in "ID Number" with "1234"
       And I check "Send me txt messages"
       And I press "registrant_submit"
      Then I should see "Stay Informed and Take Action"


    # Step 3 is SMS, Step 4 is email and volunteer
    Scenario: User sees RTV SMS opt-in options for partner 1
      Given I have completed step 2
      When I go to the step 3 page
      And I should see a checkbox for "Send me txt messages from Rock the Vote"
      When I check "Send me txt messages from Rock the Vote"
      And I fill in "ID Number" with "NONE"
      And I press "registrant_submit"
      Then I should be signed up for "opt_in_sms"
      And I should not be signed up for "partner_opt_in_sms"

    @passing
    Scenario: User sees RTV and partner SMS opt-in options for partner configured to have rtv and partner opt-ins, and checks partner-sms
      Given the following partner exists:
        | organization   | rtv_sms_opt_in | partner_sms_opt_in |
        | Opt-in Partner | true           | true               |        
      And I have completed step 2 from that partner
      When I go to the step 3 page
      Then I should see a checkbox for "Send me txt messages from Rock the Vote"
      And I should see a checkbox for "Send me txt messages from Opt-in Partner"
      When I check "Send me txt messages from Opt-in Partner"
      When I uncheck "Send me txt messages from Rock the Vote"
      And I fill in "ID Number" with "NONE"
      And I press "registrant_submit"
      Then I should be signed up for "partner_opt_in_sms"
      And I should not be signed up for "opt_in_sms"
    
    @passing
    Scenario: User sees only RTV opt-in options for partner configured to have rtv opt-ins and checks rtv-sms
      Given the following partner exists:
        | organization   | rtv_sms_opt_in | partner_sms_opt_in  |
        | Opt-in Partner | true           | false               |        
      And I have completed step 2 from that partner
      When I go to the step 3 page
      Then I should see a checkbox for "Send me txt messages from Rock the Vote"
      And I should not see a checkbox for "Send me txt messages from Opt-in Partner"
      When I check "Send me txt messages from Rock the Vote"
      And I fill in "ID Number" with "NONE"
      And I press "registrant_submit"
      Then I should not be signed up for "partner_opt_in_sms"
      And I should be signed up for "opt_in_sms"

    @passing
    Scenario: User cannot sign up for opt_in_sms if phone isn't provided
      Given the following partner exists:
        | organization   | rtv_sms_opt_in | partner_sms_opt_in  |
        | Opt-in Partner | true           | false               |        
      And I have completed step 2 from that partner
      When I go to the step 3 page
      Then I should see a checkbox for "Send me txt messages from Rock the Vote"
      And I should not see a checkbox for "Send me txt messages from Opt-in Partner"
      When I check "Send me txt messages from Rock the Vote"
      And I fill in "ID Number" with "NONE"
      And I fill in "Phone" with ""
      And I press "registrant_submit"
      Then I should see "Additional Registration Information"
      And I should see "Required if receiving TXT"


    Scenario: User sees only partner opt-in options for partner configured to have partner opt-ins and checks and partner-volunteer
      Given the following partner exists:
        | organization   | rtv_sms_opt_in | partner_sms_opt_in  |
        | Opt-in Partner | false          | true                |        
      And I have completed step 2 from that partner
      When I go to the step 3 page
      Then I should not see a checkbox for "Send me txt messages from Rock the Vote"
      And I should see a checkbox for "Send me txt messages from Opt-in Partner"
      When I check "Send me txt messages from Opt-in Partner"
      And I fill in "ID Number" with "NONE"
      And I press "registrant_submit"
      Then I should be signed up for "partner_opt_in_sms"
      And I should not be signed up for "opt_in_sms"

    Scenario: User sees no opt-in options for partner configured without opt-ins
      Given the following partner exists:
        | organization   | rtv_sms_opt_in | partner_sms_opt_in  |
        | Opt-in Partner | false          | false               |        
      And I have completed step 2 from that partner
      When I go to the step 3 page
      Then I should not see a checkbox for "Send me txt messages from Rock the Vote"
      And I should not see a checkbox for "Send me txt messages from Opt-in Partner"
      When I fill in "ID Number" with "NONE"
      And I press "registrant_submit"
      Then I should not be signed up for "partner_opt_in_sms"
      And I should not be signed up for "opt_in_sms"

    @passing
    Scenario Outline: enter basic data for <state> registrant
      Given I have completed step 2 as a resident of "<state>" state     
      When I go to the step 3 page
      Then I should not see a checkbox for "Send me txt messages from Rock the Vote"
      And I should see a button for "Review Application"
      When I fill in "ID Number" with "1234"
      And I fill in "Address" with "123 Market St."
      And I fill in "City" with "Pittsburgh"
      And I fill in "registrant_survey_answer_1" with "o hai"
      And I fill in "registrant_survey_answer_2" with "kthxbye"
      And I select "Other" from "registrant_race"
      And I select "<optional_party_field>" from "<optional_party_value>"
      And I press "registrant_submit"
      Then I should see "Confirm"

      Examples:
        | state      | optional_party_field | optional_party_value |
        | Washington | Other                | registrant_race      |
        | Arizona    | Libertarian          | registrant_party     |
        | California | Green                | registrant_party     |
        | Colorado   | Green                | registrant_party     |
        | Nevada     | Other                | registrant_race      |