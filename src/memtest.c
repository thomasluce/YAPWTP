#include "yapwtp.h"
#include "io.h"

// Run the thing 2k times so we can watch memory usage externally.

int main() {
  int i;
  for(i = 0; i < 2000; i++) {
    init();
    file_get_contents(input_buffer, "spec/fixtures/cnn.com");
    parse();
    printf("%d\n", i);
    cleanup();
  }
  return 0;
}
