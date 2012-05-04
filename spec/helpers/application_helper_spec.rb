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
require File.dirname(__FILE__) + "/../spec_helper"
require 'hpricot'

describe ApplicationHelper do
  describe "partner_locale_options" do
    it "shows partner, locale and source" do
      opts = helper.partner_locale_options(2, "es", "email")
      assert_equal 2, opts[:partner]
      assert_equal "es", opts[:locale]
      assert_equal "email", opts[:source]
    end

    it "shows partner but not default locale" do
      opts = helper.partner_locale_options(2, "en", nil)
      assert_equal 2, opts[:partner]
      assert_nil opts[:locale]
    end

    it "shows locale but not default partner" do
      opts = helper.partner_locale_options(1, "es", nil)
      assert_nil opts[:partner]
      assert_equal "es", opts[:locale]
    end

    it "shows neither default partner nor default locale" do
      opts = helper.partner_locale_options(1, "en", nil)
      assert_nil opts[:partner]
      assert_nil opts[:locale]
    end

    it "omits blank source" do
      opts = helper.partner_locale_options(2, "es", nil)
      assert !opts.has_key?(:source)
    end
  end
  
  describe "partner_css" do
    it "is pending"
  end
  

  describe "form helpers" do
    attr_accessor :form
    before(:each) do
      @form = Object.new
      partner = Partner.new
      stub(form).object { partner }
      stub(form).text_field { '<input type="text">' }
      stub(form).password_field { '<input type="password">' }
    end

    it "makes a text field by default" do
      html = helper.field_div(form, :name)
      assert_match /input type="text"/, html
    end

    it "uses :kind option to make a different type of field" do
      html = helper.field_div(form, :name, :kind => "password")
      assert_match /input type="password"/, html
    end
  end
end
