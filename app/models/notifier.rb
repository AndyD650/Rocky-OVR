class Notifier < ActionMailer::Base
  def password_reset_instructions(partner)
    subject "Password Reset Instructions"
    from FROM_ADDRESS
    recipients partner.email
    sent_on Time.now.to_s(:db)
    body :url => edit_password_reset_url(:id => partner.perishable_token)
  end

  def confirmation(registrant)
    setup_registrant_email(registrant, 'confirmation')
  end

  def reminder(registrant)
    setup_registrant_email(registrant, 'reminder')
  end

  protected

  def setup_registrant_email(registrant, type)
    subject I18n.t("email.#{type}.subject", :locale => registrant.locale.to_sym)
    from FROM_ADDRESS
    recipients registrant.email_address
    sent_on Time.now.to_s(:db)
    body :pdf_url => "http://#{default_url_options[:host]}#{registrant.pdf_path}",
         :locale => registrant.locale.to_sym,
         # TODO: strip HTML from address when rendering in plain text
         :registrar_phone => registrant.home_state.registrar_phone,
         :registrar_address => registrant.home_state.registrar_address
  end
end
