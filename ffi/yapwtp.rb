#!/usr/bin/env ruby

require 'rubygems'
require 'ffi'

class Bstring < FFI::Struct
  layout :data, :pointer,
         :slen, :int,
         :mlen, :int
end

class Node < FFI::Struct
  layout :name, :pointer,
         :content, :pointer,
         :level, :int,
         :next, :pointer # This is a pointer to a Node... Don't know how to do that yet...
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

  # char * bstr2cstr (const_bstring s, char z)
  attach_function :bstr2cstr, [:pointer, :char], :string

  # int bcstrfree (char * s)
  attach_function :bcstrfree, [:string], :int

  def self.next_template
    template = Node.new(YAPWTP.get_next_template())
    name = YAPWTP.bstr2cstr(template[:name], 20)
    n = String.new(name) # Ruby gets to own this one
    YAPWTP.bcstrfree(name)
    return n
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
    YAPWTP.get_template_count.times do |i|
      puts "#{YAPWTP.next_template}"
      puts "-" * 78;
    end
    puts YAPWTP.get_output_buffer_cstr 
    YAPWTP.cleanup
  end

end
