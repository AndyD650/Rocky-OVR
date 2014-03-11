#***** BEGIN LICENSE BLOCK *****
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

class StateCustomization
  
  attr_accessor :state
  
  def self.for(state)
    klass = class_exists?(state.abbreviation) ?  state.abbreviation.constantize : self
    klass.new(state)
  end
  
  def initialize(state)
    @state = state
  end
  
  def online_reg_enabled?(locale, registrant = nil)
    GeoState.states_with_online_registration.include?(state.abbreviation) && self.enabled_for_language?(locale)
  end
  
  def enabled_for_language?(lang)
    lang_list = RockyConf.ovr_states[state.abbreviation]
    return true if lang_list.blank?
    lang_list = lang_list["languages"]
    return true if lang_list.blank? || lang_list.empty?
    return lang_list.include?(lang)
  end
  
  
  def online_reg_url(registrant)
    state.online_registration_url
  end
  
  def redirect_to_online_reg_url(registrant)
    state.redirect_to_online_registration_url?
  end
  
  def has_ovr_pre_check?(registrant)
    false
  end
  
  def ovr_pre_check(registrant=nil, controller=nil)
    raise "Not Implemented"
  end
  
  def decorate_registrant(registrant=nil, controller=nil)
  end
  
  
protected
  def self.class_exists?(class_name)
    klass = Module.const_get(class_name)
    return klass.is_a?(Class)
  rescue NameError
    return false
  end
  
end