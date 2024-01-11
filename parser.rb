#!/usr/bin/env ruby

require 'date'

SLA_VALUE=258 # Mbits/s

log_file_path = '~/data/log/speedtest/speedtest.simple.log'

# Read the log file
log_data = File.read(File.expand_path(log_file_path))

# Split the log entries
entries = log_data.split('---')

# Initialize arrays to store extracted data
dates = []
times = []
datetimes = []
downloads = []
downloadh = []
downloadl = []
downloadhs = []
downloadls = []
uploads = []

# Loop through each entry and extract data
entries.each do |entry|
  date_match = entry.match(/DATE: (\d{2}\/\d{2}\/\d{2}) TIME:(\d{2}:\d{2}:\d{2})/)
  download_match = entry.match(/Download: (\d+\.\d+) Mbit\/s/)
  upload_match = entry.match(/Upload: (\d+\.\d+) Mbit\/s/)

  if date_match && download_match && upload_match
    # Extracted data
    date = Date.strptime(date_match[1], '%m/%d/%y').strftime('%d%m%Y')
    time = date_match[2].gsub(':', '')
    download = download_match[1].to_f
    downloadh = download_match[1].to_f >= 258 ? download_match[1].to_f : 0.to_f
    downloadl = download_match[1].to_f < 258 ? download_match[1].to_f : 0.to_f
    upload = upload_match[1].to_f

    # Store in arrays
    dates << date
    times << time
    datetimes << "#{date}#{time}" 
#STDERR.puts datetimes
    downloads << download
    downloadls << downloadl
    downloadhs << downloadh
    uploads << upload
  end
end

# Display the extracted data
#puts "Dates: #{dates}"
#puts "Times: #{times}"
#puts "Datetimes: #{datetimes}"
#puts "Downloads: #{downloads}"
#puts "Uploads: #{uploads}"

puts "DATETIME,DOWNLOADLOW,DOWNLOADHI,UPLOAD,SLA"
count = datetimes.size
for i in 0..count do
  line = "#{datetimes[i]},#{downloadls[i]},#{downloadhs[i]},#{uploads[i]},#{SLA_VALUE}"
  puts line unless line.start_with? ','
end
