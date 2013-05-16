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
class StateImporter
  
  attr_accessor :file, :defaults, :imported_states, :imported_locales, :messages
  
  def initialize(file = nil)
    @file = file || Rails.root.join('db/bootstrap/import/states.yml')
    @imported_states = []
    @imported_locales = []
    @messages = []
    @defaults = {}
  end
  
  def puts_report
    puts self.messages.join("\n\n")
  end

  def defaults_key
    'defaults'
  end

  
  def import
    File.open(@file) do |file|
      states_hash = YAML.load(file)
      set_defaults(states_hash)
      states_hash.each do |key, row|
        unless key == defaults_key
          begin
            print "#{row['name']}... "
            import_state(row)
            import_localizations(row)
            puts "DONE!"
          rescue StandardError => e
            raise e
            $stderr.puts "!!! could not import state data for #{row['name']}"
            $stderr.puts e.message
            $stderr.puts e.backtrace
          end
        end
      end
    end
  end
  
  def commit!
    commit_changes!
  end

protected

  def commit_changes!
    GeoState.transaction do
      imported_states.each do |state|
        state.save!
      end
      imported_locales.each do |loc|
        loc.save!
      end
    end
  end

  def set_defaults(states_hash)
    @defaults = states_hash[defaults_key]
  end


  def import_state(row)
    state = GeoState[row["abbreviation"]]
    %w(name participating requires_race requires_party id_length_min id_length_max).each do |method|
      new_value = get_from_row(row, method)
      report_any_changes(state.send(method), new_value, "in #{state.name}.#{method}:")
      state.send("#{method}=", new_value)
    end
    [['registrar_address','sos_address'],
     ['registrar_phone','sos_phone'],
     ['registrar_url','sos_url']].each do |method, key|
       new_value = get_from_row(row, key)
       report_any_changes(state.send(method), new_value, "in #{state.name}.#{method}:")
       state.send("#{method}=", new_value)       
     end
    # state.registrar_address = get_from_row(row, "sos_address")
    # state.registrar_phone = get_from_row(row, "sos_phone")
    # state.registrar_url = get_from_row(row, "sos_url")
    self.imported_states <<  state
  end

  def get_from_row(row, key)
    row[key].nil? ? self.defaults[key] : row[key]
  end

  def translate_from_row(row, key, locale, state_name='')
    loc_key_value = row[key].nil? ? defaults[key] : row[key]
    loc_key = "states.#{get_loc_part(key)}.#{loc_key_value}"
    I18n.t(loc_key, :locale=>locale, :state_name=>state_name).html_safe.strip
    #parties
  end
  
  def translate_party(party_key, locale, state_name='')
    I18n.t("states.parties.#{party_key}", :locale=>locale, :state_name=>state_name).html_safe.strip
  end
  
  def get_loc_part(key)
    if key =~ /tooltip/
      "tooltips.#{key.gsub('_tooltip', '')}"
    elsif key == 'no_party'
      "no_party_label"
    else
      key
    end
  end

  def import_localizations(row)
    state = GeoState[row["abbreviation"]]
    I18n.available_locales.each do |locale|
      loc = state.localizations.find_or_initialize_by_locale(locale.to_s)

      new_parties = get_from_row(row, "parties").collect {|p| translate_party(p, locale, state.name)}
      report_any_changes(loc.parties, new_parties, "in #{state.name} local #{loc.id} party list:")
      loc.parties = new_parties
      
      %w(not_participating_tooltip race_tooltip party_tooltip no_party id_number_tooltip sub_18).each do |method|
        new_val = translate_from_row(row, method, locale, state.name)
        report_any_changes(loc.send(method), new_val, "in #{state.name} local #{loc.id} #{method}")
        loc.send("#{method}=", new_val)
      end
      self.imported_locales << loc
    end
  end
  

  def read_parties(raw)
    raw ? raw.split(',').collect {|s| s.strip} : []
  end
  
  def report_any_changes(old_obj, new_obj, message)
    if clean_for_changes(old_obj) != clean_for_changes(new_obj)
      report("#{message}\n\tchange:\n\t> #{old_obj.to_s}\n\t> #{new_obj.to_s}")
    end
  end
  
  def clean_for_changes(obj)
    obj.to_s.gsub(/\s/,'')
  end
  
  def report(msg)
    self.messages << msg
  end
  
  
end
