#!/usr/bin/env ruby

base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(base_path, 'ffi', 'yapwtp')

describe WikiParser do

  before :all do
    @parser = WikiParser.new
  end

  describe "settings" do
    it "should support a base URL" do
      @parser.set_base_url "/test"
	  @parser.html_from_string("[[test]]").should include('href="/test/test"')
	end

	it "should support an image base URL" do
	  pending
      @parser.set_image_base_url "/test/"
	  @parser.html_from_string("[[Image:test.png]]").should include('src="/test/test.png"')
	end
  end

  describe "documents" do

    it "should be parseable using FFI" do

      @parser.html_from_file("#{base_path}/spec/fixtures/cnn.com").gsub(/\n/, '').should include('<p>__Domain_Page_13188934542708613758__</p><p>  <h2><span class="editsection">[<a href="edit">edit</a>]</span><span class="mw-headline" id="CNN.com">CNN.com</span></h2>  <a name="CNN.com">')

    end
  
    it "should be parseable back-to-back" do

      @parser.html_from_file("#{base_path}/spec/fixtures/cnn.com")
      @parser.html_from_file("#{base_path}/spec/fixtures/flowerpetal.com").gsub(/\n/, '').should include('<p>  <h2><span class="editsection">[<a href="edit">edit</a>]</span><span class="mw-headline" id="Flowers_make_the_perfect_gift_for_any_occasion">Flowers make the perfect gift for any occasion</span></h2>')

    end

  end

  describe "templates" do

    it "should be returned when a document was successfully parsed" do

      @parser.html_from_file("#{base_path}/spec/fixtures/cnn.com")
      @parser.templates.size.should be(2)
      @parser.templates[0][:name].should == "Domain_Page"
      @parser.templates[1][:name].should == "color"

    end

    it "should be encoded with a unique replacement key" do

      @parser.html_from_file("#{base_path}/spec/fixtures/cnn.com")
      @parser.templates[0][:replace_tag].should == "__Domain_Page_13188934542708613758__"

    end

    it "should handle simple template replacement" do
      pending
    end

  end

end
