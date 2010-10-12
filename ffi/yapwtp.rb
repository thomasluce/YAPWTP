#!/usr/bin/env ruby

require 'rubygems'
require 'ffi'

class Node < FFI::Struct
  layout :name, :pointer,
         :content, :pointer,
         :level, :int,
         :next, :pointer # This is a pointer to a Node... Don't know how to do that yet...
end

module BString
  extend FFI::Library
  ffi_lib File.join(File.dirname(__FILE__), '..', 'libyapwtp.so')
  # char * bstr2cstr (const_bstring s, char z)
  attach_function :bstr2cstr, [:pointer, :char], :string
  # int bcstrfree (char * s)
  attach_function :bcstrfree, [:string], :int
end

module YAPWTP
  extend FFI::Library
  ffi_lib File.join(File.dirname(__FILE__), '..', 'libyapwtp.so')
  # void init(void)
  attach_function :init, [], :void
  # void cleanup(void)
  attach_function :cleanup, [], :void

  # void parse(bstring inputbuffer, bstring outbuffer);
  attach_function :parse, [], :void

  # void stdin_get_contents(bstring buffer)
  attach_function :stdin_get_contents, [:pointer], :void
  # void file_get_contents(bstring buffer, char *filename)
  attach_function :file_get_contents, [:pointer, :string], :void
  # void str_get_contents(const char *str)
  attach_function :str_get_contents, [:string], :void

  # bstring get_input_buffer(void)
  attach_function :get_input_buffer, [], :pointer
  # char * get_output_buffer_cstr(void)
  attach_function :get_output_buffer_cstr, [], :string

  # void set_base_url(char *str)
  attach_function :set_base_url, [:string], :void

  # void reset_template_iter(void)
  attach_function :reset_template_iter, [], :void
  # struct node *get_next_template(void)
  attach_function :get_next_template, [], :pointer
  # int get_template_count(void)
  attach_function :get_template_count, [], :int
end

class WikiParser
  include YAPWTP
  extend YAPWTP

  def initialize
    init
    @dirty = false
  end

  def self.release(ptr)
    cleanup
  end

  def reset
    cleanup
    init
  end

  def next_template
    return {} if !@dirty
    t = get_next_template
    return nil if t.null?
    template = Node.new(t)
    name = BString.bstr2cstr(template[:name], 20)
    content = BString.bstr2cstr(template[:content], 20)
    # Ruby needs to own these
    n = String.new(name) 
    c = String.new(content) 
    BString.bcstrfree(name)
    BString.bcstrfree(content)
    return { :name => n, :content => c }
  end

  def parsed_text
    if @dirty
      return @output ||= String.new(get_output_buffer_cstr)
    end

    ""
  end

  def html_from_string source
    reset if @dirty
    str_get_contents source
    parse
    @dirty = true
    return parsed_text
  end

  def html_from_file file
    reset if @dirty
    if !File.exist? file
      raise IOError "Can't open #{file}"
    end
    file_get_contents get_input_buffer, file
    parse
    @dirty = true
    return parsed_text
  end

  def each_template
    return nil if !@dirty
    
    reset_template_iter
    while template = next_template
      yield template
    end
  end
end

if __FILE__ == $0
  parser = WikiParser.new

  200.times do
    # Example using Ruby to read a file.  Using the above C-implemented methods is barely faster.
    File.open("../spec/fixtures/cnn.com", "rb") do |f|
      parser.html_from_string f.read
      puts "# Templates: #{parser.get_template_count}"
      puts "-" * 78;
      parser.each_template do |template|
        puts "#{template[:name]} = #{template[:content]}"
        puts "-" * 78;
      end
      puts parser.parsed_text
    end
  end

end
