#!/usr/bin/env ruby
require_relative 'locale_lister'

def read_translation(line)
  puts "Enter the translation for: '#{line}'        <RET> to accept '#{line}'"
  translation = gets.chomp
  translation.empty? ? line : translation
end

def read_translation_true_false(line)
  words = line.scan(/true|false/)
  translation = '('
  words.each do |word|
    puts "Enter the translation for: '#{word}'        <RET> to accept '#{word}'"
    input = gets.chomp
    translation += input.empty? ? word : input
    translation += '|'
  end
  translation.chop!
  translation += ')'
  translation
end

def read_translation_not_and_or(line)
  word = line.match(/\w+/)[0]
  postfix = line.match(/\|.+/)[0]
  puts "Enter the translation for: '#{word}'        <RET> to accept '#{word}'"
  input = gets.chomp
  return "(#{input.empty? ? word : input}#{postfix}"
end

def prompt_user(file)
  locale_template = File.readlines("#{LOCALES_PATH}/locale_template")

  counter = 0
  File.open(file, 'a') do |f|
    f.puts ';;.*$ ;;.*$'
    locale_template.each do |line|
      counter += 1
      break if counter == 15

      if counter > 1 && counter < 10
        translation = read_translation(line.chomp)
        f.puts "#{line.chomp} #{translation}"
      end
      if counter == 10
        translation = read_translation_true_false(line.chomp)
        f.puts "#{line.chomp} #{translation}"
      end
      if counter == 11
        f.puts "#{line.chomp} (==|<=|>=)"
      end
      if counter > 11
        translation = read_translation_not_and_or(line.chomp)
        f.puts "#{line.chomp} #{translation}"
      end
    end
    f.puts '\s+ \s+'
    f.puts '\d+ \d+'
    f.puts '\w+ \w+'
    f.puts '. .'
  end
end

def create_locale_file()
  puts 'Choose a filename for your locale/syntax:'
  new_locale_name = gets.chomp
  new_locale_file_path = "#{LOCALES_PATH}/#{new_locale_name}"

  if File.exist?(new_locale_file_path)
    puts "#{new_locale_name} already exists."
    return
  end

  prompt_user(new_locale_file_path)
  system('clear')

  locale_as_array = clean_locale_file_to_array(new_locale_name)
  print_clean_locale_array(new_locale_name, locale_as_array)

  puts 'Is this correct? [Y/n]'
  answer = gets.chomp

  if answer.downcase.match? /y|Y/ or answer.empty?
    puts "Locale is saved as #{new_locale_name} in #{LOCALES_PATH}"
  else
    puts 'Translation removed'
    File.delete(new_locale_file_path)
  end
end
