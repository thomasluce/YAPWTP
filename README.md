YAPWTP
======

Yet Another Peg Wikitext Parser is a C implementation of a large
subset of MediaWiki's wikitext syntax.  It currently takes input
on stdin and presents output on stdout, and there is a Ruby FFI
module for direct library use as well.  The major advantages of
this implementation are intended to be speed and memory footprint.

At the moment a 100 line wikitext file with fairly complex markup
can be parsed in 5-6ms on a one year old Apple MacBook Pro.
