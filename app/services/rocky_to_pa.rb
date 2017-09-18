class RockyToPA
  class ParsingError < StandardError;
  end

  REQUIRED = true
  OPTIONAL = false
  # for reference only
  # FIELDS = {
  #     "batch" => 0,
  #     "FirstName" => nil,
  #     "MiddleName" => nil,
  #     "LastName" => nil,
  #     "TitleSuffix" => nil,
  #     "united-states-citizen" => nil,
  #     "eighteen-on-election-day" => nil,
  #     "isnewregistration" => nil,
  #     "name-update" => nil,
  #     "address-update" => nil,
  #     "ispartychange" => nil,
  #     "isfederalvoter" => nil,
  #     "DateOfBirth" => nil,
  #     "Gender" => nil,
  #     "Ethnicity" => nil,
  #     "Phone" => nil,
  #     "Email" => nil,
  #     "streetaddress" => nil,
  #     "streetaddress2" => nil,
  #     "unittype" => nil,
  #     "unitnumber" => nil,
  #     "city" => nil,
  #     "zipcode" => nil,
  #     "donthavePermtOrResAddress" => nil,
  #     "county" => nil,
  #     "municipality" => nil,
  #     "mailingaddress" => nil,
  #     "mailingcity" => nil,
  #     "mailingstate" => nil,
  #     "mailingzipcode" => nil,
  #     "drivers-license" => nil,
  #     "ssn4" => nil,
  #     "signatureimage" => nil,
  #     "continueAppSubmit" => nil,
  #     "donthavebothDLandSSN" => nil,
  #     "politicalparty" => nil,
  #     "otherpoliticalparty" => nil,
  #     "needhelptovote" => nil,
  #     "typeofassistance" => nil,
  #     "preferredlanguage" => nil,
  #     "voterregnumber" => nil,
  #     "previousreglastname" => nil,
  #     "previousregfirstname" => nil,
  #     "previousregmiddlename" => nil,
  #     "previousregaddress" => nil,
  #     "previousregcity" => nil,
  #     "previousregstate" => nil,
  #     "previousregzip" => nil,
  #     "previousregcounty" => nil,
  #     "previousregyear" => nil,
  #     "declaration1" => nil,
  #     "assistedpersonname" => nil,
  #     "assistedpersonAddress" => nil,
  #     "assistedpersonphone" => nil,
  #     "assistancedeclaration2" => nil,
  #     "ispollworker" => nil,
  #     "bilingualinterpreter" => nil,
  #     "pollworkerspeaklang" => nil,
  #     "secondEmail" => nil
  # }

  #

  def initialize(registrant)
    @registrant = registrant
    @request = registrant.to_api_hash
    raise ParsingError.new('Invalid input, voter_registration value not found') if @request.nil?
  end
  
  def valid_for_submission?
    dont_have_both_ids == "1"
  end

  def convert
    result = {}
    result['batch'] = "0"
    result['FirstName'] = read([:first_name], REQUIRED)
    result['MiddleName'] = read([:middle_name])
    result['LastName'] = read([:last_name], REQUIRED)
    result['TitleSuffix'] = read([:name_title])

    value = read([:us_citizen], REQUIRED)
    result['united-states-citizen'] = bool_to_int(value, "united_states_citizen")

    value = read([:will_be_18_by_election], REQUIRED)
    result['eighteen-on-election-day'] = bool_to_int(value, "eighteen_on_election_day")

    result['isnewregistration'] = is_new_registration
    result['name-update'] = name_update
    result['address-update'] = address_update
    result['ispartychange'] = bool_to_int(@registrant.change_of_party.to_s == "1")
    result['isfederalvoter'] = ""

    # YYYY-MM-DD is expected
    result['DateOfBirth'] = VRToPA.format_date(@registrant.date_of_birth.to_s, "date_of_birth")
    result['Gender'] = parse_gender()
    result['Ethnicity'] = parse_race(read([:race]))

    result['Phone'] = phone


    result['Email'] = email
    result['streetaddress'] = @registrant.home_address
    result['streetaddress2'] = ""
    result['unittype'] = @registrant.home_unit_type
    result['unitnumber'] = @registrant.home_unit

    result['municipality'] = @registrant.home_city
    result['city'] = @registrant.home_city

    result['zipcode'] = zip_code(:home_zip_code)
    result['donthavePermtOrResAddress'] = ''
    result['county'] = county

    if @registrant.has_mailing_address?
      result['mailingaddress'] = @registrant.mailing_address
      result['mailingcity'] = @registrant.mailing_city
      result['mailingstate'] = @registrant.mailing_state_abbrev
      result['mailingzipcode'] = zip_code(@registrant.mailing_zip_code)
    else
      result['mailingaddress'] = ''
      result['mailingcity'] = ''
      result['mailingstate'] = ''
      result['mailingzipcode'] = ''
    end

    result['drivers-license'] = drivers_license

    result['ssn4'] = ssn4
    result['signatureimage'] = readsignature
    result['continueAppSubmit'] = "1"
    result['donthavebothDLandSSN'] = dont_have_both_ids

    result['politicalparty'] = party[:politicalparty]
    result['otherpoliticalparty'] = party[:otherpoliticalparty]
    result['needhelptovote'] = ""
    result['typeofassistance'] = ""

    result['preferredlanguage'] = @registrant.locale

    result['voterregnumber'] = ""

    result['previousreglastname'] = prev_last_name
    result['previousregfirstname'] = prev_first_name
    result['previousregmiddlename'] = prev_middle_name

    result['previousregaddress'] = prev_reg_address
    result['previousregcity'] = prev_reg_city
    result['previousregstate'] = prev_reg_state
    result['previousregzip'] = prev_reg_zip

    result['previousregcounty'] = prev_reg_county
    
    result['previousregyear'] = ""
    result['declaration1'] = "1"
    
    result['assistedpersonname'] = @registrant.assisted_person_name
    result['assistedpersonAddress'] = @registrant.assisted_person_address
    result['assistedpersonphone'] = @registrant.assisted_person_phone
    result['assistancedeclaration2'] = bool_to_int(@registrant.has_assistant?)
    validate_assisted_person_data(result)
    result['ispollworker'] = ""
    result['bilingualinterpreter'] = ""
    result['pollworkerspeaklang'] = ""
    result['secondEmail'] = ""


    result
  end

  def is_new_registration_boolean
    prev_state_outside_pa = @registrant.change_of_address? && @registrant.prev_state_abbrev != "PA"
    return (!@registrant.change_of_name? && !@registrant.change_of_address?) || prev_state_outside_pa
  end

  def is_new_registration
     is_new_registration_boolean ? "1" : "0"
  end


  def phone(section = nil)
    value = read([:phone])
    is_empty(value) ? "" : PhoneFormatter.process(value)
  rescue PhoneFormatter::InvalidPhoneNumber => e
    raise ParsingError.new(e.message)
  end

  COUNTIES =%w(ADAMS ALLEGHENY ARMSTRONG BEAVER BEDFORD BERKS BLAIR BRADFORD BUCKS BUTLER CAMBRIA CAMERON CARBON CENTRE CHESTER CLARION CLEARFIELD CLINTON COLUMBIA CRAWFORD CUMBERLAND DAUPHIN DELAWARE ELK ERIE FAYETTE FOREST FRANKLIN FULTON GREENE HUNTINGDON INDIANA JEFFERSON JUNIATA LACKAWANNA LANCASTER LAWRENCE LEBANON LEHIGH LUZERNE LYCOMING MCKEAN MERCER MIFFLIN MONROE MONTGOMERY MONTOUR NORTHAMPTON NORTHUMBERLAND PERRY PHILADELPHIA PIKE POTTER SCHUYLKILL SNYDER SOMERSET SULLIVAN SUSQUEHANNA TIOGA UNION VENANGO WARREN WASHINGTON WAYNE WESTMORELAND WYOMING YORK)

  def county
    @registrant.home_county
  end

  def prev_reg_county
    is_new_registration_boolean ? nil : @registrant.prev_county
  end

  def prev_reg_zip
    is_new_registration_boolean ? nil : zip_code(:prev_zip_code, address_update_boolean)
  end

  def prev_reg_state
    is_new_registration_boolean ? nil : read([:prev_state_abbrev])
  end

  def prev_reg_city
    is_new_registration_boolean ? "" : read([:prev_city], address_update_boolean)
  end

  def prev_reg_address
    is_new_registration_boolean ? nil : read([:prev_address], address_update_boolean)
  end

  def address_update_boolean
    @registrant.change_of_address?
  end
  
  def address_update
    is_new_registration_boolean ? "0" : (address_update_boolean ? "0" : "1")
  end

  def prev_middle_name
    is_new_registration_boolean ? nil : read([:previous_middle_name])
  end

  def prev_first_name
    is_new_registration_boolean ? nil : read([:previous_first_name], name_update_boolean)
  end

  def prev_last_name
    is_new_registration_boolean ? nil : read([:prev_last_name], name_update_boolean)
  end

  def name_update_boolean
    @registrant.change_of_name? 
  end
  
  def name_update
    name_update_boolean ? "0" : "1"
  end

  def zip_code(key, is_required=true)
    v = safe_strip(read([key], is_required))
    if is_empty(v) || v =~ /^\d{5}(-\d{4})?$/
      v
    else
      raise ParsingError.new("Invalid ZIP code \"#{v}\". Expected format is NNNNN or NNNNN-NNNN")
    end
  end

  def unitnumber
    un = read([:registration_address, :numbered_thoroughfare_address, :complete_sub_address, :sub_address])
    un = un.to_s
    valid = un.length <= 15
    raise ParsingError.new("Unit number must be 15 characters or less. #{un} is #{un.length} characters") unless valid
    un
  end

  def drivers_license
    return '' if @registrant.state_id_number.to_s.length <= 7
    dl = @registrant.state_id_number.to_s.strip.gsub(/[^\d]/,'') 
    valid = dl == "" || dl =~ /^\d{8}$/
    raise ParsingError.new("Invalid drivers licence value \"%s\": 8 digits are expected" % dl) unless valid
    dl
  end

  def read(keys, required=false)
    keys = keys.split(".") if keys.is_a? String
    value = @registrant
    keys.each do |key|
      break if value.nil?
      value = value.send(key.to_s)
      raise ParsingError.new("Required value #{keys.join('.')} not found") if required && is_empty(value)
    end
    value
  end

  def readsignature
    # TODO
    return ""
    data = read([:signature, :image])
    type = read([:signature, :mime_type])
    
    if !is_empty(data)
      return "data:#{type};base64,#{data}"
    else
      return ""
    end

  end


  def str_to_bool(v, error_field_name = "")
    case v
      when "true"
        true
      when "false"
        false
      else
        if error_field_name != ""
          raise ParsingError.new("Invalid string value: \"#{v}\" for #{error_field_name}. Expected: \"true\" or \"false\"")
        else
          false
        end
    end
  end

  def bool_to_int(v, error_field_name = "")
    raise ParsingError.new("Boolean expected, #{v.class.name} found (#{error_field_name} #{v})") unless is_bool(v)
    v ? "1" : "0"
  end

  def is_bool(v)
    [true, false].include?(v)
  end

  def parse_gender
    key = @registrant.name_title_key.to_s
    return 'M' if key == 'mr'
    return 'F' if !key.blank?
    return ''
  end

  def is_empty(value)
    [nil, {}, "", []].include?(value)
  end

  RACE_RULES =
      {
          "american_indian_alaskan_native" => "I",
          "asian" => "A",
          "black_not_hispanic" => "B",
          "hispanic" => "H",
          "white_not_hispanic" => "W",
          "other" => "O"          
      }

  def parse_race(race)
    RACE_RULES[@registrant.race_key.to_s.downcase.strip] || ""
  end

  
  PARTIES_NAMES = {
      "democratic" => "D",
      "republican" => "R",
      "none" => "NF"
  }

  def party
    @party ||= begin
      name = read([:english_party_name], REQUIRED)
      v = PARTIES_NAMES[name.to_s.downcase.strip]
      v ? {politicalparty: v, otherpoliticalparty: ""} : {politicalparty: "OTH", otherpoliticalparty: @registrant.other_party}
    end
  end

  def email
    v = safe_strip(read([:email_address]))
    if is_empty(v)
      ""
    else
      valid = v.is_a?(String) && v =~ /^[^\s@]+@[^\s@]+\.[\w]{2,}$/
      raise ParsingError.new("Invalid e-mail value \"#{v}\".") unless valid
      v
    end
  end

  def ssn4
    v = @registrant.ssn4.to_s.gsub(/[^\d]/,'') 
    if v.blank?
      ""
    else
      valid = v.is_a?(String) && v =~ /^\d{4}$/
      raise ParsingError.new("Invalid SSN4 value \"#{v}\", expected: 4 digits value") unless valid
      v
    end
  end

  def no_such_voter_id(type)
    v = query([:voter_ids], :type, type, :attest_no_such_id)
    v_val = query([:voter_ids], :type, type, :string_value)
    return '1' if is_empty(v_val)
    raise ParsingError.new("Wrong attest_no_such_id value for #{type}: \"#{v}\"") if is_empty(v) || !is_bool(v)

    bool_to_int(v)
  end

  def assistant_declaration
    value = query([:additional_info], :name, 'assistant_declaration', :string_value)
    value = str_to_bool(value)
    bool_to_int(value)
  end

  def assistance_declaration2
    value = query([:additional_info], :name, 'assistance_declaration2', :boolean_value)
    value = false if value == ""
    bool_to_int(value)
  end
  
  def validate_assisted_person_data(result)
    if result['assistancedeclaration2'] == '1'
      raise ParsingError.new("If assistance declaration is true, assistant name, address and phone must be provided.") if is_empty(result['assistedpersonname']) || is_empty(result['assistedpersonAddress']) || is_empty(result['assistedpersonphone'])
    elsif !is_empty(result['assistedpersonname']) || !is_empty(result['assistedpersonAddress']) || !is_empty(result['assistedpersonphone'])
      raise ParsingError.new("If assistance declaration is false, assistant name, address and phone must be empty.")
    end
  end

  def dont_have_both_ids
    return @registrant.does_not_have_state_id && @registrant.does_not_have_ssn4? ? "0" : "1"
  end

  def assisted_person_name
    name = read("registration_helper.name")
    return "" if is_empty(name)
    parts = %w(first_name middle_name last_name title_suffix)
    join_non_empty(parts.map { |k| name[k] }, ' ')
  end

  def assisted_person_address
    address = read "registration_helper.address.numbered_thoroughfare_address"
    return "" if is_empty(address)

    line1 = join_non_empty([address["complete_address_number"], address["complete_street_name"]], ' ')
    city = query(
        "registration_helper.address.numbered_thoroughfare_address.complete_place_names",
        :place_name_type, 'MunicipalJurisdiction', :place_name_value)
    state = address["state"]
    line2 = join_non_empty([city, state], " ")

    join_non_empty([line1, line2], ", ")
  end

  def assisted_person_phone
    phone(:registration_helper)
  end

  def join_non_empty(objects, separator)
    objects.reject { |v| is_empty(v) }.join(separator)
  end


  def safe_strip(value)
    if value.respond_to? :strip
      value.strip
    else
      value
    end
  end
end
