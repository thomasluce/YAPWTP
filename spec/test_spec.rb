#!/usr/bin/env ruby
require 'open3'

describe "Wikitext parser" do
  before :all do
    dir = File.join(File.dirname(__FILE__), '..')
    `cd #{dir} && make`
  end

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

  describe "headings" do
    it "should not freak out when there are multiple headings" do
      parse("===heading===\n===heading===").should_not include 'headingheading'
    end

    it "should be able to do links inside of headings" do
      parse("===[[heading]] ===").should_not include '[['
    end

    it "should create the markup like mediawiki" do
      parse("===heading ===").strip.should == '<p><h3><span class="editsection">[<a href="edit">edit</a>]</span><span class="mw-headline" id="heading">heading</span></h3><a name="heading" /></p>'
    end

    it "should be able to make a heading" do
      parse("== heading ==").strip.should =~ /<span class="mw-headline" id="heading">heading<\/span>/
      parse("== heading ==\n").strip.should =~ /<span class="mw-headline" id="heading">heading<\/span>/
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
      parse("== heading ==    ").strip.should =~ /<span class="mw-headline" id="heading">heading<\/span>/
    end

    it "should let you close a heading with unballanced tags" do
      result = parse("=== heading ==").strip
      result.should include '<h3>'
      result.should include '</h3>'
    end

	it "should not output bogus h tags" do
      result = parse("========== heading ==").strip
	  result.should_not include "<h10>"
	  result.should include "<h5>"
	end
  end

  describe "paragraphs" do
    it "should be able to notice paragraph breaks" do
      parse(".\n\n.").strip.should == "<p>.</p><p>.</p>"
    end

    it "should be able to make a horizontal line" do
      parse("----").strip.should =~ /<hr\/>/
    end

    it "should be able to indent lines" do
      parse(":text").strip.should include "&nbsp;&nbsp;text"
    end

    it "should not make shitty paragraphs" do
      parse("paragraph 1\n\nparagraph 2").should == "<p>paragraph 1</p><p>paragraph 2</p>"
    end
  end

  describe "lists" do
    it "should be able to make a list" do
      parse('* test').should == '<p><ul><li>test</li></ul></p>'
      parse("* test\n").should == '<p><ul><li>test</li></ul></p>'
      parse("* test\n*test2").should == '<p><ul><li>test</li><li>test2</li></ul></p>'
    end

    it "should be able to make nested lists" do
      parse("* test\n*test2\n** nested").should == '<p><ul><li>test</li><li>test2</li><ul><li>nested</li></ul></ul></p>'
    end

    it "should be able to make numbered lists" do
      parse('# test').should == '<p><ol><li>test</li></ol></p>'
      parse("# test\n").should == '<p><ol><li>test</li></ol></p>'
      parse("# test\n#test2").should == '<p><ol><li>test</li><li>test2</li></ol></p>'
    end

    it "should be able to nest numbered lists" do
      parse("# test\n#test2\n## nested").should == '<p><ol><li>test</li><li>test2</li><ol><li>nested</li></ol></ol></p>'
    end

    it "should process other wiki text inside of list items" do
      parse("* [[link]]").should == '<p><ul><li><a href="/link">link</a></li></ul></p>'
    end
  end

  describe "text formatting" do
    it "should be able to make things italic" do
      parse("''italic''").should == '<p><i>italic</i></p>'
    end

    it "should be able to make things bold" do
      parse("'''bold'''").should == '<p><b>bold</b></p>'
    end

    it "should be able to make things bold and italic" do
      parse("'''''bold-italic'''''").should == '<p><b><i>bold-italic</i></b></p>'
    end

    it "should wrap things in leading spaces with pre tags" do
      parse(" thing one\n  thing two").should == "<p><pre>thing one\n thing two</pre></p>"
    end

    it "should pass through anything that is inside of <nowiki> tags" do
      parse("<nowiki>'''format'''</nowiki> '''format'''").should == "<p>'''format''' <b>format</b></p>"
    end
  end

  describe "links" do
    it "should be able to make a simple link" do
      parse("[[someplace else]]").should == '<p><a href="/someplace_else">someplace else</a></p>'
    end

    it "should be able to make a named link" do
      parse("[[path|display]]").should == '<p><a href="/path">display</a></p>'
    end

    it "should be able to have multiple named and un-named links on a line" do
      result = parse("check out the [[thumbnail]] tool from [[domaintools|Domain Tools]]")
      result.should == "<p>check out the <a href=\"/thumbnail\">thumbnail</a> tool from <a href=\"/domaintools\">Domain Tools</a></p>"
    end

    it "should hide parentheticals in the link text" do
      parse("[[link (test)]]").should == '<p><a href="/link_(test)">link</a></p>'
    end
    # TODO: hide namespaces. Eg: [[Namespace:test]] should produce <a href="/Namespace:test">test</a>
      # These two things together as well.
    # TODO: interwiki links.

    # blended links
    it "should be able to make blended links" do
      parse("[[path]]s").should == '<p><a href="/path">paths</a></p>'
    end

    it "should be able to do external links" do
      parse("[http://www.google.com google]").should == '<p><a href="http://www.google.com">google</a></p>'
      parse("[http://www.google.com]").should == '<p><a href="http://www.google.com">http://www.google.com</a></p>'
    end

    it "should be able to make full urls into links" do
      parse("http://www.google.com").should == '<p><a href="http://www.google.com">http://www.google.com</a></p>'
    end
  end

  describe "images" do
    # TODO: link= and caption attributes
    # TODO: size and border attributes
    it "should be able to make an image" do
      parse("[[File:image.png]]").should == '<p><a href="File:image.png" class="image"><img src="image.png" /></a></p>'
    end

    it "should be able to use the alternate, 'Image:' indicator" do
      parse("[[Image:image.png]]").should == '<p><a href="File:image.png" class="image"><img src="image.png" /></a></p>'
    end

    it "should be able to apply alt-text to an image" do
      parse("[[File:image.png|alt=alt text]]").should include 'alt="alt text"'
    end

    it "should be able to link to the file instead of display it" do
      parse("[[:File:image.png]]").should == '<p><a href="/File:image.png">File:image.png</a></p>'
      # TODO: "Media:" links that you can title
    end

    it "should be able to float the image left, right, center, or not at all" do
      parse("[[File:image.png|left]]").should include 'class="floatleft"'
    end

    describe "thumbnail" do
      # TODO: if a filename is given as the value to 'thumb=', use that without the width, and height.
      it "should scale the image down" do
        parse("[[File:image.png|thumb]]").should include 'width="220" height="30" class="thumbimage"'
      end

      it "should scale the image down" do
        parse("[[File:image.png|thumbnail]]").should include 'width="220" height="30" class="thumbimage"'
      end
    end

    describe "frame" do
      it "should attach the thumbimage class but not actually size it down" do
        parse("[[File:image.png|frame]]").should include 'class="thumbimage"'
      end
    end
  end

  describe "tables -- oh boy..." do
    it "should be able to make a caption for the table" do
      parse("{|
|+ caption
|-
|}").should == "<p><table><caption>caption</caption><tr></tr></table></p>"
    end

    it "should be able to do simple rows" do
      parse("{|
|-
| cell one
|}").should == "<p><table><tr><td>cell one</td></tr></table></p>"
    end

    it "should be able to do single-line rows" do
      parse("{|
|-
| Cell one || Cell two
|}").should == "<p><table><tr><td>Cell one </td><td>Cell two</td></tr></table></p>"
    end

    it "should be able to do a few rows" do
      parse("{|
|+ Caption
|-
| cell || cell
|-
| cell
| cell
|}").should == "<p><table><caption>Caption</caption><tr><td>cell </td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table></p>"
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
|}").should == "<p><table><caption>Caption</caption><tr><th scope=\"col\">column heading 1</th><th scope=\"col\">column heading 2</th></tr><tr><td>cell </td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table></p>"
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
|}").should == "<p><table><caption>Caption</caption><tr><th scope=\"col\">column heading 1</th><th scope=\"col\">column heading 2</th></tr><tr><th scope=\"row\">row heading</th><td>cell </td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table></p>"
      end
    end

    # TODO: single-pipe separaters for a format modifier
  end

  describe "templates" do
    it "should just swallow templates at the moment" do
      parse('{{template}}').should == '<p></p>'
    end
  end


  # TODO: categories
  # TODO: redirects
  # TODO: "As of" tags
  # TODO: media links
  # TODO: links directly into edit mode
  # TODO: book sources "ISBN" links
  # TODO: RFC links
end
