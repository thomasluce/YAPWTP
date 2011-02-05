#!/usr/bin/env ruby
require 'open3'

describe "Wikitext parser" do
  before :suite do
    dir = File.join(File.dirname(__FILE__), '..')
    `cd #{dir} && make`
  end

  def parse(wikitext, *args)
    parser = File.join(File.dirname(__FILE__), '..', 'bin', 'parser')
    result = ""
    Open3.popen3("#{parser} #{args.join(" ")}") do |stdin, stdout, sterr|
      stdin.print wikitext
      stdin.close
      result = stdout.read
    end
    return result
  end

  describe "headings" do
    it "should be able to use windows line-endings" do
      parse("==heading==\r\n").should == "<p>\n  <h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2>\n  <a name=\"heading\"></a>\n</p>"
    end

    it "should not freak out when there are multiple headings" do
      parse("===heading===\n===heading===").should_not include('headingheading')
    end

    it "should be able to do links inside of headings" do
      parse("===[[heading]] ===").should_not include('[[')
    end

    it "should be able to do multiple links in one heading" do
      parse("===[[link]] on [[FOO.com]]===").should == "<p>\n  <h3><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"link_on_FOO.com\"><a href=\"/link\">link</a> on <a href=\"/FOO.com\">FOO.com</a></span></h3>\n  <a name=\"link_on_FOO.com\"></a>\n</p>"
    end

    it "should create the markup like mediawiki" do
      parse("===heading ===").strip.should == "<p>\n  <h3><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h3>\n  <a name=\"heading\"></a>\n</p>"
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
      result.should include('<h3>')
      result.should include('</h3>')
    end

    it "should not output bogus h tags" do
      result = parse("========== heading ==").strip
      result.should_not include("<h10>")
      result.should include("<h5>")
    end
  end

  describe "paragraphs" do
    it "should be able to notice paragraph breaks" do
      parse(".\n\n.").strip.should == "<p>.</p>\n<p>.</p>"
    end

    it "should be able to make a horizontal line" do
      parse("----").strip.should =~ /<hr\/>/
    end

    it "should not get confused with colons in the middle of a line" do
      parse("* ''Unordered lists'' are easy to do:\n** Start every line with a star.").should_not include '**'
    end

    it "should not make shitty paragraphs" do
      parse("paragraph 1\n\nparagraph 2").should == "<p>paragraph 1</p>\n<p>paragraph 2</p>"
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

    it "should handle nested lists that drop more than one level at a time" do
      parse("* one\n* two\n** A\n** B\n*** a\n*** b\n* three\n* four\n").should include("</ul></ul><li>three")
      parse("# one\n# two\n## A\n## B\n### a\n### b\n# three\n# four\n").should include("</ol></ol><li>three")
    end

    it "should be able to make numbered lists" do
      parse('# test').should == '<p><ol><li>test</li></ol></p>'
      parse("# test\n").should == '<p><ol><li>test</li></ol></p>'
      parse("# test\n#test2").should == '<p><ol><li>test</li><li>test2</li></ol></p>'
    end

    it "should be able to nest numbered lists" do
      parse("# test\n#test2\n## nested").should == '<p><ol><li>test</li><li>test2</li><ol><li>nested</li></ol></ol></p>'
    end

    it "should be able to make definition lists/indented lists" do
      parse(":text").strip.should == "<p><dl><dd>text</dd></dl></p>"
    end

    it "should be able to nest definition lists" do
      parse(":text\n::text").strip.should == "<p><dl><dd>text<dl><dd>text</dd></dl></dd></dl></p>"
    end

    it "should process other wiki text inside of list items" do
      parse("* [[link]]").should == '<p><ul><li><a href="/link">link</a></li></ul></p>'
    end

    it "should protect HTML markup just like anywhere else" do
      parse("* <a href=\"wikipedia.org\">wikipedia</a>").should_not include("<a href=")
    end

    it "should not begin a list in the middle of a list line" do
      parse("* foo * asf").scan("<ul>").size.should == 1
      parse("# foo # asf").scan("<ol>").size.should == 1
    end

    it "should only begin a list when the bullet or hash is at the beginning of a line" do
      parse("Some text # foo # asf").scan("<ol>").size.should == 0
      parse("Some text * foo * asf").scan("<ul>").size.should == 0
    end

	it "should protect against loose angle brackets" do
      parse("< script >").should include("&lt; script &gt;")
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

    it "should pass through anything valid that is inside of <nowiki> tags" do
      parse("<nowiki>'''format'''\n\n'''format'''</nowiki> '''format'''").should == "<p>'''format'''\n\n'''format''' <b>format</b></p>"
    end

    it "should treat <pre> tags as nowiki tags" do
      parse("<pre>'''bold'''</pre>").should == "<p><pre>'''bold'''</pre></p>";
    end

    it "should treat <code> tags as nowiki tags" do
      parse("<code>'''bold'''</code>").should == "<p><code>'''bold'''</code></p>";
    end

    it "should handle nowiki in complex situations" do
      parse('{| cellspacing="0" border="1"
        !style="width:50%"|You type
        !style="width:50%"|You get
        |-
        |
        <pre>
        {|
        |Orange
        |Apple
        |-
        |Bread
        |Pie
        |-
        |Butter
        |Ice cream 
        |}
        </pre>
        |
        {|
        |Orange
        |Apple
        |-
        |Bread
        |Pie
        |-
        |Butter
        |Ice cream 
        |}
        |}'.gsub('        ', '')).should == "<p><table cellspacing=\"0\" border=\"1\"><tr><th style=\"width:50%\">You type</th><th style=\"width:50%\">You get</th></tr><tr><td>\n<pre>\n{|\n|Orange\n|Apple\n|-\n|Bread\n|Pie\n|-\n|Butter\n|Ice cream \n|}\n</pre></td><td>\n<table><tr>\n<td>Orange</td><td>Apple</td></tr>\n<tr><td>Bread</td><td>Pie</td></tr><tr><td>Butter</td><td>Ice cream</td></tr></table></td></tr></table></p>"
    end

    it "should not pass HTML tags through when using <nowiki>" do
      parse("<nowiki><div>asdf</div></nowiki>").should == "<p>asdf</p>"
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
      result.should include('<a href="/Namespace:test"')
      result.should include('>test</a>')
    end

    it "should support a base URL to be supplied on the command line or via the API" do
      parse("[[link]]", "/foofoo").should include("/foofoo/link")
    end
    # TODO: interwiki links. Or not.

    # blended links
    it "should be able to make blended links" do
      parse("[[path]]s").should == '<p><a href="/path">paths</a></p>'
    end

    it "should not blend formatting characters and wreck the wikitext tag" do
      parse("<s>'''Segfaults on [[Parsed Examples]]'''</s>").should include("<s><b>Segfaults on <a href=\"/Parsed_Examples\">Parsed Examples</a></b></s>")
      parse("[[Link]]{{template}}").should_not include("{{")
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
      parse("[[FooFoo]][http://BarBar.com/]").should_not include("[")
    end

    it "should handle more than one link on a line" do
      parse("[[FooFoo]] in [[BarBar]]").should_not include("[[")
    end

    it "should handle at least a renamed link and a simple link on a line" do
      parse("[[User_talk:Mr Big/FOO.com|Mr Big's Comments]] on [[FOO.com]]").should 
      be("<p><a href=\"/User_talk:Mr_Big/FOO.com\">Mr Big's Comments</a> on <a href=\"/FOO.com\">FOO.com</a></p>")
    end

    it "should not add pre tags when the link is followed by a space" do
      parse("[http://www.flowerpetal.com FlowerPetal.com] is the easy way to send flowers online").should_not
      include("<pre>")
    end

    it "should not allow javascript links" do
      parse("[javascript:alert('pwnd')]").should_not include('<a')
    end
  end

  describe "images" do
    describe "image linking" do
      it "should link to nothing if you give it a blank link" do
        parse("[[File:image.png|link=]]").should == '<p><img src="image.png" /></p>'
      end

      it "should link to someplace if you give it a valid link" do
        parse("[[File:image.png|link=http://www.google.com]]").should == '<p><a href="http://www.google.com" class="image"><img src="image.png" /></a></p>'
      end
    end

    describe "caption" do
      it "should be able to give a default image a title on the link" do
        parse("[[File:image.png|caption HO!]]").should == '<p><a href="/File:image.png" class="image" title="caption HO!"><img src="image.png" /></a></p>'
      end

      it "should be able to put the caption in a visible location if framed or thumbed" do
        parse("[[File:image.png|frame|caption HO!]]").should include('<div class="thumbcaption">caption HO!</div>')
      end
    end

    # TODO: size attribute
    it "should be able to make an image" do
      parse("[[File:image.png]]").should == '<p><a href="/File:image.png" class="image"><img src="image.png" /></a></p>'
    end

    it "should be able to put a border around an unframed image" do
      parse("[[File:image.png|border]]").should include('class="thumbimage"')
    end

    it "should be able to use the alternate, 'Image:' indicator" do
      parse("[[Image:image.png]]").should == '<p><a href="/File:image.png" class="image"><img src="image.png" /></a></p>'
    end

    it "should be able to apply alt-text to an image" do
      parse("[[File:image.png|alt=alt text]]").should include('alt="alt text"')
    end

    it "should be able to link to the file instead of display it" do
      parse("[[:File:image.png]]").should == '<p><a href="/File:image.png">image.png</a></p>'
      # TODO: "Media:" links that you can title
    end

    it "should be able to float the image left, right, center, or not at all" do
      parse("[[File:image.png|left]]").should include('class="floatleft"')
    end

    it "should be able to set an image base URL" do
      parse("[[File:image.png]]", "/", "/images/" ).should include("src=\"/images/image.png\"")
    end

    describe "thumbnail" do
      # TODO: if a filename is given as the value to 'thumb=', use that without the width, and height.
      it "should scale the image down" do
        parse("[[File:image.png|thumb]]").should include('class="thumbimage"')
      end

      it "should scale the image down" do
        parse("[[File:image.png|thumbnail]]").should include('class="thumbimage"')
      end
    end

    describe "frame" do
      it "should attach the thumbimage class but not actually size it down" do
        parse("[[File:image.png|frame]]").should include('class="thumbimage"')
      end
    end
  end

  describe "tables -- oh boy..." do
    it "should be able to make a caption for the table" do
      parse("{|
        |+ caption
        |-
        |}".gsub(/^ */, '')).should == "<p><table><caption>caption</caption><tr></tr></table></p>"
    end

    it "should support attributes on captions" do
      parse('{|
          |+ align="bottom" style="color:#e76700;" |''Food complements''
          |-
          |Orange
          |Apple
          |}
          '.gsub(/^ */,'')).should == "<p><table><caption align=\"bottom\" style=\"color:#e76700;\">Food complements</caption><tr><td>Orange</td><td>Apple</td></tr></table>\n</p>"
    end

    describe "rows" do
      it "should be able to do simple rows" do
        parse("{|
          |-
          | cell one
          |}".gsub(/^ */, "")).should == "<p><table><tr><td>cell one</td></tr></table></p>"
      end
  
      it "should be able to do single-line rows" do
        parse("{|
          |-
          | Cell one || Cell two
          |}".gsub(/^ */, "")).should == "<p><table><tr><td>Cell one</td><td>Cell two</td></tr></table></p>"
      end
  
      it "should be able to do a few rows" do
        parse("{|
          |+ Caption
          |-
          | cell || cell
          |-
          | cell
          | cell
          |}".gsub(/^ */, '')).should == "<p><table><caption>Caption</caption><tr><td>cell</td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table></p>"
      end

      it "should not require a row delimiter on the first row" do
        parse("{|
          |Orange||Apple||more
          |-
          |Bread||Pie||more
          |-
          |Butter||Ice<br />cream||and<br />more
          |}
          ".gsub(/^ */, '')).should_not include("{|")
      end

      it "should allow images inside table cells" do
        parse("{|
          |[[Image:SomeImage.png]]
          |}".gsub(/^ */,'')).should == "<p><table><tr>\n<td><a href=\"/File:SomeImage.png\" class=\"image\"><img src=\"SomeImage.png\" /></a></td></tr></table></p>"
      end
    end

    it "should handle ugly input text" do
      parse("{|
        |-
        |cell1||cell2   || align=\"right\"| cell3
        |}".gsub(/^ */,'')).should == "<p><table><tr><td>cell1</td><td>cell2</td><td align=\"right\">cell3</td></tr></table></p>"
    end


    it "should support full wikitext markup in table cells even with line feeds" do
      text = parse("{|
       |Lorem ipsum dolor sit amet, 
       consetetur sadipscing elitr, 
       sed diam nonumy eirmod tempor invidunt
       ut labore et dolore magna aliquyam erat, 
       sed diam voluptua. 
       
       At vero eos et accusam et justo duo dolores
       et ea rebum. Stet clita kasd gubergren,
       no sea takimata sanctus est Lorem ipsum
       dolor sit amet. 
       |
       * Lorem ipsum dolor sit amet
       * consetetur sadipscing elitr
       * sed diam nonumy eirmod tempor invidunt
       |}
       ".gsub(/^ */,''))
      text.should include("<ul><li>")
      text.should_not include("{|")
      text.should_not include("|}")
    end

    it "should support attributes on the table" do
      parse('{| cellspacing="0" border="1"
!style="width:50%"|You type
!style="width:50%"|You get
|-
|}').should == "<p><table cellspacing=\"0\" border=\"1\"><tr><th style=\"width:50%\">You type</th><th style=\"width:50%\">You get</th></tr><tr></tr></table></p>"

      parse('{|style="border-collapse: separate; border-spacing: 0; border-width: 1px; border-style: solid; border-color: #000; padding: 0"
          |-
          !style="border-style: solid; border-width: 0 1px 1px 0"| Orange
          !style="border-style: solid; border-width: 0 0 1px 0"| Apple
          |-
          |style="border-style: solid; border-width: 0 1px 0 0"| Bread
          |style="border-style: solid; border-width: 0"| Pie
          |}'.gsub(/^ */,'')).should == "<p><table style=\"border-collapse: separate; border-spacing: 0; border-width: 1px; border-style: solid; border-color: #000; padding: 0\"><tr><th style=\"border-style: solid; border-width: 0 1px 1px 0\">Orange</th><th style=\"border-style: solid; border-width: 0 0 1px 0\">Apple</th></tr><tr><td style=\"border-style: solid; border-width: 0 1px 0 0\">Bread</td><td style=\"border-style: solid; border-width: 0\">Pie</td></tr></table></p>"
    end

    it "should support attributes on row definitions" do
      parse('{|
        |- style="color:red"
        | data
        |}'.gsub(/^ */, '')).should == '<p><table><tr style="color:red"><td>data</td></tr></table></p>'
    end

	it "should not require table end tags" do
      parse('{|
        |- style="color:red"
        | data'.gsub(/^ */, '')).should == '<p><table><tr style="color:red"><td>data</td></tr></table></p>'
	end

    describe "headers" do
      it "should be able to make simple headers" do
        text = parse("{|
                |+Caption
                ! heading 1
                ! heading 2
                |}".gsub(/^ */, ''))
        text.should include("<th>heading 1</th><th>heading 2</th>");
        text.should_not include("{|");
      end

      it "should be able to make complex headers" do
        parse("{|
                |+ Caption
                ! scope=\"col\" | column heading 1
                ! scope=\"col\" | column heading 2
                |-
                | cell || cell
                |-
                | cell
                | cell
                |}".gsub(/^ */,'')).should == "<p><table><caption>Caption</caption><tr><th scope=\"col\">column heading 1</th><th scope=\"col\">column heading 2</th></tr><tr><td>cell</td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table></p>"
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
                |}".gsub(/^ */,'')).should == "<p><table><caption>Caption</caption><tr><th scope=\"col\">column heading 1</th><th scope=\"col\">column heading 2</th></tr><tr><th scope=\"row\">row heading</th><td>cell</td><td>cell</td></tr><tr><td>cell</td><td>cell</td></tr></table></p>"
      end

      it "should be able to do headers even with a first row defined" do
        text = parse("{|
|-
! heading 1
! heading 2
|}")
      end

      describe "cells" do
        it "should allow attributes for cells at the beginning of a line" do
          parse('{| border="1"
                  |Orange
                  |align="right" | Apple
                  |}'.gsub(/^ */, '')).should include("<td align=\"right\">Apple</td>")
        end
  
        it "should allow attributes on cells that are inlined" do
          parse('{| border="1"
                  | Orange || Apple     || align="right" | 12,333.00
                  |-
                  | Bread  || Pie       || align="right" | 500.00
                  |-
                  | Butter || Ice cream || align="right" | 1.00
                  |}'.gsub(/^ */,'')).scan("<td align=\"right\">").size.should == 3;
        end
      end
    end
  end

  describe "templates" do
    it "should replace all template content with __name_hash__" do
      parse('{{template}}').should == '<p>__template_5381__</p>'
    end

	it "should ignore templates inside <noinclude tags>" do
      parse("<noinclude>{{template}}</noinclude>").should include("{{template}}")
	end
  end

  describe "table of contents" do
    it "should not output a table of contents if  __NOTOC__ is present" do
      parse("==Heading 1==\n__NOTOC__\n==Heading 2==\n==Heading 3==").should_not include("<ol>")
    end

    it "should replace __TOC__ with the table of contents if more than 3 headings are present" do
      parse("==heading==\n__TOC__\n==heading==\n==heading==").should ==
        "<p>\n  <h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2>\n  <a name=\"heading\"></a>\n__TOC__\n\n  <h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2>\n  <a name=\"heading\"></a>\n\n  <h2><span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"heading\">heading</span></h2>\n  <a name=\"heading\"></a>\n</p>"
    end

    it "should not output a table of contents when fewer than 3 headings are present" do
      parse("==Heading 1==\n==Heading 2==\n").should_not include("<ol>")
    end

    it "should output a table of contents when more than 3 headings are present" do
      parse("==Heading 1==\n==Heading 2==\n==Heading 3==\n==Heading 4==").should include("<ol>\n     <li><a href=\"#Heading_1\">Heading 1</a></li>\n     <li><a href=\"#Heading_2\">Heading 2</a></li>\n     <li><a href=\"#Heading_3\">Heading 3</a></li>\n     <li><a href=\"#Heading_4\">Heading 4</a></li>\n</ol>")
    end

    it "should output a table of contents with fewer than 4 headings if __FORCETOC__ is present" do
      parse("==heading==\n__FORCETOC__").should include("<ol>\n     <li><a href=\"#heading\">heading</a>")
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

    it "should handle simple tags" do
      parse("<div>some text</div>").should == "<p><div>some text</div></p>"
    end

    it "should handle complex tags" do
      parse("<div name=\"something\">some text</div>").should == "<p><div name=\"something\">some text</div></p>"
    end

    it "should filter attributes, allowing only name and id for now" do
      parse("<div id=\"myid\" onclick=\"javascript:alert('vulnerable'); return 0;\">text</div>").should ==
        "<p><div id=\"myid\">text</div></p>"
    end

    it "should filter complex attributes, ignoring anything following a badly formed one" do
      parse("<div id=\"myid\" foofoo=\"sss\" NAME=\"Asdf\" onclick=\"javascript:alert('vulnerable'); return 0; name=\"asdf\"/>text</div>").should == "<p><div id=\"myid\" name=\"Asdf\">text</div></p>"
    end

	it "should allow html h* tags" do
      parse("<h1>sadf</h1><h2 style=\"color: red\">asdf</h2>").should == "<p><h1>sadf</h1><h2 style=\"color: red\">asdf</h2></p>"      
	end

	describe "poorly nested tags" do
	  it "should auto-close tags that are not closed when their parent tag gets closed" do
	    parse("<div><b>testing</div>").should include "<div><b>testing</b></div>"
	  end

	  it "should auto-close all tags at the end of a document" do
	    parse("<div><i><b>some data").should include "<div><i><b>some data</b></i></div>"
	  end

	  it "should handle crazy-stacked similar tags" do
	    parse("<div><b><b><b>something</b></b></div>").should include "<div><b><b><b>something</b></b></b></div>"
	  end
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

