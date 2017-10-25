module RegistrantMethods
  def at_least_step?(step)
    current_step = step_index
    !current_step.nil? && (current_step >= step)
  end

  def prev_step(current_state = nil)
    idx = step_index(current_state)
    if !idx.nil?
      return step_list[idx-1]
    else
      return current_state || aasm_current_state
    end
  end

  def next_step(current_state = nil)
    idx = step_index(current_state)
    if !idx.nil?
      return step_list[idx+1]
    else
      return current_state || aasm_current_state
    end
  end

  def step_index(current_state = nil)
    step_list.index(current_state || aasm_current_state)
  end

  def at_least_step_1?
    at_least_step?(1)
  end

  def at_least_step_2?
    at_least_step?(2)
  end

  def at_least_step_3?
    at_least_step?(3)
  end

  def at_least_step_4?
    at_least_step?(4)
  end

  def at_least_step_5?
    at_least_step?(5)
  end
  
  
  def validate_date_of_birth
    return if date_of_birth_before_type_cast.is_a?(Date) || date_of_birth_before_type_cast.is_a?(Time)
    if date_of_birth_before_type_cast.blank?
      errors.add(:date_of_birth, :blank)
    else
      @raw_date_of_birth = date_of_birth_before_type_cast
      date = nil
      if matches = date_of_birth_before_type_cast.to_s.match(/^(\d{1,2})\D+(\d{1,2})\D+(\d{4})$/)
        m,d,y = matches.captures
        date = Date.civil(y.to_i, m.to_i, d.to_i) rescue nil
      elsif matches = date_of_birth_before_type_cast.to_s.match(/^(\d{4})\D+(\d{1,2})\D+(\d{1,2})$/)
        y,m,d = matches.captures
        date = Date.civil(y.to_i, m.to_i, d.to_i) rescue nil
      end
      if date
        @raw_date_of_birth = nil
        self[:date_of_birth] = date
      else
        errors.add(:date_of_birth, :format)
      end
    end
  end
  
  
  
  def key_for_attribute(attr_name, i18n_list)
    key_value = I18n.t("txt.registration.#{i18n_list}", :locale=>locale).detect{|k,v| v==self.send(attr_name)}
    key_value && key_value.length == 2 ? key_value[0] : nil    
  end
  
  def english_attribute_value(key, i18n_list)
    key.nil? ? nil : I18n.t("txt.registration.#{i18n_list}.#{key}", :locale=>:en)
  end
  
  def english_races
    Registrant.english_races
  end


  
  def english_race
    Registrant.english_race(locale, race)
  end
  
  def race_key
    Registrant.race_key(locale, race)
  end
  

  def state_parties
    if requires_party?
      localization ? localization.parties + [ localization.no_party ] : []
    else
      []
    end
  end
  
  def set_official_party_name
    return unless self.step_5? || self.complete?
    self.official_party_name = detect_official_party_name
  end
  
  
  def detect_official_party_name
    if party.blank?
      I18n.t('states.no_party_label.none')
    else
      return party if en_localization[:parties].include?(party)
      if locale.to_s == "en"
        return party == en_localization.no_party ? I18n.t('states.no_party_label.none') : party
      else
        if party == localization.no_party
          return I18n.t('states.no_party_label.none', :locale=>:en)
        else
          if (p_index = localization[:parties].index(party))
            return en_localization[:parties][p_index]
          else
            Rails.logger.warn "***** UNKNOWN PARTY:: registrant: #{id}, locale: #{locale}, party: #{party}"
            return nil
          end
        end
      end
    end
  end
  
  def english_state_parties
    if requires_party?
      en_localization ? en_localization.parties + [ en_localization.no_party ] : []
    else
      []
    end    
  end

  
  def english_party_name
    if locale.to_s == 'en' || english_state_parties.include?(party)
      return party
    else
      if (p_idx = state_parties.index(party))
        return english_state_parties[p_idx]
      else
        return nil
      end
    end
  end
  
end