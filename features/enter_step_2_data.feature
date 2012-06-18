Feature: Step 2
  In order to provide personal information
  As a registrant
  I want to enter name, address
  
    Scenario: first visit
      Given I have completed step 1
      When I go to the step 2 page
       And I select "Mr." from "title"
       And I fill in "first" with "John"
       And I fill in "last" with "Public"
       And I fill in "address" with "123 Market St."
       And I fill in "city" with "Pittsburgh"
       And I press "registrant_submit"
      Then I should see "Additional Registration Information"

    Scenario: default mailing state to home state
      Given I have completed step 1
      When I go to the step 2 page
      Then I should see "Pennsylvania" in select box "registrant_mailing_state_abbrev"

    Scenario: fields for a washington state resident
      Given the following partner exists:
        | organization   | rtv_sms_opt_in | partner_sms_opt_in | rtv_email_opt_in | partner_email_opt_in |
        | Opt-in Partner | true           | true               | true             | true                 |  
      And I have completed step 1 as a resident of "Washington" state from that partner
      When I go to the step 2 page
      Then I should see a field for "Phone"
      And I should see a field for "Type"
      And I should see a checkbox for "Send me txt messages from Rock the Vote"
      And I should see a checkbox for "Send me txt messages from Opt-in Partner"
      And I should see a checkbox for "Receive emails from Rock the Vote"
      And I should see a checkbox for "Receive emails from Opt-in Partner"
      And I should see a field for "I have a valid WA state ID or driver's license"
      And I should see a field for "I do not have a valid WA state ID or driver's license"
      
    @wip @javascript
    Scenario: Modal continue actions for a washington state resident
      Given I have completed step 1 as a resident of "Washington" state
      When I go to the step 2 page
      Then I should see a disabled button for "Next Step >"
      When I check "I do not have a valid WA state ID or driver's license"
      Then I should see an enabled button for "Next Step >"
      When I check "I have a valid WA state ID or driver's license"
      Then I should see "You may be eligible to finish your registration using the state of Washington's paperless voter registration system."
      And I should see a button for "Let me finish my paperless registration with the state of Washington." 
      And I should see a button for "Finish my registration with Rock the Vote."
      
    @wip-l @javascript
    Scenario: WA resident selects to finish paperless registration with the state of Washington
    
    @wip-l @javascript
    Scenario: WA resident selects to finish registration with Rock the Vote
    