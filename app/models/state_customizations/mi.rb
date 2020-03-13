class MI < StateCustomization
  def enabled_for_language?(locale, reg=nil)
    # This is for transitions to onine state registration vs direct API calls
    if Rails.env.staging2? || Rails.env.development?
      false
    else
      super
    end
  end
  
  def use_state_flow?(registrant)
    if Rails.env.staging2?  || Rails.env.development?
      #return false
      return false if ovr_settings.blank?
      lang_list = ovr_settings["languages"]
      return true if lang_list.blank? || lang_list.empty?
      return lang_list.include?(registrant.locale)    
    
      # return false if reg && !reg.has_state_license? && reg.does_not_have_ssn4?
      # return false if reg && !reg.will_be_18_by_election?
    else
      super
    end
    
  end
  
end