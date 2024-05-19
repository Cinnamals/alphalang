#!/usr/bin/env ruby

def prompt_user_for_deletion(locales)
  puts 'Which locale would you like to delete?:                    RET or "none" to abort'

  locales.each do |locale|
    puts locale
  end

  locale_file = gets.chomp

  return if ABORT_ANSWERS.include?(locale_file)

  if PROTECTED_LOCALES.include?(locale_file)
    puts 'You may not delete a default locale.'
    return
  else
    File.delete("#{LOCALES_PATH}/#{locale_file}")
    puts "Successfully deleted #{LOCALES_PATH}/#{locale_file}"
  end
end

def delete_locale_file()
  imported_locales = Dir.entries(LOCALES_PATH).reject { |entry| PROTECTED_LOCALES.include?(entry) }

  if imported_locales.empty?
    puts '[alphalang] There are no locale files to delete. Default locale files are protected.'
    return
  else
    prompt_user_for_deletion(imported_locales)
  end
end
