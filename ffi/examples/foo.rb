#!/usr/bin/env ruby
base_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require "#{base_path}/yapwtp"

parser = WikiParser.new

# Example using Ruby to read a file.  Using the C-implemented methods is barely faster.
parser.image_base_url = "/test/"
parser.html_from_string("[[File:test.png]]")
puts parser.parsed_text
