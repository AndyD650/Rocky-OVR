class CanvassingShift < ActiveRecord::Base
  has_many :canvassing_shift_registrants, foreign_key: :shift_external_id, primary_key: :shift_external_id
  has_many :registrants, through: :canvassing_shift_registrants


  has_many :canvassing_shift_grommet_requests, foreign_key: :shift_external_id, primary_key: :shift_external_id
  has_many :grommet_requests, through: :canvassing_shift_grommet_requests

  belongs_to :partner

  validates_presence_of :shift_external_id

  SOURCE_WEB= 'WEB'.freeze
  SOURCE_GROMMET = 'GROMMET'.freeze
  SOURCES = [
    SOURCE_WEB,
    SOURCE_GROMMET
  ].freeze

  CSV_HEADER = [
    "Shift ID",
    "Shift Source",
    "Blocks Shift ID",
    "Blocks Shift Location ID",
    "Blocks Shift Location Name",
    "Canvasser Name",
    "Canvasser Phone",
    "Canvasser Email",
    "Shift Collection Start Time",
    "Shift Collection End Time",
    "Total Shift Time (Hours)",
    "Abandoned Registrations",
    "Completed Registrations",
    "Registrations with SSN",
    "Registrations with State ID",
    "Source Tracking ID",
    "Partner Tracking ID",
    "Open Tracking ID",
    "Device ID",
    "Submitted to Blocks?"
  ]

  validates_presence_of [:canvasser_first_name, :canvasser_last_name, :partner_id, :canvasser_phone, :canvasser_email, :shift_location], if: :is_web?
  validates_format_of :canvasser_phone, :with => /[ [:punct:]]*\d{3}[ [:punct:]]*\d{3}[ [:punct:]]*\d{4}\D*/, if: :is_web?, allow_blank: true
  validates_format_of :canvasser_email, :with => Authlogic::Regex::EMAIL, if: :is_web?, allow_blank: true

  after_save :check_submit_to_blocks

  def self.enabled_state_ids
    @@enabled_state_ids ||= RockyConf.blocks_configuration.states.collect {|abbrev| GeoState[abbrev].id }
  end

  def self.location_options(partner)
    b = BlocksService.new
    locations = begin b.get_locations(partner)&.[]("locations") rescue nil end;
    if locations && locations.any?
      return locations.map {|obj| [obj["name"], obj["id"]]}
    else
      default_location_id = begin
        RockyConf.blocks_configuration.partners[partner.id].location_id || RockyConf.blocks_configuration.default_location_id
      rescue
        nil
      end
      return [["Default Location", default_location_id]] if default_location_id
    end
    return []
  end

  def shift_location=(value)
    self[:shift_location] = value
    location_options = CanvassingShift.location_options(self.partner)
    location_options.each do |name, id|
      self.blocks_shift_location_name = name if id.to_s.strip == value.to_s.strip
    end
    value
  end

  def to_csv_array
    [
      shift_external_id,
      shift_source,
      blocks_shift_id,
      shift_location,
      blocks_shift_location_name,
      canvasser_name,
      canvasser_phone,
      canvasser_email,
      clock_in_datetime && clock_in_datetime.in_time_zone("America/New_York").to_s,
      clock_out_datetime && clock_out_datetime.in_time_zone("America/New_York").to_s,
      clock_in_datetime && clock_out_datetime ? (clock_out_datetime - clock_in_datetime).to_f / 3600.0 : nil,
      abandoned_registrations,
      completed_registrations,
      # Regs who finish with paper never have an SSN
      registrants.select {|r| r.has_ssn?  && r.complete? && !r.pdf_ready? }.length,
      registrants.select {|r| r.has_state_license? && r.complete? }.length,
      source_tracking_id,
      partner_tracking_id,
      open_tracking_id,
      device_id,
      yes_no(submitted_to_blocks)
    ]
  end
  
  def yes_no(attribute)
    attribute ? "Yes" : "No"
  end

  def is_web?
    self.shift_source == SOURCE_WEB
  end
  def is_grommet?
    self.shift_source == SOURCE_GROMMET
  end
  
  def blocks_shift_type
    is_grommet? ? "voter_registration" : "digital_voter_registration"
  end
  
  def locale
    :en
  end

  def new_registrant_url
    Rails.application.routes.url_helpers.new_registrant_url(shift_id: self.shift_external_id, host: RockyConf.default_url_host)
  end
  
  def show_shift_url
    Rails.application.routes.url_helpers.canvassing_shifts_url(host: RockyConf.default_url_host)
  end

  def canvasser_name
    [canvasser_first_name.to_s.strip, canvasser_last_name.to_s.strip].collect{|n| n.blank? ? nil : n}.compact.join(" ")
  end

  def canvasser_name=(name)
    name_parts = name.to_s.strip.split(" ")
    self.canvasser_first_name = name_parts.shift || ""
    self.canvasser_last_name = name_parts.join(" ") #Remaining parts
    canvasser_name
  end

  def set_attributes_from_data!(data)
    set_attribute_from_data(:shift_location, data, :canvass_location_id)
    %w(partner_id
      source_tracking_id
      partner_tracking_id
      geo_location
      open_tracking_id
      canvasser_name
      canvasser_first_name
      canvasser_last_name
      canvasser_phone
      canvasser_email
      clock_in_datetime
      clock_out_datetime
      device_id
      abandoned_registrations
      completed_registrations
    ).each do |attribute|
      set_attribute_from_data(attribute, data)
    end

    self.save!
    return self
  end

  def web_complete_registrants
    self.registrants.where("status = ? or finish_with_state = ?", :complete, true)
  end
  def web_abandoned_registrants
    self.registrants.abandoned.where.not(status: :complete)
  end

  def set_counts
    self.completed_registrations = web_complete_registrants.count
    self.abandoned_registrations = web_abandoned_registrants.count
  end

  def is_ready_to_submit?
    !!(self.clock_in_datetime && self.clock_out_datetime && self.complete?)
  end
  
  def complete!
    self.complete = true
    self.save!
  end

  

  def check_submit_to_blocks
    if !submitted_to_blocks? && is_ready_to_submit?
      self.delay.submit_to_blocks # TODO: should delay for amount of abandoned time?
    end
  end

  def submit_to_blocks
    if !submitted_to_blocks? && is_ready_to_submit?
      service = BlocksService.new
      created_shift = service.upload_canvassing_shift(self, shift_type: blocks_shift_type)
      forms = created_shift[:forms]
      shift = created_shift[:shift]
      self.update_attributes(submitted_to_blocks: true, blocks_shift_id: shift["shift"]["id"])
      registrants_or_requests.each_with_index do |reg_req, i|
        form_result = get_form_from_reg_req(reg_req, forms, i)
        # Make sure form_result maps to reg_req
        if form_result #form_matches_request(form_result, reg_req)
          form_id = form_result["id"]
          registrant_id = reg_req.is_a?(Registrant) ? reg_req.uid : nil
          grommet_request_id = reg_req.is_a?(Registrant) ? reg_req.state_ovr_data["grommet_request_id"] : reg_req.id
          BlocksFormDisposition.create!(blocks_form_id: form_id, registrant_id: registrant_id, grommet_request_id: grommet_request_id)
        else
          puts "No form result for #{reg_req} #{i}"
        end
      end
    end
  end
  
  def get_form_from_reg_req(reg_req, forms, i)
    # Expect the index to match
    form = forms[i]
    return form if form_matches_request(form, reg_req)
    # Otherwise, loop through to find a match
    forms.each do |form_result|
      return form_result if form_matches_request(form_result, reg_req)
    end
    return nil
  end
  
  
  # TODO: Used to ensure blocks ID matches this request
  def form_matches_request(form_result, r)
    return false if form_result.nil? || r.nil?
    built_form = if r.is_a?(Registrant)
      BlocksService.form_from_registrant(r)
    elsif r.is_a?(GrommetRequest)
      BlocksService.form_from_grommet_request(r)
    end
    
    uid = form_result["metadata"].try(:[], "rtv_uid")
    unless uid.blank?
      return uid == built_form[:metadata][:rtv_uid]
    end
    
    return true if form_result["first_name"]==built_form[:first_name] && form_result["last_name"]==built_form[:last_name] && form_result["date_of_birth"] == built_form[:date_of_birth]

    return false
  end

  def registrants_or_requests
    @regs ||= nil
    if !@regs
      if self.is_web?
        @regs = self.web_complete_registrants.where(home_state_id: CanvassingShift.enabled_state_ids)
      elsif self.is_grommet?
        @regs = []
        registrant_grommet_ids = []
        self.registrants.each do |r|
          registrant_grommet_ids << r.state_ovr_data["grommet_request_id"]
          @regs << r
        end
        self.grommet_requests.each do |req|
          unless registrant_grommet_ids.include?(req.id)
            @regs << req
          end
        end
      else
        @regs = []
      end
    end
    return @regs
  end

  def generate_shift_external_id
    prefix = is_web? ? "web-" : "grommet-"
    self.shift_external_id = prefix + Digest::SHA1.hexdigest( "#{Time.now.usec} -- #{rand(1000000)} -- #{canvasser_name} -- #{partner_id}" )
  end


  private
  def set_attribute_from_data(attribute_name, data, data_attribute=nil)
    data_attribute ||= attribute_name
    #only update if not nil
    self.send("#{attribute_name}=", data[data_attribute]) if !data[data_attribute].blank?
  end

end
