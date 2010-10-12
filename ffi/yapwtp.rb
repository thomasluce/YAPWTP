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
  ffi_lib "libyapwtp.so" # Must be in your LD_LIBRARY_PATH
  # char * bstr2cstr (const_bstring s, char z)
  attach_function :bstr2cstr, [:pointer, :char], :string
  # int bcstrfree (char * s)
  attach_function :bcstrfree, [:string], :int
end

module YAPWTP
  extend FFI::Library
  ffi_lib "libyapwtp.so" # Must be in your LD_LIBRARY_PATH
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
  # bstring get_input_buffer(void)
  attach_function :get_input_buffer, [], :pointer
  # char * get_output_buffer_cstr(void)
  attach_function :get_output_buffer_cstr, [], :string
  # void str_get_contents(const char *str)
  attach_function :str_get_contents, [:string], :void
  # void set_base_url(char *str)
  attach_function :set_base_url, [:string], :void
  # struct node *get_next_template(void)
  attach_function :get_next_template, [], :pointer
  # int get_template_count(void)
  attach_function :get_template_count, [], :int

  def self.next_template
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

  def self.parsed_text
    String.new(YAPWTP.get_output_buffer_cstr)
  end
end

if __FILE__ == $0
  #YAPWTP.stdin_get_contents(YAPWTP.get_input_buffer)
  #YAPWTP.file_get_contents(YAPWTP.get_input_buffer, "../spec/fixtures/cnn.com")
  
  # Example using Ruby to read a file.  Using the above C-implemented methods is barely faster.
  File.open("../spec/fixtures/cnn.com", "rb") do |f|
    YAPWTP.init
    YAPWTP.str_get_contents f.read
    YAPWTP.parse
    puts "# Templates: #{YAPWTP.get_template_count}"
    puts "-" * 78;
    while template = YAPWTP.next_template
      puts "#{template[:name]} = #{template[:content]}"
      puts "-" * 78;
    end
    puts YAPWTP.parsed_text
    YAPWTP.cleanup
  end

end
