module AbrSignatureMethods
  METHODS = [
    :voter_signature_image,
    :signature_method,
    :sms_number_for_continue_on_device,
    :email_address_for_continue_on_device
  ]
  def allow_desktop_signature?
    true
  end  

  def signature_capture_url
    step_3_abr_url(self.to_param,  :protocol => "https", :host=>RockyConf.default_url_host)
  end

  def signature_attrs
    # Always allow these methods
    AbrSignatureMethods::METHODS
  end

  def deliver_to_elections_office_via_email?
    return RockyConf.absentee_states[home_state_abbrev] && !RockyConf.absentee_states[home_state_abbrev][:email_delivery].blank?
  end

  def elections_office_name
    "Elections Officer"
  end

  def elections_office_email
    "alex.mekelburg@osetfoundation.org"
    #"ovrtool@rockthevote.org"
    #RockyConf.absentee_states[home_state_abbrev] && !RockyConf.absentee_states[home_state_abbrev][:email_delivery] ?? 
  end

  def email_address_to_send_form_delivery_from
    RockyConf.from_address
  end

  def validates_signature
    if deliver_to_elections_office_via_email? && advancing_to_step_4?
      self.validates_presence_of(:voter_signature_image)
      self.validates_presence_of(:signature_method)
    end
  end

  def signature_pdf_field_name
    nil
  end


end