V3#***** BEGIN LICENSE BLOCK *****
#
#Version: RTV Public License 1.0
#
#The contents of this file are subject to the RTV Public License Version 1.0 (the
#"License"); you may not use this file except in compliance with the License. You
#may obtain a copy of the License at: http://www.osdv.org/license12b/
#
#Software distributed under the License is distributed on an "AS IS" basis,
#WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
#specific language governing rights and limitations under the License.
#
#The Original Code is the Online Voter Registration Assistant and Partner Portal.
#
#The Initial Developer of the Original Code is Rock The Vote. Portions created by
#RockTheVote are Copyright (C) RockTheVote. All Rights Reserved. The Original
#Code contains portions Copyright [2008] Open Source Digital Voting Foundation,
#and such portions are licensed to you under this license by Rock the Vote under
#permission of Open Source Digital Voting Foundation.  All Rights Reserved.
#
#Contributor(s): Open Source Digital Voting Foundation, RockTheVote,
#                Pivotal Labs, Oregon State University Open Source Lab.
#
#***** END LICENSE BLOCK *****
module V3
  class RegistrationService

    INVALID_PARTNER_OR_PASSWORD = "Invalid partner ID or password"

    # Validation error
    class ValidationError < StandardError
      attr_reader :field

      def initialize(field, message)
        super(message)
        @field = field
      end
    end

    class SurveyQuestionError < StandardError
    end
    
    class InvalidUIDError < ValidationError
      def initialize
        super("UID", "Registrant not found")
      end
    end
    
    class InvalidParameterValue < ValidationError
      def initialize(field)
        super(field, "Invalid Parameter Value")
      end
    end
    class InvalidParameterType < ValidationError
      def initialize(field)
        super(field, "Invalid Parameter Type")
      end
    end
    
    # Creates a record and returns it.
    def self.create_record(data, finish_with_state = false)
      data ||= {}
      block_protected_attributes(data)

      attrs = data_to_attrs(data)
      async = attrs.delete(:async)
      async = true if (async != false)
      
      validate_survey_questions(attrs) unless finish_with_state

      reg = Registrant.build_from_api_data(attrs, finish_with_state)

      if reg.save
        reg.enqueue_complete_registration_via_api(async) unless finish_with_state
      else
        validate_language(reg)
        raise_validation_error(reg)
      end
      return reg
    end
    
    def self.create_pa_registrant(orig_data)
      orig_data = ActiveSupport::HashWithIndifferentAccess.new(orig_data)
      data = orig_data.deep_dup
      geo_location  = data.delete(:geo_location)
      attrs = pa_data_to_attrs(data)
      r = Registrant.build_from_pa_api_data(attrs)
      # process into Registrant fields
      r.state_ovr_data["voter_records_request"] = orig_data[:voter_records_request]
      r.state_ovr_data["geo_location"] = geo_location
      return r
    end
    
    def self.valid_for_pa_submission(registrant)
      pa_adapter = VRToPA.new(registrant.state_ovr_data["voter_records_request"])
      begin
        pa_data = pa_adapter.convert
      rescue => e
        return ["Error parsing request: #{e.message}"]        
      end
      return []
    end
    
    def self.register_with_pa(registrant, debug=nil)
    
      pa_adapter = VRToPA.new(registrant.state_ovr_data["voter_records_request"])
      
      pa_data = pa_adapter.convert
      result = PARegistrationRequest.send_request(pa_data)
      if result[:error].present?
        raise result[:error].to_s
      else
        registrant.state_ovr_data['pa_transaction_id'] = result[:id]
        registrant.save!
      end
    end
    
    # def self.bulk_create(data_list, partner_id, partner_api_key)
    #   partner = V3::PartnerService.find_partner(partner_id, partner_api_key)
    #   return data_list.collect do |data|
    #     begin
    #       block_protected_attributes(data)
    #       attrs = data_to_attrs(data)
    #       status = attrs.delete(:status)
    #       async = attrs.delete(:async)
    #       reg = Registrant.new(attrs)
    #       reg.status = status
    #       reg.save!
    #       [true, reg.uid]
    #     rescue Exception=>e
    #       [false, e.message]
    #     end
    #   end
    # end

    # Lists records for the given registrant
    ALLOWED_PARAMETERS = [:partner_id, :gpartner_id, :partner_api_key, :gpartner_api_key, :since, :email, :callback]
    def self.find_records(query)
      query ||= {}

      cond_str = []
      cond_vars = []
      
      query.each do |k,v|
        if !ALLOWED_PARAMETERS.include?(k.to_s.downcase.to_sym)
          raise InvalidParameterType.new(k)
        end
      end

      if query[:gpartner_id]
        partner = V3::PartnerService.find_partner(query[:gpartner_id], query[:gpartner_api_key])
        regs = Registrant
        if partner.is_government_partner? && !partner.government_partner_state.nil?
          cond_str << "home_state_id = ?"
          cond_vars << partner.government_partner_state_id
        elsif partner.is_government_partner? && !partner.government_partner_zip_codes.blank?
          cond_str << "home_zip_code in (?)"
          cond_vars << partner.government_partner_zip_codes
        else
          return []
        end
      else
        partner = V3::PartnerService.find_partner(query[:partner_id], query[:partner_api_key])
        regs = partner.registrants
      end
      

      if since = query[:since]
        if !(query[:since] =~ /^\d\d\d\d-\d\d-\d\d([T\s]\d\d:\d\d(:\d\d(\+\d\d:\d\d|\s...)?)?)?$/)
          raise InvalidParameterValue.new(:since)          
        else
          cond_str << "created_at >= ?"
          cond_vars << Time.parse(since)
        end
      end

      if email = query[:email]
        cond_str << "email_address = ?"
        cond_vars << email
      end

      if cond_vars.size > 0 && cond_vars.size == cond_str.size
        regs = regs.all(:conditions=>[cond_str.join(" AND ")]+cond_vars)
      end

      regs.map do |reg|
        { :status               => reg.extended_status,
          :will_be_18_by_election => reg.will_be_18_by_election?,
          :create_time          => reg.created_at.to_s,
          :complete_time        => reg.completed_at.to_s,
          :lang                 => reg.locale,
          :first_reg            => reg.first_registration?,
          :home_zip_code        => reg.home_zip_code,
          :us_citizen           => reg.us_citizen?,
          :name_title           => reg.name_title,
          :first_name           => reg.first_name,
          :middle_name          => reg.middle_name,
          :last_name            => reg.last_name,
          :name_suffix          => reg.name_suffix,
          :home_address         => reg.home_address,
          :home_unit            => reg.home_unit,
          :home_city            => reg.home_city,
          :home_state_id        => reg.home_state_id,
          :has_mailing_address  => reg.has_mailing_address,
          :mailing_address      => reg.mailing_address,
          :mailing_unit         => reg.mailing_unit,
          :mailing_city         => reg.mailing_city,
          :mailing_state_id     => reg.mailing_state_id,
          :mailing_zip_code     => reg.mailing_zip_code,
          :race                 => reg.race,
          :party                => reg.party,
          :phone                => reg.phone,
          :phone_type           => reg.phone_type,
          :email_address        => reg.email_address,
          :opt_in_email         => reg.opt_in_email,
          :opt_in_sms           => reg.opt_in_sms,
          :opt_in_volunteer            => reg.volunteer?,
          :partner_opt_in_email => reg.partner_opt_in_email,
          :partner_opt_in_sms   => reg.partner_opt_in_sms,
          :partner_opt_in_volunteer    => reg.partner_volunteer?,
          :survey_question_1    => partner.send("survey_question_1_#{reg.locale}"),
          :survey_answer_1      => reg.survey_answer_1,
          :survey_question_2    => partner.send("survey_question_1_#{reg.locale}"),
          :survey_answer_2      => reg.survey_answer_2,
          :finish_with_state    => reg.finish_with_state?,
          :created_via_api      => reg.building_via_api_call?,
          :tracking_source      => reg.tracking_source,
          :tracking_id         => reg.tracking_id,
          :dob                  => reg.pdf_date_of_birth }
      end
    end


    def self.check_pdf_ready(query)
      reg = Registrant.find_by_uid(query[:UID])
      raise InvalidUIDError.new if reg.nil?
      return reg && reg.pdf_ready?
    end
    
    def self.stop_reminders(query)
      reg = Registrant.find_by_uid(query[:UID])
      raise InvalidUIDError.new if reg.nil?
      return {
        :first_name=>reg.first_name,
        :last_name=> reg.last_name,
        :email_address=>reg.email_address,
        :finish_iframe_url=> reg.finish_iframe_url,
        :locale => reg.locale,
        :partner_id=> reg.partner_id,
        :reminders_stopped=>reg.update_attributes(:reminders_left=>0)
      }
    end

    private

    def self.block_protected_attributes(attrs)
      raise ActiveRecord::UnknownAttributeError.new('unknown attribute: state_id_number') if attrs[:state_id_number].present?
    end

    def self.validate_language(reg)
      if reg.locale.nil?
        reg.errors.clear
        reg.errors.add(:lang, :blank)
        raise_validation_error(reg)
      end

      raise UnsupportedLanguageError if !reg.errors[:locale].empty?
    end

    def self.raise_validation_error(reg, error = reg.errors.sort.first)
      field = error.first

      # convert state_id_number into id_number
      field = 'id_number' if field == 'state_id_number'

      raise ValidationError.new(field, error.last)
    end

    def self.validate_survey_questions(attrs)
      [1,2].each do |qnum|
        raise SurveyQuestionError.new("Question #{qnum} required when Answer #{qnum} provided") if attrs["original_survey_question_#{qnum}".to_sym].blank? && !attrs["survey_answer_#{qnum}".to_sym].blank?
      end
    end


    def self.pa_data_to_attrs(data)
      
      attrs = data.clone
      attrs.symbolize_keys! if attrs.respond_to?(:symbolize_keys!)
      
      attrs.merge!(attrs[:voter_records_request].delete(:voter_registration))
      attrs.delete(:voter_records_request) # This only deletes the remaining stub, most keys have just been moved to the top level.
      attrs.delete(:registration_helper)
      attrs.delete(:gender)
      attrs.delete(:signature)
      attrs.delete(:additional_info)
      
      name = attrs.delete(:name)
      if name
        attrs[:name_title] = self.fix_pa_title(name[:title_prefix])
        attrs[:first_name] = name[:first_name]
        attrs[:middle_name] = name[:middle_name]
        attrs[:last_name] = name[:last_name]
        attrs[:name_suffix] = self.fix_pa_suffix(name[:title_suffix])
      end
      
      
      reg_address = attrs.delete(:registration_address)
      if reg_address && reg_address = reg_address.delete(:numbered_thoroughfare_address)
        attrs[:home_address]  = [
          reg_address[:complete_address_number],
          reg_address[:complete_street_name]
        ].join(" ").strip
        attrs[:home_unit] = reg_address[:complete_sub_address] ?  reg_address[:complete_sub_address][:sub_address] : nil
        # TODO do we know that these are always provided and in order?
        attrs[:home_city] = reg_address[:complete_place_names] && reg_address[:complete_place_names].any? ? reg_address[:complete_place_names][0][:place_name_value] : nil
        attrs[:home_county] = reg_address[:complete_place_names] && reg_address[:complete_place_names].length > 1 ? reg_address[:complete_place_names][1][:place_name_value] : nil
        attrs[:home_state] = GeoState[reg_address[:state].to_s.upcase] || GeoState.find_by_name(reg_address[:state])
        attrs[:home_zip_code] = reg_address[:zip_code]        
      end
      
      reg_equals_mailing = attrs.delete(:registration_address_is_mailing_address)
      mailing_address = attrs.delete(:mailing_address)
      if mailing_address && !reg_equals_mailing && mailing_address = mailing_address.delete(:numbered_thoroughfare_address) 
        attrs[:mailing_address]  = [
          mailing_address[:complete_address_number],
          mailing_address[:complete_street_name]
        ].join(" ").strip
        attrs[:mailing_unit] = mailing_address[:complete_sub_address] ?  mailing_address[:complete_sub_address][:sub_address] : nil
        attrs[:mailing_city] = mailing_address[:complete_place_names] && mailing_address[:complete_place_names].any? ? mailing_address[:complete_place_names][0][:place_name_value] : nil
        attrs[:mailing_county] = mailing_address[:complete_place_names] && mailing_address[:complete_place_names].length > 1 ? mailing_address[:complete_place_names][1][:place_name_value] : nil
        attrs[:mailing_state] = GeoState[mailing_address[:state].to_s.upcase] || GeoState.find_by_name(mailing_address[:state])
        attrs[:mailing_zip_code] = mailing_address[:zip_code]        
      end
      
      
      # Handle name/address changes
      prev_name = attrs.delete(:previous_name)
      if prev_name
        attrs[:change_of_name] = true
        attrs[:prev_name_title] = self.fix_pa_title(prev_name[:title_prefix])
        attrs[:prev_first_name] = prev_name[:first_name]
        attrs[:prev_middle_name] = prev_name[:middle_name]
        attrs[:prev_last_name] = prev_name[:last_name]
        attrs[:prev_name_suffix] = self.fix_pa_suffix(prev_name[:title_suffix])
      end
      prev_reg = attrs.delete(:previous_registration_address)
      if prev_reg && prev_reg = prev_reg.delete(:numbered_thoroughfare_address)
        attrs[:change_of_address] = true
        attrs[:prev_address]  = [
          prev_reg[:complete_address_number],
          prev_reg[:complete_street_name]
        ].join(" ").strip
        attrs[:prev_unit] = prev_reg[:complete_sub_address] ?  prev_reg[:complete_sub_address][:sub_address] : nil
        attrs[:prev_city] = prev_reg[:complete_place_names] && prev_reg[:complete_place_names].any? ? prev_reg[:complete_place_names][0][:place_name_value] : nil
        attrs[:prev_county] = prev_reg[:complete_place_names] && prev_reg[:complete_place_names].length > 1 ? prev_reg[:complete_place_names][1][:place_name_value] : nil
        attrs[:prev_state] = GeoState[prev_reg[:state].to_s.upcase] || GeoState.find_by_name(prev_reg[:state])
        attrs[:prev_zip_code] = prev_reg[:zip_code]        
      end
      
      classifications = attrs.delete(:voter_classifications)
      if classifications && classifications.any?
        classifications.each do |cls|
          case cls[:type]
          when "eighteen_on_election_day"
            attrs[:will_be_18_by_election] = cls[:assertion]
          when "united_states_citizen"
            attrs[:us_citizen] = cls[:assertion]
          end
        end
      end

      voter_ids = attrs.delete(:voter_ids)
      if voter_ids && voter_ids.any?
        voter_ids.each do |cls|
          case cls[:type]
          when "drivers_license"
            if cls[:attest_no_such_id]
              attrs[:has_state_license] = false
            else
              attrs[:has_state_license] = true
              attrs[:state_id_number] = cls[:string_value]
            end
          when "ssn4"
            if cls[:attest_no_such_id]
              attrs[:has_ssn] = false
            else
              attrs[:has_ssn] = true
              attrs[:state_id_number] = cls[:string_value]
            end
          end
        end
      end
      
      contacts = attrs.delete(:contact_methods)
      if contacts && contacts.any?
        contacts.each do |cls|
          case cls[:type]
          when "phone"
            attrs[:phone] = cls[:value]
            if cls[:capabilities].include?("sms")
              attrs[:phone_type] = I18n.t("txt.registration.phone_types.mobile")
            end
          when "email"
            attrs[:email_address] = cls[:value]
          end
        end
      end

      
      attrs[:locale] = attrs.delete(:lang)
      attrs[:volunteer] = attrs.delete(:opt_in_volunteer)
      attrs[:partner_volunteer] = attrs.delete(:partner_opt_in_volunteer)
      attrs.delete(:created_via_api)
      attrs[:tracking_source] = attrs.delete(:source_tracking_id)
      attrs[:tracking_id] = attrs.delete(:partner_tracking_id)
      attrs[:open_tracking_id] = attrs.delete(:open_tracking_id)
      
      if attrs[:email].blank?
        attrs[:collect_email_address] = 'no'
      end
      
      return attrs
      
    end

    def self.fix_pa_title(pa_title)
      unless pa_title == "Miss"
        return "#{pa_title}."
      else
        return pa_title
      end
    end
    
    def self.fix_pa_suffix(pa_suffix)
      return "Jr." if pa_suffix == "Jr"
      return "Sr." if pa_suffix == "Jr"
      return pa_suffix        
    end

    def self.data_to_attrs(data)
      attrs = data.clone
      attrs.symbolize_keys! if attrs.respond_to?(:symbolize_keys!)

      if l = attrs.delete(:lang)
        attrs[:locale] = l
      end

      if l = attrs.delete(:source_tracking_id)
        attrs[:tracking_source] = l
      end
      if l = attrs.delete(:partner_tracking_id)
        attrs[:tracking_id] = l
      end

      if l = attrs.delete(:opt_in_volunteer)
        attrs[:volunteer] = l
      end
      if l = attrs.delete(:partner_opt_in_volunteer)
        attrs[:partner_volunteer] = l
      end

      if l = attrs.delete(:id_number)
        attrs[:state_id_number] = l
      end


      if !(l = attrs.delete(:IsEighteenOrOlder)).nil?
        attrs[:will_be_18_by_election] = l
      end
      if !(l = attrs.delete(:is_eighteen_or_older)).nil?
        attrs[:will_be_18_by_election] = l
      end

      if l = attrs.delete(:survey_question_1)
        attrs[:original_survey_question_1] = l
      end
      if l = attrs.delete(:survey_question_2)
        attrs[:original_survey_question_2] = l
      end


      attrs = state_convert(attrs, :home_state)
      attrs = state_convert(attrs, :mailing_state)
      attrs = state_convert(attrs, :prev_state)

      attrs
    end

    def self.state_convert(attrs, field)
      l1 = attrs.delete(field)
      l2 = attrs.delete("#{field}_id".to_sym)
      l  = l2 || l1
      if l
        attrs["#{field}_id".to_sym] = GeoState[l.to_s.upcase].try(:id)
      end
      attrs
    end

  end
end
