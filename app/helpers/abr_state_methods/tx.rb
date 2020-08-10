module AbrStateMethods::TX
  
  PDF_FIELDS = {
      "Suffix Jr Sr III etc": {
        method: "name_suffix"
      },
      "First Name": {
        method: "first_name"
      },
      "Middle Initial": {method: middle_initial },
      "2 Residence Address See back of this application for instructions": {
        method: "address"
      },
      "City TX": {
        method: "city"
      },
      "ZIP Code": {
        method: "zip"
      },
      "3 Mail my ballot to If mailing address differs from residence address please complete Box  7": {},
      "State": {},
      "ZIP Code_2": {},
      "4 Date of Birth mmddyyyy Optional Contact Information Optional Please list phone number andor email address  Used in case our office has questions": {
        method: "phone_and_email" 
      },
      "Date of Birth mmddyyyy Optional": {}, #month only - max: 2
      "Annual Application": {
        options: ["Off", "Yes"],
        value: "Off"
      },
      "Republican Primary": {
        options: ["Off", "Republican Primary"],
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
        #TODO- conditional static value of "November election" if applicant selects "65 years of age or older. (Complete box #6a" radio option under "Reason for voting by mail:"
      },
      "Select only if absent from the county or confined to jail:": {
        options: ["Any resulting runoff", "May election", "November election", "Off", "Other"]
        #TODO- conditional static value of "November election" if applicant selects "Confinement to jail. (Complete box #6b)" radio option under "Reason for voting by mail:"
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
      "Relative; relationship": {}, #this is the text field for the radio option
      "early voting clerks fax": {}, #only needed if applicant wants to fax their PDF application
      "City": {
        method: "city"
      },
      "Early voting clerk's address": {}, #only needed if applicant wants to email their PDF application
    }
  EXTRA_FIELDS = ["has_mailing_address"]
  
  def form_field_items
    [
      {"Reason for voting by mail:": {required: true, type: :radio, options: []}}, #TODO- grab options from above
      {"has_mailing_address": {type: :checkbox}},
      {"3 Mail my ballot to If mailing address differs from residence address please complete Box  7": {visible: "has_mailing_address"}},
      {"City": {visible: "has_mailing_address"}},
      {"State": {visible: "has_mailing_address", type: :select, options: GeoState.collection_for_select, include_blank: true}},
      {"ZIP Code_2": {visible: "has_mailing_address", min: 5, max: 10}},
      {"If requesting this ballot be mailed to a different address (other than residense), indicate where the ballot will be mailed": {
        visible: "has_mailing_address", type: :radio, options: []}}, #TODO- grab options from above
      {"Relative; relationship": {visible: "if_requesting_this_ballot_be_mailed_to_a_different_address__other_than_residense___indicate_where_the_ballot_will_be_mailed_relative__relationship"}},
      {"If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below": {
        type: :checkbox}}, 
      {"If you assisted the applicant in completing this application in the applicants presence or emailedmailed or faxed the application on behalf of the applicant please check this box as an Assistant and sign below": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below"), 
        type: :checkbox}},
      {"Refer to Instructions on back for clarification": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below")}},
        #witness' relationship to applicant
      {"Street address of witness": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below")}}, 
      {"Apartment number (if applicable) of witness": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below")}}, 
      {"City of witness": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below")}},
      {"State of witness": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below")}}, 
      {"Zip code of witness": {
        visible: self.class.make_method_name("If applicant is unable to mark Box 10 and you are acting as a Witness to that fact please check this box and sign below")}},
    ]
  end
  
  def custom_form_field_validations
    # make sure delivery is selected if reason ==3
    # make sure fax is provided if faxtype is selected for delivery
  end

  
end