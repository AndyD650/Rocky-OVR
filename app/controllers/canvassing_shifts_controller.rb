class CanvassingShiftsController < ApplicationController
  CURRENT_STEP = 0
  
  include ApplicationHelper

  layout "registration"
  before_filter :find_partner
  before_filter :find_canvassing_shift
  
  
  def new
    @new_canvassing_shift = CanvassingShift.new
  end
  
  def create
    @new_canvassing_shift = CanvassingShift.new(cs_params)
    @new_canvassing_shift.partner_id = params[:partner_id]
    @new_canvassing_shift.source_tracking_id = params[:source_tracking_id]
    @new_canvassing_shift.partner_tracking_id = params[:partner_tracking_id]
    @new_canvassing_shift.open_tracking_id = params[:open_tracking_id]
    @new_canvassing_shift.device_id = "web-#{request.ip}" #User IP? 
    @new_canvassing_shift.generate_shift_external_id
    @new_canvassing_shift.shift_location ||= RockyConf.blocks_configuration.default_location_id
    @new_canvassing_shift.clock_in_datetime = DateTime.now
    if @new_canvassing_shift.save
      # If existing shift, clock it out
      if @canvassing_shift
        @canvassing_shift.clock_out_datetime = DateTime.now
        @canvassing_shift.save!
      end
      session[:canvassing_shift_id] = @new_canvassing_shift.id
      redirect_to new_registrant_path(partner: @partner.id)
    else
      render action: :new
    end
    
  end
  
  def clock_out
    if @canvassing_shift
      @canvassing_shift.clock_out_datetime = DateTime.now
      @canvassing_shift.set_counts
      @canvassing_shift.save!
      flash[:message] = "#{@canvassing_shift.canvasser_name} clocked out at #{l @canvassing_shift.clock_out_datetime}"
    end
    session[:canvassing_shift_id] = nil
    redirect_to action: :new
  end
  
  
  def current_step
    self.class::CURRENT_STEP
  end
  hide_action :current_step


  private
  
  def cs_params
    params.require(:canvassing_shift).permit(:canvasser_name, :canvasser_phone)
  end
  
  def find_partner
    @partner = Partner.find_by_id(params[:partner]) || Partner.find(Partner::DEFAULT_ID)
    set_params
  end
  
  def set_params
    @source_tracking = params[:source] #source_tracking_id
    @partner_tracking = params[:tracking] #partner_tracking_id
    @open_tracking = params[:open_tracking] #open_tracking_id
  end
  
  
  
end
