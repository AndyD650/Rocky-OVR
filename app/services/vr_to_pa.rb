class VRToPA
  class ParsingError < StandardError;
  end

  REQUIRED = true
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
  # SAMPLE_VR_REQUEST = {
  # "rocky_request" => {
  #     "lang" => "en",
  #     "phone_type" => "home",
  #     "partner_id" => 1,
  #     "opt_in_email" => false,
  #     "opt_in_sms" => false,
  #     "opt_in_volunteer" => false,
  #     "partner_opt_in_sms" => true,
  #     "partner_opt_in_email" => true,
  #     "partner_opt_in_volunteer" => false,
  #     "finish_with_state" => true,
  #     "created_via_api" => true,
  #     "source_tracking_id" => "Aaron Huttner",
  #     "partner_tracking_id" => "22201",
  #     "geo_location" => {
  #         "lat" => 123,
  #         "long" => -123
  #     },
  #     "open_tracking_id" => "metro canvasing",
  #     "voter_records_request" => {

  #     "type" => "registration",
  #     "generated_date" => "2016-06-16T19=>44=>45+00=>00",
  #     "voter_registration" => {
  #         "date_of_birth" => "2016-06-16",
  #         "mailing_address" => {
  #             "numbered_thoroughfare_address" => {
  #                 "complete_address_number" => "\"\"",
  #                 "complete_street_name" => "801 N. Monroe",
  #                 "complete_sub_address" => {
  #                     "sub_address_type" => "APT",
  #                     "sub_address" => "Apt 306"
  #                 },
  #                 "complete_place_names" => [
  #                     {
  #                         "place_name_type" => "MunicipalJurisdiction",
  #                         "place_name_value" => "Philadelphia"
  #                     },
  #                     {
  #                         "place_name_type" => "County",
  #                         "place_name_value" => "Philadelphia"
  #                     }
  #                 ],
  #                 "state" => "Virginia",
  #                 "zip_code" => "22201"
  #             }
  #         },
  #         "previous_registration_address" => {
  #             "numbered_thoroughfare_address" => {
  #                 "complete_address_number" => "\"\"",
  #                 "complete_street_name" => "801 N. Monroe",
  #                 "complete_sub_address" => {
  #                     "sub_address_type" => "APT",
  #                     "sub_address" => "Apt 306"
  #                 },
  #                 "complete_place_names" => [
  #                     {
  #                         "place_name_type" => "MunicipalJurisdiction",
  #                         "place_name_value" => "Philadelphia"
  #                     },
  #                     {
  #                         "place_name_type" => "County",
  #                         "place_name_value" => "Philadelphia"
  #                     }
  #                 ],
  #                 "state" => "Virginia",
  #                 "zip_code" => "22201"
  #             }
  #         },
  #         "registration_address" => {
  #             "numbered_thoroughfare_address" => {
  #                 "complete_address_number" => "\"\"",
  #                 "complete_street_name" => "801 N. Monroe",
  #                 "complete_sub_address" => {
  #                     "sub_address_type" => "APT",
  #                     "sub_address" => "Apt 306"
  #                 },
  #                 "complete_place_names" => [
  #                     {
  #                         "place_name_type" => "MunicipalJurisdiction",
  #                         "place_name_value" => "Philadelphia"
  #                     },
  #                     {
  #                         "place_name_type" => "County",
  #                         "place_name_value" => "Philadelphia"
  #                     }
  #                 ],
  #                 "state" => "Virginia",
  #                 "zip_code" => "22201"
  #             }
  #         },
  #         "registration_address_is_mailing_address" => false,
  #         "name" => {
  #             "first_name" => "Aaron",
  #             "last_name" => "Huttner",
  #             "middle_name" => "Bernard",
  #             "title_prefix" => "Mr",
  #             "title_suffix" => "Jr"
  #         },
  #         "previous_name" => {
  #             "first_name" => "Aaron",
  #             "last_name" => "Huttner",
  #             "middle_name" => "Bernard",
  #             "title_prefix" => "Mr",
  #             "title_suffix" => "Jr"
  #         },
  #         "gender" => "male",
  #         "race" => "American Indian / Alaskan Native",
  #         "party" => "democratic",
  #         "voter_classifications" => [
  #             {
  #                 "type" => "eighteen_on_election_day",
  #                 "assertion" => true
  #             },
  #             {
  #                 "type" => "united_states_citizen",
  #                 "assertion" => true
  #             },
  #             {
  #                 "type" => "send_copy_in_mail",
  #                 "assertion" => true
  #             },
  #             {
  #                 "type" => "agreed_to_declaration",
  #                 "assertion" => true
  #             }
  #         ],
  #         "signature" => {
  #             "mime_type" => "image/png",
  #             "image" => "?"
  #         },
  #         "voter_ids" => [
  #             {
  #                 "type" => "drivers_license",
  #                 "string_value" => "1243asdf",
  #                 "attest_no_such_id" => false
  #             }
  #         ],
  #         "contact_methods" => [
  #             {
  #                 "type" => "phone",
  #                 "value" => "555-555-5555",
  #                 "capabilities" => ["voice", "fax", "sms"]
  #             }
  #         ],
  #         "additional_info" => [
  #             {
  #                 "name" => "preferred_language",
  #                 "string_value" => "english"
  #             }
  #         ]
  #     }
  # }

  # }
  # }


  def initialize(voter_records_req)
    @voter_records_request = voter_records_req
    @request = @voter_records_request['voter_registration']
    raise ParsingError.new('Invalid input, voter_registration value not found') if @request.nil?
  end

  def convert
    result = {}
    result['batch'] = "0"
    result['FirstName'] = read([:name, :first_name], REQUIRED)
    result['MiddleName'] = read([:name, :middle_name], REQUIRED)
    result['LastName'] = read([:name, :last_name])
    result['TitleSuffix'] = read([:name, :title_suffix])

    value = query([:voter_classifications], :type, 'united_states_citizen', :assertion, REQUIRED)
    result['united-states-citizen'] = bool_to_int(value, "united_states_citizen")

    value = query([:voter_classifications], :type, 'eighteen_on_election_day', :assertion, REQUIRED)
    result['eighteen-on-election-day'] = bool_to_int(value, "eighteen_on_election_day")

    result['isnewregistration'] =
        (is_empty(read([:previous_registration_address])) && is_empty(read([:previous_name]))) ? "1" : "0"
    result['name-update'] = is_empty(read([:previous_name])) ? "0" : "1"
    result['address-update'] = is_empty(read([:previous_registration_address])) ? "0" : "1"
    result['ispartychange'] = ""
    result['isfederalvoter'] = ""

    # YYYY-MM-DD is expected
    result['DateOfBirth'] = VRToPA.format_date(read([:date_of_birth], REQUIRED), "date_of_birth")
    result['Gender'] = parse_gender(read([:gender]))
    result['Ethnicity'] = parse_race(read([:race]))

    value = query([:contact_methods], :type, 'phone', :value)
    result['Phone'] = value


    result['Email'] = email
    result['streetaddress'] = street_address
    result['streetaddress2'] = ""
    result['unittype'] = read([:registration_address, :numbered_thoroughfare_address, :complete_sub_address, :sub_address_type])
    result['unitnumber'] = read([:registration_address, :numbered_thoroughfare_address, :complete_sub_address, :sub_address])

    result['municipality'] = municipality(:registration_address)
    result['city'] = municipality(:registration_address)

    result['zipcode'] = zip_code(:registration_address)
    result['donthavePermtOrResAddress'] = ''

    result['county'] = query([:registration_address, :numbered_thoroughfare_address, :complete_place_names],
                             :place_name_type, 'County', :place_name_value, REQUIRED)


    result['mailingaddress'] = read([:mailing_address, :numbered_thoroughfare_address, :complete_street_name])
    result['mailingcity'] = municipality(:mailing_address)
    result['mailingstate'] = read([:mailing_address, :numbered_thoroughfare_address, :state])
    result['mailingzipcode'] = zip_code(:mailing_address)

    result['drivers-license'] = drivers_license

    result['ssn4'] = ssn4
    result['signatureimage'] = read([:signature, :image])
    result['continueAppSubmit'] = "1"
    result['donthavebothDLandSSN'] = dont_have_both_ids

    result['politicalparty'] = party[:politicalparty]
    result['otherpoliticalparty'] = party[:otherpoliticalparty]
    result['needhelptovote'] = ""
    result['typeofassistance'] = ""

    result['preferredlanguage'] = query([:additional_info], :name, 'preferred_language', :string_value)

    result['voterregnumber'] = ""
    result['previousreglastname'] = read([:previous_name, :last_name])
    result['previousregfirstname'] = read([:previous_name, :first_name])
    result['previousregmiddlename'] = read([:previous_name, :middle_name])
    result['previousregaddress'] = read([:previous_registration_address, :numbered_thoroughfare_address, :complete_street_name])
    result['previousregcity'] = municipality(:previous_registration_address)
    result['previousregstate'] = read([:previous_registration_address, :numbered_thoroughfare_address, :state])
    result['previousregzip'] = read([:previous_registration_address, :numbered_thoroughfare_address, :zip_code])

    result['previousregcounty'] = query([:previous_registration_address, :numbered_thoroughfare_address, :complete_place_names],
                                        :place_name_type, 'County', :place_name_value)

    result['previousregyear'] = ""
    result['declaration1'] = "1"
    result['assistedpersonname'] = assisted_person_name
    result['assistedpersonAddress'] = assisted_person_address
    result['assistedpersonphone'] = assisted_person_phone
    result['assistancedeclaration2'] = assistance_declaration2
    result['ispollworker'] = ""
    result['bilingualinterpreter'] = ""
    result['pollworkerspeaklang'] = ""
    result['secondEmail'] = ""

    result
  end

  def zip_code(section)
    read([section, :numbered_thoroughfare_address, :zip_code], REQUIRED)
  end

  def municipality(section)
    query(
        [section, :numbered_thoroughfare_address, :complete_place_names],
        :place_name_type, 'MunicipalJurisdiction', :place_name_value, REQUIRED)
  end

  def street_address
    join_non_empty([
                       read([:registration_address, :numbered_thoroughfare_address, :complete_address_number]),
                       read([:registration_address, :numbered_thoroughfare_address, :complete_street_name], REQUIRED)
                   ], ' ')
  end

  def drivers_license
    query([:voter_ids], :type, 'drivers_license', :string_value)
  end

  def read(keys, required=false)
    keys = keys.split(".") if keys.is_a? String
    value = @request
    keys.each do |key|
      break if value.nil?
      value = value[key.to_s]
      raise ParsingError.new("Value #{keys.join('.')} not found in #{@request}") if required && value.nil?
    end
    value
  end

  def query(keys, key, value, output, required=false)
    objects = read(keys, required) || []
    raise ParsingError.new("Array is expected #{objects.class.name} found") unless objects.is_a? Array
    result = objects.find { |obj| obj[key.to_s] == value }
    raise ParsingError.new("Not found #{key} == #{value} in #{objects}") if is_empty(result) && required
    result ? result[output.to_s] : ""
  end

  def bool_to_int(v, error_field_name = "")
    raise ParsingError.new("Boolean expected, #{v.class.name} found (#{error_field_name} #{v})") unless is_bool(v)
    v ? "1" : "0"
  end

  def is_bool(v)
    [true, false].include?(v)
  end

  def parse_gender(gender)
    gender.downcase.strip == 'male' ? 'M' : 'F'
  end

  def is_empty(value)
    [nil, {}, "", []].include?(value)
  end

  RACE_RULES =
      {
          "american indian / alaskan native" => "I",
          "asian / pacific islander" => "A",
          "black (not hispanic)" => "B",
          "hispanic" => "H",
          "white (not hispanic)" => "W"
      }

  def parse_race(race)
    RACE_RULES[race.downcase.strip] || "O"
  end

  PARTIES_NAMES = {
      "democratic" => "D",
      "republican" => "R",
      "none" => "NF"
  }

  def party
    @party ||= begin
      name = read([:party])
      v = PARTIES_NAMES[name.downcase.strip]
      v ? {politicalparty: v, otherpoliticalparty: ""} : {politicalparty: "OTH", otherpoliticalparty: name}
    end
  end

  def email
    query([:contact_methods], :type, 'email', :value)
  end

  def ssn4
    query([:voter_ids], :type, 'ssn4', :string_value)
  end

  def no_such_voter_id(type)
    v = query([:voter_ids], :type, type, :attest_no_such_id)
    v_val = query([:voter_ids], :type, type, :string_value)
    return '1' if is_empty(v_val)
    raise ParsingError.new("Wrong attest_no_such_id value for #{type}: \"#{v}\"") if is_empty(v) || !is_bool(v)

    bool_to_int(v)
  end

  def assistance_declaration2
    value = query([:additional_info], :name, 'assistance_declaration2', :boolean_value)
    value = false if value == ""
    bool_to_int(value)
  end

  def dont_have_both_ids
    v = no_such_voter_id('ssn4') == '1' &&
        no_such_voter_id('drivers_license') == '1'
    if v
      [ssn4: ssn4, drivers_license: drivers_license].each do |name, id|
        raise ParsingError.new("Non empty #{name} when attest_no_such_id == true") unless is_empty(id)
      end
      "1"
    else
      "0"
    end
  end

  def assisted_person_name
    name = read("registration_helper.name")
    return "" if is_empty(name)
    parts = %w(title_prefix first_name middle_name last_name title_suffix)
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
    query("registration_helper.contact_methods", :type, 'phone', :value)
  end

  def join_non_empty(objects, separator)
    objects.reject { |v| is_empty(v) }.join(separator)
  end

  def self.format_date(value, error_field_name=nil)
    # Date.parse(value).strftime("%m/%d/%Y")
    Date.parse(value).strftime("%Y-%m-%d")
  rescue ArgumentError => e
    if error_field_name.nil?
      ""
    else
      raise ParsingError.new("Invalid date value \"#{value}\" for \"#{error_field_name}\", #{e.message}")
    end
  end
end
