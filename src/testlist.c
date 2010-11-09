#include <stdio.h>
#include "bstrlib.h"
#include "list.h"

int main(void) {
  struct list list;

  kw_list_init(&list);

  struct node *current = kw_list_append_new(&list);
  bassign(current->name, bfromcstr("heading1"));
  current->level = 1;

  int i;
  for(i = 2; i < 200000; i++ ) {
    current = kw_list_append_new(&list);
    current->name = bformat("heading%d", i % 3 + 1);
    current->content = bformat("content%d", i % 3 + 1);
    current->level = i % 3 + 1;
  }

  kw_list_print(&list);
  kw_list_free(&list);
}
