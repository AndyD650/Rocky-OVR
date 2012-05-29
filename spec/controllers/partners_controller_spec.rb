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

describe PartnersController do

  describe "registering" do
    it "creates a new partner" do
      assert_difference("Partner.count") do
        post :create, :partner => Factory.attributes_for(:partner)
      end
      assert_not_nil assigns[:partner]
    end

    it "creates a new partner with correct opt-in defaults (true for RTV, false for partner settings)" do
      post :create, :partner => Factory.attributes_for(:partner)
      assigns[:partner].rtv_email_opt_in.should be_true
      assigns[:partner].partner_email_opt_in.should be_false
      assigns[:partner].rtv_sms_opt_in.should be_true
      assigns[:partner].partner_sms_opt_in.should be_false
      assigns[:partner].ask_for_volunteers.should be_true
      assigns[:partner].partner_ask_for_volunteers.should be_false
    end

    it "requires login, email and password for new partner" do
      assert_no_difference("Partner.count") do
        post :create, :partner => Factory.attributes_for(:partner, :username => nil)
      end
      assert_template "new"
    end
  end

  describe "when not logged in" do
    before(:each) do
      @no_login_actions = %w[new create]
    end

    it "requires login for partner-only actions" do
      (PartnersController.public_instance_methods(false) - @no_login_actions).each do |act|
        get act
        assert_redirected_to login_url, "did not prevent no-login access to #{act}"
      end
    end

    it "allows public access to some actions" do
      @no_login_actions.each do |act|
        get act
        assert_response :success, "did not allow no-login access to #{act}"
      end
    end
  end

  describe "when logged in" do
    before(:each) do
      activate_authlogic
      @partner = Factory.create(:partner, :id => 5)
      PartnerSession.create(@partner)
    end

    describe "dashboard" do
      integrate_views

      it "highlights dashboard nav link as current" do
        get :show
        assert_select "a.current", "Dashboard"
      end
    end

    describe "embed codes" do
      integrate_views

      before do
        stub(request).host { "example.com" }
        @partner.update_attributes :widget_image_name => "rtv100x100v1"
        get :embed_codes
        assert_response :success
      end

      it "shows widget html for plain text link" do
        assert_select 'textarea[name=text_link_html][readonly]', 1
        html = HTML::Node.parse(nil, 0, 0, assigns(:text_link_html))
        assert_select html, "a[href=https://example.com/?partner=5]"
        assert_match />Register to Vote Here</, assigns(:text_link_html)
      end

      it "shows widget html for image link" do
        assert_select 'textarea[name=image_link_html][readonly]', 1
        assert_match %r{<img src=.*/images/widget/rtv-100x100-v1.gif}, assigns(:image_link_html)
        html = HTML::Node.parse(nil, 0, 0, assigns(:image_link_html))
        assert_select html, "a[href=https://example.com/?partner=5&source=embed-rtv100x100v1]"
      end

      it "shows widget html for image overlay widget" do
        assert_select 'textarea[name=image_overlay_html][readonly]', 1
        html = HTML::Node.parse(nil, 0, 0, assigns(:image_overlay_html))
        assert_select html, "a[href=https://example.com/?partner=5&source=embed-rtv100x100v1][class=floatbox][data-fb-options='width:618 height:max scrolling:yes']"
        assert_match %r{<img src=.*/images/widget/rtv-100x100-v1.gif}, assigns(:image_overlay_html)
        html = HTML::Node.parse(nil, 0, 0, assigns(:image_overlay_html).split("\n").last)
        assert_select html, "script[type=text/javascript][src=https://example.com/widget_loader.js]"
      end
    end

    describe "statistics" do
      it "shows registration statistics" do
        get :statistics
        assert_response :success
        assert_not_nil assigns[:stats_by_state]
        assert_not_nil assigns[:stats_by_completion_date]
        assert_not_nil assigns[:stats_by_race]
        assert_not_nil assigns[:stats_by_gender]
        assert_not_nil assigns[:stats_by_age]
        assert_not_nil assigns[:stats_by_party]
      end
    end

    describe "profile" do
      integrate_views

      it "shows profile edit form" do
        get :edit
        assert_response :success
        assert_equal @partner, assigns[:partner]
        assert_select "form[action=/partner]"
      end

      it "shows dashboard after updating" do
        put :update, :partner => {:name => "Friends of the Moose"}
        assert_redirected_to partner_url
      end

      it "update requires valid input" do
        put :update, :partner => {:email => "bogus!!!!!"}
        assert_response :success
        assert_template "edit"
      end
    end

    describe "download registration data" do
      it "triggers download" do
        this_moment = Time.now
        stub(Time).now { this_moment }
        now = this_moment.to_s(:db).gsub(/\D/,'')
        get :registrations, :format => 'csv'
        assert_response :success
        assert_equal "text/csv", response.headers["Content-Type"]
        assert_equal %Q(attachment; filename="registrations-#{now}.csv"), response.headers["Content-Disposition"]
      end
    end
  end
end
