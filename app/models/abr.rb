class Abr < ActiveRecord::Base
  belongs_to :home_state,    :class_name => "GeoState"
  
  include RegistrantMethods
  
  def locale
    'en'
  end
  
  def require_email_address?
    true
  end
  
  def home_state_abbrev
    home_state && home_state.abbreviation
  end
  
  
end
