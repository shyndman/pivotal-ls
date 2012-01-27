#! /usr/bin/ruby

require "rubygems"
require "net/http"
require "uri"
require "cgi"
require "nokogiri"

CONFIG_PATH = File.expand_path "~/.pvt"
FILTER_API_URL = "https://www.pivotaltracker.com:443/services/v3/projects/%s/stories?filter=%s"
FILTER_FORMAT = "mywork:%s state:started"

# Check for config file
if not File.exists? CONFIG_PATH
  $stderr.write "Could not find configuration at #{CONFIG_PATH}\n"
  $stderr.write "See .pvt.sample for information on configuration\n"
  exit 1
end

# Parse the configuration file
opts = {}

open CONFIG_PATH do |config|
  config.each_line do |line|
    line.gsub!(/#.*$/, '') # Strip comments
    line.strip! # Eliminate whitespace

    # Ignore empty lines
    next if line.empty?

    name, value = line.split(':')
    opts[name.to_sym] = value.strip
  end
end

# Construct the URL
filter = CGI.escape(FILTER_FORMAT % opts[:initials])
filter_uri = URI.parse(FILTER_API_URL % [opts[:project_id], filter])

# Construct the client
client = Net::HTTP.new(filter_uri.host, filter_uri.port)
client.use_ssl = true

# Grab the stories (XML)
begin
  response = client.get("#{filter_uri.path}?#{filter_uri.query}", "X-TrackerToken" => opts[:token])
rescue Exception => e
  $stderr.write "Error while attempting to communicate with Pivotal\n"
  $stderr.write "Details: #{e}\n"
  exit 1
end

# Error handling
unless response.code.start_with? '2'
  $stderr.write "Error response received from Pivotal\n"
  $stderr.write "#{response.code}: #{response.message}\n"
  $stderr.write "Might I suggest you check your internet connection?\n"
  exit 1
end

# Parse out the stories and write them to stdout
xml = Nokogiri::XML(response.body)
xml.css('story').each do |story|
  id = story.css('id')[0].content
  name = story.css('name')[0].content

  puts "#%-20s // %s" % [id, name]
end

puts ""