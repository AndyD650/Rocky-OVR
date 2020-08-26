module AbrStateMethods::RI
  
  PDF_FIELDS = {
    "Text Field 4": {
      method: "full_name"
    },
    "Text Field 11": {},
    "Text Field 5": {
      method: "address"
    },
    "Text Field 12": {},
    "Text Field 6": {
      method: "city"
    },
    "Text Field 7": {
      method: "zip"
    },
    "Text Field 8": {
      method: "date_of_birth_mm_dd_yyyy"
    },
    "Text Field 9": {
      method: "phone"
    },
    "Text Field 14": {},
    "Text Field 15": {},
    "Text Field 16": {},
    "Text Field 10": {
      method: "email"
    },
    "Text Field 18": {
      method: "email_conditional"
    }, #TODO - if "eligibility_military" is selected, autofill with email, #ToDone
    "eligibility": { options: ["absent", "confined", "incapacitated", "military"] },
  }
  EXTRA_FIELDS = ["has_mailing_address"]
  # e.g.
  # EXTRA_FIELDS = ["has_mailing_address", "identification"]
  
  # def whatever_it_is_you_came_up_with
  #   # TODO when blah is selected it should be "abc" and otherwise left blank
  # end
  
  
  def form_field_items
    [
      {"eligibility": {type: :radio, required: true}},
      # TODO when "confined" is selected, make sure field 11,12,13,14,15,16 get populated by either the residence address or a user-entered mailing address
      {"has_mailing_address": {type: :checkbox}},
      {"Text Field 11": {visible: "has_mailing_address"}},
      {"Text Field 12": {visible: "has_mailing_address", required: :if_visible }},
      {"Text Field 14": {visible: "has_mailing_address", required: :if_visible, classes: "half"}},
      {"Text Field 15": {visible: "has_mailing_address", required: :if_visible, classes: "quarter", type: :select, options: GeoState.collection_for_select, include_blank: true}}, #TODO -- this should just be abbreviations
      {"Text Field 16": {visible: "has_mailing_address", required: :if_visible, classes: "quarter last"}},
      
    ]
  end
  
  def email_conditional
    if(self.eligibility == "military")
      return self.email
    end
  end

  
  def custom_form_field_validations
    # make sure delivery is selected if reason ==3
    # make sure fax is provided if faxtype is selected for delivery
  end
  
 
end