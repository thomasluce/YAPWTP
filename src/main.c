#include "yapwtp.h"
#include "io.h"

int main() {
   init();
   //file_get_contents(input, "spec/fixtures/cnn.com");
   stdin_get_contents(input_buffer);
   parse();
   printf("%s", bdata(output_buffer));
   cleanup();
   return 0;
 }
