#!/usr/bin/env ruby

# Simple test harness runner for MediaWiki's tests
# -- This should eventually just generate spec files

require File.join(File.dirname(__FILE__), '..', '..', 'ffi/yapwtp')

capturing = false
type = 'input'
input_buffer = ""
result_buffer = ""
title = ""
count = 0
success = 0

parser = WikiParser.new

File.open(File.join(File.dirname(__FILE__), 'parserTests.txt')) do |f| 
  f.each_line do |line|
  
    if line =~ /^!! input/
      type = 'input'
      capturing = true
      next
    end
  
    if line =~ /^!!\s*result/
      type = 'result'
      next
    end
  
    if line =~ /^!!\s*test/
      capturing = true
      type = 'title'
      next
    end
  
    if line =~ /^!!\s*end/ && capturing
      count += 1
      capturing = false
      input_buffer.gsub! /\r\n/, "\n"
      input_buffer.chomp!
      output = parser.html_from_string(input_buffer)
  
      # normalize white space
      output.gsub! /\s+/, ' '
      result_buffer.gsub! /\s+/, ' '
      output.strip!
      result_buffer.strip!
  
      if output == result_buffer
        success += 1
      else
        puts "-- #{title}"
        puts "== Input:"
        puts input_buffer.inspect
        puts "== Expected:"
        puts result_buffer.inspect
        puts "== Got:"
        puts output.inspect
        puts "-" * 80
      end
  
      result_buffer = ""
      output = ""
      input_buffer = ""
      next
    end
  
    if capturing
      input_buffer  += line if type == 'input'
      result_buffer += line if type == 'result'
      title = line if type == 'title'
    end
  end
end

puts "Success in #{success} of #{count}"
