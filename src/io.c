#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include "yapwtp.h"
#include "io.h"
#include "bstrlib.h"

// Buffer printf, buffer output until we're ready
void bprintf(const char *fmt, ...) {
  int ret;
  bvformata(ret, output_buffer, fmt, fmt);
}

// Read from a string buffer rather than a file when requested by leg code.
// Could be made faster by reading more than a byte at a time... (up to max_size)
void handle_input(char *buf, int *result, size_t max_size) {
  if(input_buffer_pos > input_buffer->slen) {
    *result = 0;
	return;
  }
  *buf = input_buffer->data[input_buffer_pos++];
  *result = 1;
}

// Read a file into a bstring buffer 
void file_get_contents(bstring buffer, char *filename) {
  if(!buffer) {
    printf("Invalid buffer supplied to buffer_from_file.\n");
  }

  FILE *infile;
  if(!(infile = fopen(filename, "r"))) {
     printf("Can't open %s to read.\n", filename);
  }
  breada(buffer, (bNread)fread, infile);
  fclose(infile);
}

// Read from stdin until EOF, buffering to a bstring (destructive)
void stdin_get_contents(bstring buffer) {
  int c;
  ballocmin(buffer, 100 * KBYTE);
  buffer->slen = 0;
  while(EOF != (c = getchar())) {
    if(buffer->slen == buffer->mlen) {
      ballocmin(buffer, buffer->mlen * 2); // Just double the buffer
	  buffer->mlen = buffer->mlen * 2;
	}
    buffer->data[buffer->slen] = c;
	buffer->slen++;
  }
  buffer->slen--; // Move the pointer back on the very last pass
}

// Fill the input buffer from a standard C string
void str_get_contents(const char *str) {
  bcatcstr(input_buffer, str);
}
