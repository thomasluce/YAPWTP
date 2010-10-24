#!/usr/bin/env ruby

base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(base_path, 'ffi', 'yapwtp')

describe WikiParser do

  before :all do
    @parser = WikiParser.new
  end

  it "should be able to parse wikitext using FFI" do
    @parser.html_from_file("#{base_path}/spec/fixtures/cnn.com").gsub(/\n/, '').should include('<p>__Domain_Page_2953224830__</p><p>  <h2><span class="editsection">[<a href="edit">edit</a>]</span><span class="mw-headline" id="CNN.com">CNN.com</span></h2>  <a name="CNN.com">')
  end

end
