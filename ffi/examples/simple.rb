#!/usr/bin/env ruby
base_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require "#{base_path}/yapwtp"

parser = WikiParser.new

# Example using Ruby to read a file.  Using the C-implemented methods is barely faster.
File.open("#{base_path}/../spec/fixtures/cnn.com", "rb") do |f|
  parser.html_from_string(f.read)
  puts "# Templates: #{parser.get_template_count}"
  puts "-" * 78;
  parser.each_template do |template|
    puts "#{template[:name]} = #{template[:content]}"
    puts "-" * 78;
  end
  puts parser.parsed_text
end
