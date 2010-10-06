#!/usr/bin/env ruby
require 'open3'

describe "Wikitext parser" do
  before :suite do
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
    it "should be able to use windows line-endings" do
      parse("==heading==\r\n").should == '<p><h2><span class="editsection">[<a href="edit">edit</a>]</span><span class="mw-headline" id="heading">heading</span></h2><a name="heading" /></p>'
    end

    it "should not freak out when there are multiple headings" do
      parse("===heading===\n===heading===").should_not include 'headingheading'
    end

    it "should be able to do links inside of headings" do
      parse("===[[heading]] ===").should_not include '[['
    end

    it "should be able to do multiple links in one heading" do
      parse("===[[link]] on [[FOO.com]]===").should == '<p><h3><span class="editsection">[<a href="edit">edit</a>]</span><span class="mw-headline" id="link_on_FOO.com"><a href="/link">link</a> on <a href="/FOO.com">FOO.com</a></span></h3><a name="link_on_FOO.com" /></p>'
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

    it "should hide parentheticals in the link text and urlencode them in the href" do
      parse("[[link (test)]]").should == "<p><a href=\"/link_%28test%29\">link</a></p>"
    end

    it "should hide namespaces" do
      result = parse("[[Namespace:test]]")
      result.should include '<a href="/Namespace:test"'
      result.should include '>test</a>'
    end
    # TODO: interwiki links.

    # blended links
    it "should be able to make blended links" do
      parse("[[path]]s").should == '<p><a href="/path">paths</a></p>'
    end

    describe "external links" do
      it "should be able to do external links" do
        parse("[http://www.google.com google]").should == '<p><a href="http://www.google.com">google</a></p>'
        parse("[http://www.google.com]").should == '<p><a href="http://www.google.com">http://www.google.com</a></p>'
      end

      it "should allow multiple links on a line" do
        parse("[http://www.google.com] should link to [[google]]").should == '<p><a href="http://www.google.com">http://www.google.com</a> should link to <a href="/google">google</a></p>'
      end
    end

    it "should be able to make full urls into links" do
      parse("http://www.google.com").should == '<p><a href="http://www.google.com">http://www.google.com</a></p>'
    end

    it "should handle links back to back" do
      parse("[[FooFoo]][http://BarBar.com/]").should_not include "["
    end

    it "should handle more than one link on a line" do
      parse("[[FooFoo]] in [[BarBar]]").should_not include "[["
    end

    it "should handle at least a renamed link and a simple link on a line" do
      parse("[[User_talk:Mr Big/FOO.com|Mr Big's Comments]] on [[FOO.com]]").should 
      be("<p><a href=\"/User_talk:Mr_Big/FOO.com\">Mr Big's Comments</a> on <a href=\"/FOO.com\">FOO.com</a></p>")
    end

    it "should not add pre tags when the link is followed by a space" do
      parse("[http://www.flowerpetal.com FlowerPetal.com] is the easy way to send flowers online").should_not
      include "<pre>";
    end

    it "should not allow javascript links" do
      parse("[javascript:alert('pwnd')]").should_not include '<a'
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
      parse("[[:File:image.png]]").should == '<p><a href="/File:image.png">image.png</a></p>'
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

  describe "table of contents" do
    it "should not output a table of contents if  __NOTOC__ is present" do
      parse("==Heading 1==\n__NOTOC__\n==Heading 2==\n==Heading 3==").should_not include "<ol>"
    end

    it "should replace __TOC__ with the table of contents if more than 3 headings are present" do
      parse("==heading==\n__TOC__\n==heading==\n==heading==").should ==
        "<p><h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2><a name=\"heading\" />__TOC__<h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2><a name=\"heading\" /><h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2><a name=\"heading\" /></p>"
    end

    it "should not output a table of contents when fewer than 3 headings are present" do
      parse("==Heading 1==\n==Heading 2==\n").should_not include "<ol>"
    end

    it "should output a table of contents when more than 3 headings are present" do
      parse("==Heading 1==\n==Heading 2==\n==Heading 3==").should include 
      "<ol><li><a href=\"#Heading_1\">Heading 1</a>\n<li><a href=\"#Heading_2\">Heading 2</a>\n<li><a href=\"#Heading_3\">Heading 3</a>\n</ol>"
    end

    it "should output a table of contents with fewer than 4 headings if __FORCETOC__ is present" do
      parse("==heading==\n__FORCETOC__").should include "<ol>\n     <li><a href=\"#heading\">heading</a>"
    end
  end

  describe "html markup" do
    it "should allow some html markup" do
      parse("<i>test</i>").should == "<p><i>test</i></p>"
      parse("<pre>test</pre>").should == "<p><pre>test</pre></p>"
    end

    it "should be case insensitive" do
      parse("<BlockQuote>some text to be block-quoted</bLocKquoTe>").should == "<p><blockquote>some text to be block-quoted</blockquote></p>"
    end

    it "should encode < and > as &lt; and &gt; when the tag is not allowed" do
      parse("<script>some_script</script>").should == "<p>&lt;script&gt;some_script&lt;/script&gt;</p>"
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

