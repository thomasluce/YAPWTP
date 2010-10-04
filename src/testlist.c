#include <stdio.h>
#include "bstrlib.h"
#include "list.h"

int main(void) {
  struct list list;

  list_init(&list);

  struct node *current = list_get_new_tail(&list);
  bassign(current->name, bfromcstr("heading1"));
  current->level = 1;

  int i;
  for(i = 2; i < 200000; i++ ) {
    current = list_get_new_tail(&list);
    current->name = bformat("heading%d", i % 3 + 1);
    current->content = bformat("content%d", i % 3 + 1);
    current->level = i % 3 + 1;
  }

  list_print(&list);
  list_free(&list);
}
