class StateRegistrants::MIRegistrant < StateRegistrants::Base
  include StateRegistrants::MIRegistrant::EyeColor
  include StateRegistrants::MIRegistrant::StreetType
  include StateRegistrants::MIRegistrant::MailingAddress
  
  validates_with MIRegistrantValidator
  

  def state_transaction_id
    self.mi_transaction_id
  end
  
  def cleanup!
    # TODO make sure we don't keep SSN
    self.ssn4 = nil
    self.dln = nil
    self.save(validate: false)
  end
  
  def default_state_abbrev
    'MI'
  end
  def steps
    %w(step_1 step_2 step_3 step_4 complete)
  end
  def num_steps
    4
  end
  
  def complete?
    status == step_list.last && valid? #&& confirm_affirm_privacy_notice? && confirm_voter_fraud_warning?
  end
  
  def async_submit_to_online_reg_url
    #self.registrant.skip_state_flow!
    self.mi_submission_complete = false
    self.save
    self.delay.submit_to_online_reg_url
  end
  
  def submitted?
    false
    #self.registrant.skip_state_flow?
  end
  
  def submit_to_online_reg_url
    
    # Do the actual submission
    # if failed, call self.registrant.skip_state_flow!
    # if successs, set submission complete and transaction ID
    self.mi_submission_complete = true
    self.mi_transaction_id = "sample-transaction-id"
    self.save
  end
  
  def mailing_same_as_residential_address
    !has_mailing_address
  end
  def mailing_same_as_residential_address=(val)
    self.has_mailing_address = val #converts to boolean
    self.has_mailing_address = !self.has_mailing_address
  end
  
  def mappings
    {
      "email" => "email_address",
      "confirm_us_citizen"  => "us_citizen",
      "confirm_will_be_18"  => "will_be_18_by_election",
      "date_of_birth" => "date_of_birth",
      # "name_title"  => "name_title",
      # "first_name"  => "first_name",
      # "middle_name" => "middle_name",
      # "last_name" => "last_name",
      # "name_suffix" => "name_suffix",

      "registration_city" => "home_city",
      "registration_zip_code" => "home_zip_code",
      
      "has_mailing_address" => "has_mailing_address",
      "mailing_city"  => "mailing_city",
      "mailing_zip_code"  => "mailing_zip_code",
      
      "opt_in_email"  => "opt_in_email",
      "opt_in_sms"  => "opt_in_sms",
      "phone" => "phone",
      "partner_opt_in_email"=>"partner_opt_in_email",
      "partner_opt_in_sms"=>"partner_opt_in_sms",
      "partner_volunteer"=>"partner_volunteer",
      

      "locale"  => "locale"
    }
  end
  
  
  
  def set_from_original_registrant
    r = self.registrant
    mappings.each do |k,v|
      val = r.send(v)
      self.send("#{k}=", val)
    end
    self.full_name = [r.first_name, r.middle_name, r.last_name].compact.join(" ")
    # regs = r.home_address.to_s.split(', ')
    # self.registration_address_1 = regs[0]
    # self.registration_address_2 = regs[1..regs.length].to_a.join(', ')
    #
    # mails = r.mailing_address.to_s.split(', ')
    # self.mailing_address_1 = mails[0]
    # self.mailing_address_2 = mails[1..mails.length].to_a.join(', ')
    
    # if r.mailing_state
    #   self.mailing_state = r.mailing_state.abbreviation
    # end
    self.save(validate: false)
  end
  
  def update_original_registrant
    r = self.registrant
    mappings.each do |k,v|
      val = self.send(k)
      r.send("#{v}=", val)
    end
    
    names = self.full_name.to_s.split(/\s+/)
    r.first_name = names.shift
    r.last_name = names.join(" ")

    street_address = [self.registration_address_number, self.registration_address_street_name, self.registration_address_street_type].collect{|v| v.blank? ? nil : v}.compact.join(' ')
    r.home_address = [street_address, self.registration_unit_number].collect{|v| v.blank? ? nil : v}.compact.join(' ')
    mailing_street = [self.mailing_address_1, self.mailing_address_2, self.mailing_address_3].collect{|v| v.blank? ? nil : v}.compact.join(', ')
    r.mailing_address = [mailing_street, self.mailing_address_unit_number].collect{|v| v.blank? ? nil : v}.compact.join(', ')
    #
    # if !self.mailing_state.blank? #always an abbrev
    #   r.mailing_state = GeoState[self.mailing_state]
    # else
    #   r.mailing_state = nil
    # end
    r.save(validate: false)
  end    
  
end
