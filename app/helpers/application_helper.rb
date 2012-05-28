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
module ApplicationHelper

  # flash_messages
  # use to display specified flash messages
  # defaults to standard set: [:success, :message, :warning]
  # example:
  #   <%= flash_messages %>
  # example with other keys:
  #   <%= flash_messages :notice, :violation %>
  # renders like:
  #  <ul class="flash">
  #   <li class="flash-success">Positive - successful action</li>
  #   <li class="flash-message">Neutral - reminders, status</li>
  #   <li class="flash-warning">Negative - error, unsuccessful action</li>
  #  </ul>
  def flash_messages(*keys)
    keys = [:success, :message, :warning] if keys.empty?
    messages = []
    keys.each do |key|
      messages << content_tag(:li, flash[key], :class => "flash-#{key}") if flash[key]
    end
    if messages.empty?
       content_tag(:div, "", :class => "flash")
    else
      content_tag(:ul, messages.join("\n"), :class => "flash")
    end
  end

  def partner_locale_options(partner, locale, source)
    opts = {}
    opts[:partner] = partner unless partner == Partner::DEFAULT_ID
    opts[:locale]  = locale  unless locale == "en"
    opts[:source]  = source  unless source.blank?
    opts
  end

  def partner_css
    if @partner && @partner.whitelabeled?
      stylesheet_link_tag @partner.application_css_present? ? @partner.application_css_url : "application"
      stylesheet_link_tag @partner.registration_css_present? ? @partner.registration_css_url : "registration"
    else
      stylesheet_link_tag "application", "registration"
    end
  end

  def yes_no_options
    [['', nil], ['Yes', true], ['No', false]]
  end

  def octothorpe(unit)
    unit =~ /^\d+$/ ? "##{unit}" : unit
  end

  def progress_indicator
    (1..5).map do |step_index|
      progress = case step_index <=> controller.current_step
      when -1 then "progress-done"
      when 0 then "progress-current"
      else "progress-todo"
      end
      content_tag :li, step_index, :class => progress
    end.join
  end

  def tooltip_tag(tooltip_id, content = t("txt.registration.tooltips.#{tooltip_id}"))
    image_tag 'buttons/help_icon.gif', :mouseover => 'buttons/help_icon_over.gif', :alt => t('txt.button.help'),
      :class => 'tooltip', :id => "tooltip-#{tooltip_id}",
      :title => content
  end

  def field_div(form, field, options={})
    kind = options.delete(:kind) || "text"
    selector = "#{kind}_field"
    has_error = form.object.errors.on(field) ? "has_error" : nil
    content_tag(:div, form.send( selector, field, {:size => nil}.merge(options) ), :class => has_error)
  end

  def select_div(form, field, contents, options={})
    has_error = form.object.errors.on(field) ? "has_error" : nil
    content_tag(:div, form.select(field, contents, options), :class => has_error)
  end

  def rollover_button(name, text)
    <<-HTML
      <div class="button">
        <a class="button_#{name}_#{I18n.locale}" href="#"><button type="submit" id="registrant_submit"><span>#{text}</span></button></a>
      </div>
    HTML
  end

  def rollover_image_link(name, text, url, options={})
    optional_attrs = options.inject("") {|s,(k,v)| s << %Q[ #{k}="#{v}"] }
    <<-HTML
      <span class="button">
        <a class="button_#{name}_#{I18n.locale}" href="#{url}"#{optional_attrs}><span>#{text}</span></a>
      </span>
    HTML
  end

  def partner_rollover_button(name, text)
    <<-HTML
      <div class="button">
        <a class="button_#{name}" href="#"><button type="submit" id="partner_submit"><span>#{text}</span></button></a>
      </div>
    HTML
  end
end
