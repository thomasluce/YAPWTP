#include "yapwtp.h"
#include "io.h"

extern void parse(bstring inputbuffer, bstring outbuffer);

int main() {
  bstring output = bfromcstr("");
  bstring input = bfromcstr("");
  //file_get_contents(input, "spec/fixtures/cnn.com");
  stdin_get_contents(input);
  parse(input, output);
  printf("%s", bdata(output));
  bdestroy(output);
  return 0;
}
