Feature: Canvasser UI

  So that registrations can be attributed to a canvassing shift
  As a canvasser
  I want to start a new canvassing on my browser

    @passing
    Scenario: Canvasser Landing Page
      When I go to the start shift page
      Then I should not see the canvassing notice bar
      And I should see "Canvasser Web Portal"
      And I should see "Select Partner"
      And I should see a field for "partner"

    @passing
    Scenario: Select Parter
      Given the following partner exists:
        | id  | name           | organization        |
        | 123 | Partner Name 2 | Organization Name 2 |
      And the following partner exists:
        | id  | name           | organization        |
        | 124 | Partner Name 3 | Organization Name 3 |

      When I go to the start shift page
      Then "partner" select box should contain "Organization Name 2"
      And "partner" select box should contain "Organization Name 3"
      When I select "Organization Name 2" from "partner"
      And I click "Next"
      Then I should be on the shift creation page
      And the "#partner_id" hidden field should be "123"

    @passing
    Scenario: Create Shift Required Fields
      Given the following partner exists:
        | id  | name           | organization        |
        | 123 | Partner Name 2 | Organization Name 2 |
      When I go to the shift creation page for partner="123"
      And I click "Start Shift"
      Then the "#partner_id" hidden field should be "123"
      And the "First Name" field should be required
      And the "Last Name" field should be required
      And the "Phone" field should be required
      And the "Email" field should be required
      And the "Location" field should be required

    @passing
    Scenario: Create Shift Formatted Fields
      Given the following partner exists:
        | id  | name           | organization        |
        | 123 | Partner Name 2 | Organization Name 2 |
      When I go to the shift creation page for partner="123"
      And I fill in "Phone" with "123"
      And I fill in "Email" with "abc"
      And I click "Start Shift"
      Then the "#partner_id" hidden field should be "123"
      And the "Phone" field should have a format error
      And the "Email" field should have a format error

    @passing
    Scenario: Create Shift
      Given the following partner exists:
        | id  | name           | organization        |
        | 123 | Partner Name 2 | Organization Name 2 |
      When I go to the shift creation page for partner="123"
      And I fill in "First Name" with "Test"
      And I fill in "Last Name" with "Test"
      And I fill in "Phone" with "123-123-1234"
      And I fill in "Email" with "abc@def.ghi"
      And I select "Default Location" from "Location"
      And I click "Start Shift"
      Then I should be on the shift status page
      And I should see "0 completed registration(s)"
      And I should see "0 via paper"
      And I should see "0 via api"
      And I should see "0 abandoned registration(s)"
      And I should see a button for "Start new registration"
      And I should see a button for "End Shift"

    @passing
    Scenario: Register via Shift
      Given that I started a new shift for partner="123"
      When I go to the shift status page
      Then I should see "0 completed registration(s)"
      And I follow "Start new registration"
      And show the page
      Then I should be on a new registration page for partner="123"
      And I should see the canvassing notice bar
      And I fill in "Email" with "test@rtv.org"
      And I fill in "ZIP Code" with "19000"
      And I click "Next"
      Then I should see "Your Basic Info"
      And I should see the canvassing notice bar

    @wip
    Scenario: Complete shift registration
      Given that I started a new shift
      When I complete a PA paper registration for that shift
      Then I should see the canvassing notice bar with a link to the shift status page

    Scenario: Complete shift registration
      Given that I started a new shift
      When I complete a PA online registration for that shift
      Then I should see the canvassing notice bar with a link to the shift status page

    Scenario: Complete shift registration
      Given that I started a new shift
      When I complete a PA paper fallback registration for that shift
      Then I should see the canvassing notice bar with a link to the shift status page

    Scenario: Canvassing status
      Given that I started a new shift with "3" complete registrations and "2" abandoned registrations
      When I go to the shift status page
      Then I should see "3 registrations completed"
      And I should see "2 registrations abandoned"

    Scenario: End Shift
      Given that I started a new shift with "3" complete registrations and "2" abandoned registrations
      When I go to the shift status page
      And I click "End Shift"
      Then I should be on the start shift page
      And I should see the shift end message
