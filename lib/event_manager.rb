require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  digits = number.gsub(/[^\d]/, '')
  if digits.length < 10 || digits.length > 11 || digits.length == 11 && digits[0] != '1'
    'Invalid phone number.'
  else
    digits.delete_prefix!('1') if digits[0] == '1'
    digits
  end # return a standarized version of the number parameter
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def find_highest(hash)
  hash.key(hash.values.max)
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.html')
erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

registering_hours = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  reg_date = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M")
  registering_hours["#{reg_date.hour}:00"] += 1

  puts "Processing request ##{id}"
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

puts 'Event Manager Finished Processing.'
most_active_hour = find_highest(registering_hours)
puts "The most active hour of each day was: #{most_active_hour}, with #{registering_hours[most_active_hour]} people registering in the hour."
