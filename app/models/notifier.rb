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

  def tell_friends(tell_params)
    subject tell_params[:tell_subject]
    from "#{tell_params[:tell_from]} <#{tell_params[:tell_email]}>"
    recipients tell_params[:tell_recipients]
    sent_on Time.now.to_s(:db)
    body :message => tell_params[:tell_message]
  end

  protected

  def setup_registrant_email(registrant, kind)
    subject I18n.t("email.#{kind}.subject", :locale => registrant.locale.to_sym)
    from FROM_ADDRESS
    recipients registrant.email_address
    sent_on Time.now.to_s(:db)
    content_type "multipart/alternative"

    part "text/html" do |p|
      p.body = render_message("#{kind}.#{registrant.locale}.html.erb",
                              :pdf_url => "http://#{default_url_options[:host]}#{registrant.pdf_path}?source=email",
                              :cancel_reminders_url => registrant_finish_url(registrant, :protocol => "https", :reminders => "stop"),
                              :locale => registrant.locale.to_sym,
                              :registrar_phone => registrant.home_state.registrar_phone,
                              :registrar_address => registrant.home_state.registrar_address,
                              :registrar_url => registrant.home_state.registrar_url,
                              :registrant => registrant)
      p.transfer_encoding = "quoted-printable"
    end
  end
end
