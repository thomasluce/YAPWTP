#!/usr/bin/env ruby
require 'open3'

describe "Integration tests" do
  def parse(wikitext)
    parser = File.join(File.dirname(__FILE__), '..', 'bin', 'parser')
    result = ""
    Open3.popen3(parser) do |stdin, stdout, sterr|
      stdin.print wikitext
      stdin.close
      result = stdout.read
    end
    return result
  end

  def get_wikitext(file)
    File.read(File.join(File.dirname(__FILE__), 'fixtures', file))
  end
  def get_result(file)
    File.read(File.join(File.dirname(__FILE__), 'fixtures', 'results', file))
  end

  def tidy(html)
    result = ""
    Open3.popen3("tidy -f /dev/null -ibq -ashtml") do |stdin, stdout, stderr|
      stdin.puts html
      stdin.close
      result = stdout.read
    end
    result
  end

  fixtures = Dir.new(File.join(File.dirname(__FILE__), 'fixtures')).entries - ['results','.','..']
  fixtures.each do |f|
    it "should be able to parse #{f}" do
      wikitext = get_wikitext f
      result = parse wikitext
      compare = get_result f
      File.open('/tmp/compare', 'w+') {|f| f.puts tidy(compare)}
      File.open('/tmp/result', 'w+') {|f| f.puts tidy(result)}
      tidy(compare).should == tidy(result)
    end
  end
end
