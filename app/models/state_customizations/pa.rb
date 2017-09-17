class PA < StateCustomization
  UNITS = {APT: "APARTMENT",
    BSM: "BASEMENT",
    BOX: "BOX #",
    BLD: "BUILDING",
    DEP: "DEPARTMENT",
    FL: "FLOOR",
    FRN: "FRONT",
    HNG: "HANGER",
    LBB: "LOBBY",
    LOT: "LOT",
    LOW: "LOWER",
    OFC: "OFFICE",
    PH: "PENTHOUSE",
    PIE: "PIER",
    POL: "POLL",
    REA: "REAR",
    RM: "ROOM",
    SID: "SIDE",
    SLI: "SLIP",
    SPC: "SPACE",
    STO: "STOP",
    STE: "SUITE",
    TRL: "TRAILER",
    UNI: "UNIT",
    UPP: "UPPER",
    CBN: "CABIN",
    HUB: "HUB",
    SMC: "STUDENT MAILING CENTER",
    TH: "TOWNHOUSE"
  }
  
  def decorate_registrant(registrant=nil, controller=nil)
    unless registrant.respond_to?(:home_county_required)
      registrant.class.class_eval do
        state_attr_accessor :home_county, :home_unit_type, :prev_county, :change_of_party, :pa_submission_error, :pa_transaction_id, :ssn4, :does_not_have_ssn4, :pa_submission_complete
        
        validate :home_county_required, :prev_county_required_in_pa, :validate_pa_formats, :home_unit_type_required_if_home_unit_present, :validate_ids
        
        define_method :does_not_have_ssn4? do
          self.does_not_have_ssn4.to_s == "1"
        end
        
        
        define_method :validate_ids do
          if self.at_least_step_2? && !self.complete?
            if self.state_id_number.blank? && !self.does_not_have_state_id
              errors.add(:state_id_number, :blank)
            elsif self.does_not_have_state_id
              if self.ssn4.blank? && !self.does_not_have_ssn4?
                errors.add(:ssn4, :blank)
              end
            end
          end
        end
        
        define_method :home_county_required do
          if self.at_least_step_2? && self.home_county.blank?
            errors.add(:home_county, :blank)
          end
        end
        
        define_method :does_not_have_state_id do
          return !self.has_state_license
        end
        
        define_method :does_not_have_state_id= do |val|
          self.has_state_license = val.to_s == "0"
        end
        
        
        define_method :home_unit_type_required_if_home_unit_present do          
          if self.at_least_step_2? && !self.home_unit.blank? && self.home_unit_type.blank?
            errors.add(:home_unit_type, :blank)
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
            
            if self.status != 'complete'
              if self.has_state_license
                valid = self.state_id_number == "" || self.state_id_number.to_s.gsub(/[^\d]/,'') =~ /^\d{8}$/
                errors.add(:state_id_number, "Drivers licence must be 8 digits.") unless valid
              elsif !self.does_not_have_ssn4?
                valid = self.ssn4.to_s.gsub(/[^\d]/,'')  =~ /^\d{4}$/
                errors.add(:ssn4, "Last 4 of SSN must be 4 digits.") unless valid
              end
            end
            
            if self.party.blank?
              errors.add(:party, :blank)
            end
          end
          
        end
        
        ## Override!
        define_method :redact_sensitive_data do
          self.state_id_number = nil
          self.ssn4 = nil
        end
        
        define_method :cleanup! do
          self.redact_sensitive_data
          self.status = 'complete'
          begin
            self.deliver_thank_you_for_state_online_registration_email
          rescue Exception => e
            Rails.logger.error(e)
            raise e
          end      
          self.save
        end
        
        define_method :pdf_ready? do
          self.pdf_ready || (self.pa_submission_complete && !self.pa_transaction_id.blank?)
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
  
  
  def async_submit_to_online_reg_url(registrant)
    registrant.pa_submission_complete = false
    self.delay.submit_to_online_reg_url(registrant)    
  end
  
  def submit_to_online_reg_url(registrant)
    decorate_registrant(registrant)
    pa_adapter = RockyToPA.new(registrant)
    pa_data = pa_adapter.convert
    result = PARegistrationRequest.send_request(pa_data)
    registrant.pa_submission_complete = true
    registrant.save
    if result[:error].present?
      registrant.pa_submission_error = [result[:error].to_s]
      registrant.save!
      # No retries for this flow
      # This causes the delayed job to re-run on a schedule
      # raise result[:error].to_s if V3::RegistrationService::PA_RETRY_ERRORS.include?(result[:error].to_s)
      Rails.logger.warn("PA Registration Error for registrant id: #{registrant.id} params:\n#{registrant.state_ovr_data}\n\nErrors:\n#{registrant.pa_submission_error}")
      AdminMailer.pa_registration_error(registrant, registrant.pa_submission_error).deliver
    elsif result[:id].blank? || result[:id]==0
        registrant.pa_submission_error = ["PA returned response with no errors and no transaction ID"]
        #complete it, but go on to PDF generation?
        registrant.pa_transaction_id = nil
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
  
end