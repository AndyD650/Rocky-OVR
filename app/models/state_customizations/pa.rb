class PA < StateCustomization

  def decorate_registrant(registrant=nil, controller=nil)
    unless registrant.respond_to?(:home_county_required)
      registrant.class.class_eval do
        state_attr_accessor :home_county, :prev_county, :change_of_party, :pa_submission_error, :pa_transaction_id    
        
        validate :home_county_required, :prev_county_required_in_pa, :validate_pa_formats
        
        define_method :home_county_required do
          if self.at_least_step_2? && self.home_county.blank?
            errors.add(:home_county, :blank)
          end
        end
        
        define_method :prev_county_required_in_pa do
          if self.needs_prev_address? && self.prev_state_abbrev.to_s.downcase == "pa"
            if self.prev_county.blank?
              errors.add(:prev_county, :blank)
            end
          end
        end
        
        define_method :validate_pa_formats do
          if self.at_least_step_2?
            begin
              p = self.phone ? "" : PhoneFormatter.process(value)
            rescue PhoneFormatter::InvalidPhoneNumber => e
              errors.add(:phone, e.message)
            end
            
            if self.home_unit.length > 15
              errors.add(:home_unit, "Unit number must be 15 characters or less.")
            end
            
            if self.state_id_number.length <= 4
              valid = self.state_id_number == "" || self.state_id_number =~ /^\d{4}$/
              errors.add(:state_id_number, "Last 4 of SSN must be 4 digits.") unless valid
            else
              valid = self.state_id_number == "" || self.state_id_number =~ /^\d{8}$/
              errors.add(:state_id_number, "Drivers licence must be 8 digits.") unless valid
            end
            if self.party.blank?
              errors.add(:party, :blank)
            end
          end
          
        end
        
      end
    end
  end

  def custom_step_2?
    true
  end
  
  def has_ovr_pre_check?(registrant)
    true
  end
  
  def can_submit_to_online_reg_url(registrant)
    return true
  end
  
  
  
  
  def submit_to_online_reg_url(registrant)
    pa_adapter = RockyToPA.new(registrant)
    pa_data = pa_adapter.convert
    result = PARegistrationRequest.send_request(pa_data)
    if result[:error].present?
      registrant.pa_submission_error = [result[:error].to_s]
      registrant.save!
      # This causes the delayed job to re-run on a schedule
      raise result[:error].to_s if V3::RegistrationService::PA_RETRY_ERRORS.include?(result[:error].to_s)
      Rails.logger.warn("PA Registration Error for registrant id: #{registrant.id} params:\n#{registrant.state_ovr_data}\n\nErrors:\n#{registrant.pa_submission_error}")
      AdminMailer.pa_registration_error(registrant, registrant.pa_submission_error).deliver
    elsif result[:id].blank? || result[:id]==0
        registrant.pa_submission_error = ["PA returned response with no errors and no transaction ID"]
        registrant.save!
        Rails.logger.warn("PA Registration Error for registrant id: #{registrant.id} params:\n#{registrant.state_ovr_data}\n\nErrors:\n#{registrant.pa_submission_error}")
        AdminMailer.pa_registration_error(registrant, registrant.pa_submission_error).deliver
    else
      registrant.pa_transaction_id = result[:id]
      registrant.save!
    end
  end
    
  
  def enabled_for_language?(lang, reg)
    return true
  end
  
  def ovr_pre_check(registrant, controller)
    errors = []
    pa_adapter = RockyToPA.new(registrant)
    begin
      pa_data = pa_adapter.convert
    rescue => e
      errors = ["Error parsing request: #{e.message}\n\n#{e.backtrace.join("\n")}"]        
    end

    registrant.errors.add(:base, errors.join("\n")) if errors.any?
    
  end
  
  # def online_reg_url(registrant)
  #   root_url ="https://nvsos.gov/sosvoterservices/Registration/step1.aspx?source=rtv&utm_source=rtv&utm_medium=rtv&utm_campaign=rtv"
  #   return root_url if registrant.nil?
  #   fn = CGI.escape registrant.first_name.to_s
  #   mn = CGI.escape registrant.middle_name.to_s
  #   ln = CGI.escape registrant.last_name.to_s
  #   sf = CGI.escape registrant.name_suffix.to_s
  #   zip = CGI.escape registrant.home_zip_code.to_s
  #   lang = registrant.locale.to_s
  #   "#{root_url}&fn=#{fn}&mn=#{mn}&ln=#{ln}&lang=#{lang}&zip=#{zip}&sf=#{sf}"
  # end
end