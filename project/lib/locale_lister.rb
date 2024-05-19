#!/usr/bin/env ruby

# extra_entries_array in case we wanna make a "protected locale" function later on
def get_locale_files(extra_entries_array = [])
  protected_locales = ['.', '..', 'locale_template', 'default', 'default.old', extra_entries_array].flatten
  Dir.entries(LOCALES_PATH).reject { |entry| protected_locales.include?(entry) }
end

def list_locale_files()
  locales = get_locale_files
  puts "[alphalang] These are the available locales.\ndefault"
  locales.each do |locale|
    puts locale
  end
  puts
end

def clean_locale_file_to_array(locale_name)
  locale_file = File.readlines("#{LOCALES_PATH}/#{locale_name}")

  clean_locale_file_array = []
  locale_file.each do |line|
    line.scan(/[\p{Word}\p{Emoji}]+[|][\p{Word}\p{Emoji}]+|[\p{Word}\p{Emoji}]+/) do |word|
      clean_locale_file_array << word if word.size > 1 or word.match?(/\p{Emoji}/)
    end
  end

  clean_locale_file_array
end

def print_clean_locale_array(locale_name, clean_array)
  longest_word = clean_array.max_by(&:length).size
  padding = ' ' * (longest_word / 2 - 5)

  header = "#{padding}[alphalang] Syntax for locale <#{locale_name}>.#{padding}"
  puts header
  puts '+' * (header.size - 2)

  clean_line = ''
  clean_array.each_with_index do |word, index|
    if index.even?
      clean_line += "+ #{word}"
    else
      clean_line += (' ' * (20 - clean_line.size)) + "#{word}"
      clean_line += (' ' * (header.size - clean_line.size - 3) + '+')
      puts clean_line
      clean_line = ''
    end
  end

  puts '+' * (header.size - 2)
end

def list_specific_locale_file()
  list_locale_files
  specific_locale = gets.chomp

  specific_locale = File.read("#{LOCALES_PATH}/#{specific_locale}") if specific_locale == 'default'

  return if ABORT_ANSWERS.include?(specific_locale)

  specific_locale_array = clean_locale_file_to_array(specific_locale)
  print_clean_locale_array(specific_locale, specific_locale_array)
end
