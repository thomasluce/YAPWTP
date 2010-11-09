
#ifndef __LIST_H
#define __LIST_H
#include <stdint.h>

struct node {
  bstring name;
  bstring content;
  uint64_t level;
  struct node *next;
};

struct list {
  struct node *tail;
  struct node *head;
  int size;
};

void kw_list_init(struct list *list);
struct node *kw_node_alloc();
struct node *kw_list_append_new(struct list *list);
int kw_node_free(struct node *item);
int kw_list_iterate(struct node *item, int (*listfunc)(struct node *));
void kw_list_free(struct list *list);
void kw_list_print(struct list *list);

#endif
