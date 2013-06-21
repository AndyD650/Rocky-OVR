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
class Translation
  
  def self.base_directory
    Rails.root.join('config','locales')
  end
  
  def self.type_names
    ['core', 'states', 'txt', 'email']
  end
  
  def self.types
    type_names.collect{|t| Translation.new(t) }
  end
  
  def self.directories
     types.collect{|t| directory(t) }
  end
  
  def self.file_names
    I18n.available_locales.collect{|l| "#{l}.yml"}
  end
  
  def self.find(type)
    self.new(type)
  end
  
  def self.directory(type)
    type == 'core' ? base_directory : base_directory.join(type)
  end
  
  def self.instructions_for(key)
    instructions = []
    en_value = I18n.t(key, :locale=>'en')
    en_value.to_s.scan(/(\%\{[^\{]+\})/).each do |match|
      instructions << "Please keep '#{match.first}' intact"
    end
    specific_instructions = I18n.t("#{key}_translation_instructions", :locale=>'en', :default=>'')
    instructions << specific_instructions unless specific_instructions.blank?

    instructions
  end
  
  def self.language_name(locale)
    I18n.t('language_name', :locale=>locale) + " (#{locale})"
  end
  
  attr_reader :directory
  attr_reader :type
  attr_reader :blanks
  
  def initialize(type)
    raise "Not Found" if !self.class.type_names.include?(type)
    @type = type
    @directory = self.class.directory(type)
    @blanks = []
  end
  
  def name
    @type.capitalize
  end
  
  def to_param
    @type
  end
  
  def file_path(fn)
    File.join(directory, fn)
  end
  
  def language(fn)
    fn.gsub(".yml", '')
  end
  
  def contents
    @contents ||= {}
    if @contents.empty?
      self.class.file_names.each do |fn|
        File.open(file_path(fn)) do |file|
          h = YAML.load(file)
          @contents[language(fn)] = h[h.keys.first] || {}
        end
      end
    end
    @contents
  end
  
  def get_from_contents(key, locale, group=nil)
    hash_keys = key.split('.')
    group ||= contents[locale]
    if hash_keys.size == 1
      return group[hash_keys.first]
    else
      group = group[hash_keys.shift]
      
      get_from_contents(hash_keys.join('.'), locale, group)
    end
  end
  
  def is_blank?(key)
    blanks.include?(key)
  end
  
  def generate_yml(locale, key_values)
    full_hash = {locale=>{}}
    key_values.each do |k,v|
      last_hash = full_hash[locale]
      key_chain = k.split('.')
      key_chain.each_with_index do |key, i|
        if (i+1 == key_chain.size)
          last_hash[key] = v
          blanks << k if v.blank?
        else
          last_hash[key] ||= {}
          last_hash = last_hash[key]
        end
      end
    end
    contents #load it
    @contents[locale] = full_hash[locale]
    full_hash.to_yaml
  end
  
  
end