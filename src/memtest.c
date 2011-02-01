#include "kiwi.h"
#include "io.h"

// Run the thing 2k times so we can watch memory usage externally.

int main() {
  int i;
  for(i = 0; i < 100; i++) {
    init();
    file_get_contents(input_buffer, "spec/fixtures/tables");
    parse();
    printf("%d\n", i);
    cleanup();
  }
  return 0;
}
