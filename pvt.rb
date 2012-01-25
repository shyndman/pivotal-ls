#! /usr/bin/ruby

require "rubygems"
require "net/http"
require "uri"
require "cgi"
require "nokogiri"

CONFIG_PATH = File.expand_path "~/.pvt"
FILTER_API_URL = "http://www.pivotaltracker.com/services/v3/projects/%s/stories?filter=%s"
FILTER_FORMAT = "mywork:%s state:started"

if not File.exists? CONFIG_PATH
  $stderr.write "Could not find configuration at #{CONFIG_PATH}\n"
  exit 1
end

opts = {}

open CONFIG_PATH do |config|
  config.each_line do |line|
    line.strip!

    next if line.start_with? "#" or line.empty?

    name, value = line.split(':')
    opts[name.to_sym] = value.strip
  end
end


filter_uri = URI.parse(FILTER_API_URL % [opts[:project_id], CGI::escape(FILTER_FORMAT % opts[:initials])])
response = Net::HTTP.start(filter_uri.host, filter_uri.port) do |http|
  http.get("#{filter_uri.path}?#{filter_uri.query}", {"X-TrackerToken" => opts[:token]})
end

xml = Nokogiri::XML(response.body)
xml.css('story').each do |story|
  id = story.css('id')[0].content
  name = story.css('name')[0].content

  puts "#%-20s // %s" % [id, name]
end

puts ""