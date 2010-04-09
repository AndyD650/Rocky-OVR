class Partner < ActiveRecord::Base
  acts_as_authentic

  belongs_to :state, :class_name => "GeoState"
  has_many :registrants

  has_attached_file :logo, PAPERCLIP_OPTIONS.merge(:styles => { :header => "75x45" })

  before_validation :reformat_phone
  before_validation :set_default_widget_image

  validates_presence_of :name
  validates_presence_of :url
  validates_presence_of :address
  validates_presence_of :city
  validates_presence_of :state_id
  validates_presence_of :zip_code
  validates_format_of :zip_code, :with => /^\d{5}(-\d{4})?$/, :allow_blank => true
  validates_presence_of :phone
  validates_format_of :phone, :with => /^\d{3}-\d{3}-\d{4}$/, :message => 'Phone must look like ###-###-####', :allow_blank => true
  validates_presence_of :organization

  validates_attachment_size :logo, :less_than => 1.megabyte, :message => "Logo must not be bigger than 1 megabyte"
  validates_attachment_content_type :logo, :message => "Logo must be a JPG, GIF, or PNG file",
                                    :content_type => ['image/jpeg', 'image/jpg', 'image/pjpeg', 'image/png', 'image/x-png', 'image/gif']

  after_validation :make_paperclip_errors_readable


  def self.find_by_login(login)
    find_by_username(login) || find_by_email(login)
  end

  def self.default_id
    1
  end

  def primary?
    self.id == self.class.default_id
  end

  def custom_logo?
    !primary? && logo.file?
  end

  def registration_stats_state
    counts = Registrant.connection.select_all(<<-"SQL")
      SELECT count(*) as registrations_count, home_state_id FROM `registrants`
      WHERE (status = 'complete' OR status = 'step_5') AND partner_id = #{self.id}
      GROUP BY home_state_id
    SQL
    sum = counts.sum {|row| row["registrations_count"].to_i}
    named_counts = counts.collect do |row|
      { :state_name => GeoState[row["home_state_id"].to_i].name,
        :registrations_count => (c = row["registrations_count"].to_i),
        :registrations_percentage => c.to_f / sum
      }
    end
    named_counts.sort_by {|r| [-r[:registrations_count], r[:state_name]]}
  end

  def registration_stats_race
    counts = Registrant.connection.select_all(<<-"SQL")
      SELECT count(*) as registrations_count, race, locale FROM `registrants`
      WHERE (status = 'complete' OR status = 'step_5') AND partner_id = #{self.id}
      GROUP BY race
    SQL

    en_races = I18n.backend.send(:lookup, :en, "txt.registration.races")
    es_races = I18n.backend.send(:lookup, :es, "txt.registration.races")
    counts, es_counts = counts.partition { |row| row["locale"] == "en" || !es_races.include?(row["race"]) }
    counts.each do |row|
      if ( i = en_races.index(row["race"]) )
        race_name_es = es_races[i]
        es_row = nil
        es_counts.reject! {|r| es_row = r if r["race"] == race_name_es }
        row["registrations_count"] = row["registrations_count"].to_i + es_row["registrations_count"].to_i if es_row
      else
        row["race"] = "Unknown"
      end
    end
    es_counts.each do |row|
      row["race"] = en_races[ es_races.index(row["race"]) ]
      counts << row
    end

    sum = counts.sum {|row| row["registrations_count"].to_i}
    named_counts = counts.collect do |row|
      { :race => row["race"],
        :registrations_count => (c = row["registrations_count"].to_i),
        :registrations_percentage => c.to_f / sum
      }
    end
    named_counts.sort_by {|r| [-r[:registrations_count], r[:race]]}
  end

  def registration_stats_gender
    counts = Registrant.connection.select_all(<<-"SQL")
      SELECT count(*) as registrations_count, name_title FROM `registrants`
      WHERE (status = 'complete' OR status = 'step_5') AND partner_id = #{self.id}
      GROUP BY name_title
    SQL

    male_titles = [I18n.backend.send(:lookup, :en, "txt.registration.titles")[0], I18n.backend.send(:lookup, :es, "txt.registration.titles")[0]]
    male_count = female_count = 0

    counts.each do |row|
      if male_titles.include?(row["name_title"])
        male_count += row["registrations_count"].to_i
      else
        female_count += row["registrations_count"].to_i
      end
    end

    sum = male_count + female_count
    [ { :gender => "Male",
        :registrations_count => male_count,
        :registrations_percentage => male_count.to_f / sum
      },
      { :gender => "Female",
        :registrations_count => female_count,
        :registrations_percentage => female_count.to_f / sum
      }
    ].sort_by { |r| [ -r[:registrations_count], r[:gender] ] }
  end

  def registration_stats_age
    conditions = "partner_id = ? AND (status = 'complete' OR status = 'step_5') AND (age BETWEEN ? AND ?)"
    stats = {}
    stats[:age_under_18]  = { :count => Registrant.count(:conditions => [conditions, self, 0, 17]) }
    stats[:age_18_to_29]  = { :count => Registrant.count(:conditions => [conditions, self, 18, 29]) }
    stats[:age_30_to_39]  = { :count => Registrant.count(:conditions => [conditions, self, 30, 39]) }
    stats[:age_40_to_64]  = { :count => Registrant.count(:conditions => [conditions, self, 40, 64]) }
    stats[:age_65_and_up] = { :count => Registrant.count(:conditions => [conditions, self, 65, 199]) }
    total_count = stats.inject(0) {|sum, (key,stat)| sum + stat[:count]}
    stats.each { |key, stat| stat[:percentage] = percentage(stat[:count], total_count) }
    stats
  end

  def registration_stats_party
    sql = <<-SQL
      SELECT official_party_name, count(registrants.id) AS registrants_count FROM registrants
      INNER JOIN geo_states ON geo_states.id = registrants.home_state_id
      WHERE registrants.partner_id = #{self.id}
        AND (status = 'complete' OR status = 'step_5')
      GROUP BY official_party_name
      ORDER BY registrants_count DESC, official_party_name
    SQL

    stats = self.class.connection.select_all(sql)
    total_count = stats.inject(0) { |sum, row| sum + row['registrants_count'].to_i }
    stats.collect do |row|
      { :party => row['official_party_name'],
        :count => row['registrants_count'].to_i,
        :percentage => percentage(row['registrants_count'], total_count)
      }
    end
  end

  def percentage(count, total_count)
    total_count > 0 ? count.to_f / total_count : 0.0
  end

  def registration_stats_completion_date
    conditions = "partner_id = ? AND (status = 'complete' OR status = 'step_5') AND created_at >= ?"
    stats = {}
    stats[:day_count] =   Registrant.count(:conditions => [conditions, self, 1.day.ago])
    stats[:week_count] =  Registrant.count(:conditions => [conditions, self, 1.week.ago])
    stats[:month_count] = Registrant.count(:conditions => [conditions, self, 1.month.ago])
    stats[:year_count] =  Registrant.count(:conditions => [conditions, self, 1.year.ago])
    stats[:total_count] = Registrant.count(:conditions => ["partner_id = ? AND (status = 'complete' OR status = 'step_5')", self])
    stats[:percent_complete] = stats[:total_count].to_f / Registrant.count(:conditions => ["partner_id = ? AND (status != 'initial')", self])
    stats
  end

  def state_abbrev=(abbrev)
    self.state = GeoState[abbrev]
  end

  def state_abbrev
    state && state.abbreviation
  end

  def reformat_phone
    if phone.present? && phone_changed?
      digits = phone.gsub(/\D/,'')
      if digits.length == 10
        self.phone = [digits[0..2], digits[3..5], digits[6..9]].join('-')
      end
    end
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

  def generate_registrants_csv
    FasterCSV.generate do |csv|
      csv << Registrant::CSV_HEADER
      registrants.all(:include => [:home_state, :mailing_state]).each do |reg|
        csv << reg.to_csv_array
      end
    end
  end

  WIDGET_IMAGES = {
    "rtv100x100v1"  => "rtv-100x100-v1.gif",
    "rtv200x165v1"  => "rtv-200x165-v1.gif",
    "rtv234x60v1"   => "rtv-234x60-v1.gif",
    "rtv300x100v1"  => "rtv-300x100-v1.gif",
    "rtv468x60v1"   => "rtv-468x60-v1.gif",
    "rtv468x60v1sp" => "rtv-468x60-v1-sp.gif"
  }
  DEFAULT_WIDGET_IMAGE_NAME = "rtv234x60v1"

  def widget_image_name
    WIDGET_IMAGES.index(widget_image)
  end

  def widget_image_name=(name)
    self.widget_image = WIDGET_IMAGES[name]
  end

  def set_default_widget_image
    self.widget_image_name = DEFAULT_WIDGET_IMAGE_NAME if self.widget_image.blank?
  end

  def make_paperclip_errors_readable
    if Array(errors[:logo]).any? {|e| e =~ /not recognized by the 'identify' command/}
      errors.clear
      errors.add(:logo, "logo must be an image file")
    end
  end
end
