#!/usr/bin/env ruby

require_relative 'locale_lister'

def set_default_locale(new_locale)
  available_locales = get_locale_files

  available_locales.each do |available_locale|
    if available_locale == new_locale
      begin
        File.open("#{LOCALES_PATH}/default", 'w') { |f| f.write(new_locale) }
        puts "[alphalang] Default syntax locale is now set to #{new_locale}."
      rescue Errno::ENOENT
        puts '[alphalang] Failed to change default locale. Likely permissions error on your machine.'
        puts "Could not open #{LOCALES_PATH}/default}"
      end
    end
  end
end
