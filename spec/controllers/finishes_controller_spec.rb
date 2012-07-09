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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ActionView::Helpers::UrlHelper

describe FinishesController do
  integrate_views

  describe "waiting for delayed job to complete registration" do
    before(:each) do
      @registrant = Factory.create(:step_5_registrant)
    end
    it "renders :complete partial when still in step_5" do
      get :show, :registrant_id => @registrant.to_param
      assert_response :success
      assert_select "h1", "Spread the word!"
    end
  end

  describe "complete registration" do
    before(:each) do
      @registrant = Factory.create(:completed_registrant)
    end

    it "sets default content for message body" do
      get :show, :registrant_id => @registrant.to_param
      assert_match %r(Hey, I just registered to vote), assigns[:registrant].tell_message
      assert_match Regexp.compile(Regexp.escape(root_url(:source => "email"))), assigns[:registrant].tell_message
    end

    it "shows share links and tell-a-friend email form" do
      get :show, :registrant_id => @registrant.to_param
      assert_not_nil assigns[:registrant]
      assert_response :success
      assert_template "finish"

      assert_select "h1", "Spread the word!"

      assert_share_links "I just registered to vote and you can too!"

      # Disabled until spammers can be stopped
      # assert_select "form div.button a.button_send_email_en"
    end
  end

  describe "under 18" do
    before(:each) do
      @registrant = Factory.create(:under_18_finished_registrant)
    end

    it "sets default content for message body" do
      get :show, :registrant_id => @registrant.to_param
      assert_match %r(Are you registered to vote\? I may not be old enough to vote), assigns[:registrant].tell_message
      assert_match Regexp.compile(Regexp.escape(root_url(:source => "email"))), assigns[:registrant].tell_message
    end

    it "shows share links and tell-a-friend email form" do
      get :show, :registrant_id => @registrant.to_param

      assert_select "h1", "You're on the list!"
      assert_share_links "Make sure you register to vote. It's easy!"

      # Disabled until spammers can be stopped
      # assert_select "form div.button a.button_send_email_en"
    end
  end

  def assert_share_links(share_text)
    assert_select "div.share div", 2

    assert_select "a[class=button_share_facebook_en][href=http://www.facebook.com/sharer.php?u=#{FACEBOOK_CALLBACK_URL}&t=#{CGI.escape(share_text)}]"

    escaped = CGI.escape(share_text + " " + root_url)
    href = "http://twitter.com/home"
    href << "?status=#{escaped}"
    assert_select "a[class=button_share_twitter_en][href=#{href}]"

    
  end

  describe "stop reminders" do
    it "stops remaining emails from coming" do
      reg = Factory.create(:completed_registrant, :reminders_left => 2)
      get :show, :registrant_id => reg.to_param, :reminders => "stop"
      reg.reload
      assert_equal 0, reg.reminders_left
    end

    describe "feedback page" do
      integrate_views
      it "should show thank you message" do
        reg = Factory.create(:completed_registrant, :reminders_left => 2)
        get :show, :registrant_id => reg.to_param, :reminders => "stop"
        assert_select "h1", "Thanks for Registering!"
        assert_match /Hey, I just registered to vote/, assigns[:registrant].tell_message
      end
    end
  end

  describe "PDF not ready" do
    integrate_views
    it "includes text about pending PDF" do
      reg = Factory.create(:step_5_registrant, :pdf_ready => false)
      get :show, :registrant_id => reg.to_param
      assert_select "h1", "Check Your Email"
      assert_match /Hey, I just registered to vote/, assigns[:registrant].tell_message
    end
  end

end
