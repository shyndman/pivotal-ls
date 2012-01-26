#! /usr/bin/ruby

require "rubygems"
require "net/http"
require "uri"
require "cgi"
require "nokogiri"

CONFIG_PATH = File.expand_path "~/.pvt"
FILTER_API_URL = "http://www.pivotaltracker.com/services/v3/projects/%s/stories?filter=%s"
FILTER_FORMAT = "mywork:%s state:started"

# Quick check
if not File.exists? CONFIG_PATH
  $stderr.write "Could not find configuration at #{CONFIG_PATH}\n"
  $stderr.write "See .pvt.sample for information on configuration\n"
  exit 1
end

# Parse the configuration file
opts = {}

open CONFIG_PATH do |config|
  config.each_line do |line|
    line.strip!

    next if line.start_with? "#" or line.empty?

    name, value = line.split(':')
    opts[name.to_sym] = value.strip
  end
end



# Construct the URL
filter = CGI::escape(FILTER_FORMAT % opts[:initials])
filter_uri = URI.parse(FILTER_API_URL % [opts[:project_id], filter])

# Grab the stories (XML)
response = Net::HTTP.start(filter_uri.host, filter_uri.port) do |http|
  http.get("#{filter_uri.path}?#{filter_uri.query}", {"X-TrackerToken" => opts[:token]})
end

# Parse out the stories and write them to stdout
xml = Nokogiri::XML(response.body)
xml.css('story').each do |story|
  id = story.css('id')[0].content
  name = story.css('name')[0].content

  puts "#%-20s // %s" % [id, name]
end

puts ""