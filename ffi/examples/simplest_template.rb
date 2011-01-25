#!/usr/bin/env ruby

# --------------------------------------------------------------------------------
# This example handles the simplest case of templates one layer deep
# * Templates here ignore arguments
# --------------------------------------------------------------------------------

base_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require "#{base_path}/kiwi"

parser = WikiParser.new

# Open the requested file, parse, capture text and templates
wikitext = parser.html_from_file("#{base_path}/../spec/fixtures/cnn.com")
templates = parser.templates

templates.each do |template|
  template_file = File.join("templates", template[:name]) 
  if File.exist? template_file
    wikitext.gsub! /#{template[:replace_tag]}/, parser.html_from_file(template_file)
  end
end

puts wikitext
