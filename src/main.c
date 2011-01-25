#include "kiwi.h"
#include "io.h"

int main(int argc, char **argv) {
   init();
   //file_get_contents(input, "spec/fixtures/cnn.com");
   stdin_get_contents(input_buffer);
   if(argc > 0) {
     set_base_url(argv[1]);
   }
   if(argc > 1) {
     set_image_base_url(argv[2]);
   }
   parse();
   printf("%s", bdata(output_buffer));
   cleanup();
   return 0;
 }
