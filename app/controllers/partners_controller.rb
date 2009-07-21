class PartnersController < ApplicationController
  before_filter :require_partner, :only => [:show, :edit, :update]
  
  def show
    @widget_html = <<-HTML
<div id="widget_box">
  <a href="#{new_registrant_url(:partner => partner_id)}" id="rtv-widget-link">
    <img src="http://www.rockthevote.com/assets/images/pages/home/top-boxes/register_to_vote.jpg"></img>
  </a>
  <script type="text/javascript" src="#{widget_loader_partner_url(partner_id, :format => 'js')}"></script>
</div>
HTML

    @link_html = <<-HTML
<a href="#{new_registrant_url(:partner => partner_id)}">
  <img src="http://www.rockthevote.com/assets/images/pages/home/top-boxes/register_to_vote.jpg"></img>
</a>
HTML
  end

  def widget_loader
    @partner_id = params[:id]
    @host = host_url
  end

  protected

  def host_url
    "#{request.protocol}#{request.host_with_port}"
  end
  
  def partner_id
    current_partner && current_partner.to_param
  end
end
