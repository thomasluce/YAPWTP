#!/usr/bin/env ruby
require 'open3'

describe "Wikitext parser" do
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

  def assert(&block)
    result = yield
    raise "Assertion failed: #{result}" unless yield
  end

  describe "headings" do
    it "should be able to make a heading" do
      parse("== heading ==").strip.should =~ /<h1>heading/
      parse("== heading ==\n").strip.should =~ /<h1>heading/
    end
    
    it "should make an anchor with the heading" do
      parse("==heading==").strip.should =~ /<a name="heading"/
    end
    
    it "should filter headings content for the anchor name" do
      parse("==heading ''with formatting''==").strip.should =~/<a name="heading_with_formatting"/
    end

    it "should not allow text after the closing header" do
      parse("== heading == test").strip.should_not =~ /<h1>heading/
    end

    it "should allow white-space after the closing heading marker" do
      parse("== heading ==    ").strip.should =~ /<h1>heading/
    end

    it "should let you close a heading with unballanced tags" do
      result = parse("=== heading ==").strip
      result.should include '<h2>'
      result.should include '</h2>'
    end
  end

  describe "paragraphs" do
    it "should be able to notice paragraph breaks" do
      parse(".\n\n.").strip.should == "<p>.</p>."
    end

    it "should be able to make a horizontal line" do
      parse("----").strip.should == "<hr/>"
    end

    it "should be able to indent lines" do
      parse(":text").strip.should == "&nbsp;&nbsp;text"
    end
  end

  describe "lists" do
    it "should be able to make a list" do
      parse('* test').should == '<ul><li>test</li></ul>'
      parse("* test\n").should == '<ul><li>test</li></ul>'
      parse("* test\n*test2").should == '<ul><li>test</li><li>test2</li></ul>'
    end

    it "should be able to make nested lists" do
      parse("* test\n*test2\n** nested").should == '<ul><li>test</li><li>test2</li><ul><li>nested</li></ul></ul>'
    end

    it "should be able to make numbered lists" do
      parse('# test').should == '<ol><li>test</li></ol>'
      parse("# test\n").should == '<ol><li>test</li></ol>'
      parse("# test\n#test2").should == '<ol><li>test</li><li>test2</li></ol>'
    end

    it "should be able to nest numbered lists" do
      parse("# test\n#test2\n## nested").should == '<ol><li>test</li><li>test2</li><ol><li>nested</li></ol></ol>'
    end
  end

  describe "text formatting" do
    it "should be able to make things italic" do
      parse("''italic''").should == '<i>italic</i>'
    end

    it "should be able to make things bold" do
      parse("'''bold'''").should == '<b>bold</b>'
    end

    it "should be able to make things bold and italic" do
      parse("'''''bold-italic'''''").should == '<b><i>bold-italic</i></b>'
    end
    
    it "should wrap things in leading spaces with pre tags" do
      parse(" thing one\n  thing two").should == "<pre>thing one\n thing two</pre>"
    end
    # TODO: <nowiki>tags
  end

  describe "links" do
    it "should be able to make a simple link" do
      parse("[[someplace else]]").should == '<a href="/someplace_else">someplace else</a>'
    end

    it "should be able to make a named link" do
      parse("[[path|display]]").should == '<a href="/path">display</a>'
    end
    # TODO: I need to hide things in parenthesis. Eg: [[test (first)]] should produce <a href="/test_(first)">test</a>
    # TODO: hide namespaces. Eg: [[Namespace:test]] should produce <a href="/Namespace:test">test</a>
      # These two things together as well.
    # TODO: interwiki links.

    # blended links
    it "should be able to make blended links" do
      parse("[[path]]s").should == '<a href="/path">paths</a>'
    end

    it "should be able to do external links" do
      parse("[http://www.google.com google]").should == '<a href="http://www.google.com">google</a>'
      parse("[http://www.google.com]").should == '<a href="http://www.google.com">http://www.google.com</a>'
    end

    it "should be able to make full urls into links" do
      parse("http://www.google.com").should == '<a href="http://www.google.com">http://www.google.com</a>'
    end
  end

  describe "images" do
    it "should be able to make an image" do
      parse("[[File:image.png]]").should == '<img src="image.png" />'
    end

    it "should be able to apply alt-text to an image" do
      parse("[[File:image.png|alt=alt text]]").should == '<img src="image.png" alt="alt text" />'
    end

    it "should be able to link to the file instead of display it" do
      parse("[[:File:image.png]]").should == '<a href="/File:image.png">File:image.png</a>'
      # TODO: "Media:" links that you can title
    end

    # TODO: frame and thumb attributes
    # TODO: right and left floats
    # TODO: sizing
  end

  describe "tables -- oh boy..." do
    it "should be able to make a caption for the table" do
      parse("{|
|+ caption
|-
|}").should == "<table><caption>caption</caption><tr></tr></table>"
    end

    it "should be able to do simple rows" do
      parse("{|
|-
| cell one
|}").should == "<table><tr><td>cell one</td></tr></table>"
    end

    it "should be able to do single-line rows" do
      parse("{|
|-
| Cell one || Cell two
|}").should == "<table><tr><td>Cell one </td><td>Cell two</td></tr></table>"
    end

    it "should be able to do a few rows" do
      parse("{|
|+ Caption
|-
| cell || cell
|-
| cell
| cell
|}").should == "<table><caption>Caption</caption><tr><td>cell </td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table>"
    end
    
    describe "headers" do
      it "should be able to make headers" do
        parse("{|
|+ Caption
! scope=\"col\" | column heading 1
! scope=\"col\" | column heading 2
|-
| cell || cell
|-
| cell
| cell
|}").should == "<table><caption>Caption</caption><tr><th scope=\"col\">column heading 1</th><th scope=\"col\">column heading 2</th></tr><tr><td>cell </td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table>"
      end
      
      it "should be able to do headers part-way down as well" do
        parse("{|
|+ Caption
! scope=\"col\" | column heading 1
! scope=\"col\" | column heading 2
|-
! scope=\"row\" | row heading
| cell || cell
|-
| cell
| cell
|}").should == "<table><caption>Caption</caption><tr><th scope=\"col\">column heading 1</th><th scope=\"col\">column heading 2</th></tr><tr><th scope=\"row\">row heading</th><td>cell </td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table>"
      end
    end
    
    # TODO: single-pipe separaters for a format modifier
  end


  # TODO: categories
  # TODO: redirects
  # TODO: "As of" tags
  # TODO: media links
  # TODO: links directly into edit mode
  # TODO: book sources "ISBN" links
  # TODO: RFC links
  # TODO: templates and transclusions
end
