module AbrStateMethods::TX
  
  def self.included(klass)
    klass.extend(AbrStateMethods::ClassMethods)
    klass.add_pdf_fields({
      "Suffix Jr Sr III etc": {
        method: "name_suffix"
      },
      "First Name": {
        method: "first_name"
      },
      "Middle Initial": {}, #TODO- fill this in from the middle name
      "2 Residence Address See back of this application for instructions": {
        method: "address"
      },
      "City TX": {
        method: "city"
      },
      "ZIP Code": {
        method: "zip"
      },
      "3 Mail my ballot to If mailing address differs from residence address please complete Box  7": {}
      "State": {},
      "ZIP Code_2": {},
      "4 Date of Birth mmddyyyy Optional Contact Information Optional Please list phone number andor email address  Used in case our office has questions": {
        method: "email" 
        #add phone number field if possible
      },
      "Date of Birth mmddyyyy Optional": {}, #month only - max: 2
      "Annual Application": {
        options: ["Off", "On"],
        value: "Off"
      },
      "Republican Primary": {
        options: ["Off", "On"],
        value: "Off"
      },
      "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below": {},
      "If you assisted the applicant in completing this application in the applicants presence or emailedmailed or faxed the application on behalf of the applicant please check this box as an Assistant and sign below": {},
      "Refer to Instructions on back for clarification": {},
      "Day of date of birth": {}, #day only - max: 2
      "Year of date of birth": {}, #year only - max: 4
      "Month of date you can begin to receive mail at this address": {},
      "Day of date you can begin to receive mail at this address": {},
      "Year of date you can begin to receive mail at this address": {},
      "Month of date of return to residence address": {},
      "Day of date of return to residence address": {},
      "Year of date of return to residence address": {},
      "Reason for voting by mail:": {
        options: ["65 years of age or older. (Complete box #6a", "Confinement to jail. (Complete box #6b)", "Disability. (Complete box #6a", "Expected absence from the county. (Complete box #6b and box #8"]
      },
      "If requesting this ballot be mailed to a different address (other than residense), indicate where the ballot will be mailed": {
        options: ["Off", "Address of the jail", "Address outside the county", "Hospital", "Mailing address as listed on my voter registration certificate", "Nursing home, assisted living facility, or long term care facility", "Relative; relationship", "Retirement center"]
      },
      #Date of signature
      "City of witness": {},
      "Zip code of witness": {},
      "State of witness": {},
      "Street address of witness": {},
      "Apartment number (if applicable) of witness": {},
      "Select only if your 65 or older or live with a disability:": {
        options: ["Any resulting runoff", "May election", "November election", "Off", "Other"]
      },
      "Select only if absent from the county or confined to jail:": {
        options: ["Any resulting runoff", "May election", "November election", "Off", "Other"]
      },
      "name": {
        method: "full_name" #return address
      },
      "address": {
        method: "address" #return address
      },
      "city and state": {}, #return address: city, state zip
      "To: Early Voting Clerk's address": {}, #is there a way to automatically fill in the address of the nearest voting clerk based on the location they entered?
      "To: Early Voting Clerk's state": {}, #city, state zip
      "1 Last Name Please print information": {
        method: "last_name"
      },
      "Relative; relationship": {},
      "early voting clerks fax": {}, #only needed if applicant wants to fax their PDF application
      "City": {
        method: "city"
      },
      "Early voting clerk's address": {}, #only needed if applicant wants to email their PDF application
    })
    klass.define_state_value_attribute("has_mailing_address")
  end
  
  def form_field_items
    [
      {"has_mailing_address": {type: :checkbox}},
      {"3 Mail my ballot to If mailing address differs from residence address please complete Box  7": {visible: "has_mailing_address"}},
      {"CITY_2": {visible: "has_mailing_address"}},
      {"State": {visible: "has_mailing_address", type: :select, options: GeoState.collection_for_select, include_blank: true}},
      {"ZIP Code_2": {visible: "has_mailing_address", min: 5, max: 10}},
      {"Reason for voting by mail:": {type: :radio}},
      {"Select only if your 65 or older or live with a disability:": {value: "November election"}},
      #conditional value if applicant selects "65 years of age or older. (Complete box #6a" radio option under "Reason for voting by mail:"
      {"Select only if absent from the county or confined to jail:": {value: "November election"}},
      #conditional value if applicant selects "65 years of age or older. (Complete box #6a" radio option under "Reason for voting by mail:"
      {"If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below": {
        type: :checkbox}}, 
      {"If you assisted the applicant in completing this application in the applicants presence or emailedmailed or faxed the application on behalf of the applicant please check this box as an Assistant and sign below": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below", 
        type: :checkbox}},
      {"Refer to Instructions on back for clarification": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"}},
        #witness' relationship to applicant
      {"Street address of witness": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"}}, 
      {"Apartment number (if applicable) of witness": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"}}, 
      {"City of witness": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"}},
      {"State of witness": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"}}, 
      {"Zip code of witness": {
        visible: "If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"}},
    ]
  end
  
  def custom_form_field_validations
    # make sure delivery is selected if reason ==3
    # make sure fax is provided if faxtype is selected for delivery
  end

  
end