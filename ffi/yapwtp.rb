#!/usr/bin/env ruby

require 'rubygems'
require 'ffi'

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
end

if __FILE__ == $0
  #YAPWTP.stdin_get_contents(YAPWTP.get_input_buffer)
  #YAPWTP.file_get_contents(YAPWTP.get_input_buffer, "../spec/fixtures/cnn.com")
  
  200.times do |i|

    # Example using Ruby to read a file.  Using the above C-implemented methods is barely faster.
    File.open("../spec/fixtures/cnn.com", "rb") do |f|
      YAPWTP.init
      YAPWTP.str_get_contents f.read
      YAPWTP.parse
      #puts YAPWTP.get_output_buffer_cstr 
      puts i
      YAPWTP.cleanup
    end

  end

end
