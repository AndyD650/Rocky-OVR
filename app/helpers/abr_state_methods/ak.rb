module AbrStateMethods::AK
  
  def self.included(klass)
    klass.add_pdf_fields({
      "All in Calendar Year" => {
        options: ["Off", "On"],
        value: "Off"
      },
      "Primary August" => {
        options: ["Off", "On"],
        value: "Off"
      },
      "General November" => {
        options: ["Off", "On"],
        value: "On"
      },
      "REAA October" => {
        options: ["Off", "On"],
        value: "Off"
      },
      "Last" => {
        method: "last_name"
      },
      "First" => {
        method: "first_name"
      },
      "Middle" => {
        method: "middle_name"
      },
      "Suffix" => {
        method: "name_suffix"
      },      
      "Street Name" => {
        method: "street_name"
      },  
      "Apt" => {
        method: "unit"
      },     
      "City" => {
        method: "city"
      },     
      "SSN or Last 4" => {},     
      "Birthdate" => {
        method: "date_of_birth_mm_dd_yyyy"
      }, 
      "Us Citizen Yes" => {
        options: ["Off", "Yes"]
      },
      "Us Citizen No" => {
        options: ["Off", "No"]
      },
      "18 Years Yes" => {
        options: ["Off", "Yes_2"]
      },
      "18 Years No" => {
        options: ["Off", "No_2"]
      },
      "House Number" => {
        method: "street_number"
      },
      "Perm Mailing 1"=>{},
      "Perm Mailing 2"=>{},
      "Perm Mailing 3"=>{},
      "ADL"=>{},
      "No SSN or ADL"=> {
        options: ["Off", "On"]
      },
      "Male"=> {
        options: ["Male", "Off"]
      },
      "Female"=> {
        options: ["Female", "Off"]
      },
      "AD Ballot" => {
        options: ["Off", "On"]
      },
      "Rep Ballot" => {
        options: ["Off", "On"]
      },
      "Remote AK and Overseas" => {
        options: ["Off", "On"]
      },
      "Ballot Mailing Address 1"=>{},
      "Ballot Mailing Address 2"=>{},
      "Ballot Mailing Address 3"=>{},
      "Former Name"=>{},
      "Voter No"=>{},
      "Party"=>{},
      "Day Phone"=>{},
      "Evening Phone"=>{
        method: "phone"
      },
      "Email"=>{
        method: "email"
      }
    })    
  end
  
  def form_field_items
    [
      {"us_citizen": {type: :checkbox}},
      {"attest_is_18": {type: :checkbox}},
      "Former Name",
      "Voter No",
      "Perm Mailing 1",
      "Perm Mailing 2",
      "Perm Mailing 3",
      "SSN or Last 4",
      "ADL",
      {"attest_no_ssn_or_dln": { type: :checkbox}},
      {"gender": {type: :radio, options: [:male, :female]}},
      "Party",
      {"ballot_selection": {type: :radio, options: [:dem, :rep]}},
      {"attest_remote": {type: :checkbox}},
      "Ballot Mailing Address 1",
      "Ballot Mailing Address 2",
      "Ballot Mailing Address 3",      
    ]
  end
  
  # TODO move this to geneal abr_state_methods
  
  
  # Methods below map from UI attributes to PDF fields
  def attest_remote
    self.remote_ak_and_overseas == "On"
  end
  def attest_remote=(value)
    if !!value && !["0", "off", "false", ""].include?(value.to_s.downcase)
      self.remote_ak_and_overseas = "On"
    else
      self.remote_ak_and_overseas = "Off"
    end
  end
  
  def us_citizen
    self.us_citizen_yes == "Yes"
  end
  
  def us_citizen=(value)
    if !!value && !["0", "off", "false", ""].include?(value.to_s.downcase)
      self.us_citizen_yes = "Yes"
      self.us_citizen_no = "Off"
    else 
      self.us_citizen_yes = "Off"
      self.us_citizen_no = "No"
    end
  end
  
  def attest_is_18
    self.n_18_years_yes == "Yes"
  end
  
  def attest_is_18=(value)
    if !!value && !["0", "off", "false", ""].include?(value.to_s.downcase)
      self.n_18_years_yes = "Yes_2"
      self.n_18_years_no = "Off"
    else 
      self.n_18_years_yes = "Off"
      self.n_18_years_no = "No_2"
    end
  end
  
  def attest_no_ssn_or_dln
    self.no_ssn_or_adl == "On"
  end
  
  def attest_no_ssn_or_dln=(value)
    if !!value && !["0", "off", "false", ""].include?(value.to_s.downcase)
      self.no_ssn_or_adl = "On"
    else 
      self.no_ssn_or_adl = "Off"
    end
  end
  
  def gender
    return "female" if self.female == "Female"
    return "male" if self.male == "Male"
    return nil
  end
  
  def ballot_selection
    return "dem" if self.ad_ballot == "On"
    return "rep" if self.rep_ballot == "On"
    return ""
  end
  def ballot_selection=(value)
    if value.to_s.downcase == "dem"
      self.ad_ballot = "On"
      self.rep_ballot = "Off"
    elsif value.to_s.downcase == "rep"
      self.ad_ballot = "Off"
      self.rep_ballot = "On"
    else
      self.ad_ballot = "Off"
      self.rep_ballot = "Off"      
    end
  end
  
  def gender=(value)
    if value.to_s.downcase == "male"
      self.male = "Male"
      self.female = "Off"
    elsif value.to_s.downcase == "female"
      self.male = "Off"
      self.female = "Female"
    else
      self.male == "Off"
      self.female == "Off"
    end
      
  end
  
end