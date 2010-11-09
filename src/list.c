#include "bstrlib.h"
#include <stdint.h>
#include <inttypes.h>
#include "list.h"
#include <stdlib.h>
#include <stdio.h>

void kw_list_init(struct list *list) {
  if(list == NULL) {
    return;
  }
  list->head = kw_node_alloc();
  list->tail = list->head;
  list->size = 0;
}

struct node *kw_node_alloc() {
  struct node *item = (struct node *)malloc(sizeof(struct node));
  item->name = bfromcstr("");
  item->content = bfromcstr("");
  item->next = NULL;
  item->level = 0;
  return item;
}

struct node *kw_list_append_new(struct list *list) {
  if(list == NULL) {
    return NULL;
  }

  struct node *child = kw_node_alloc();
  list->tail->next = child;
  list->tail = child;
  list->size++;
  return list->tail;
}

int kw_node_free(struct node *item) {
  if(item == NULL) {
    return 0;
  }
  bdestroy(item->name);
  bdestroy(item->content);
  free(item);
  return 1;
}

int kw_list_iterate(struct node *item, int (*listfunc)(struct node *)) {
  struct node *next;
  while(item != NULL) {
    next = item->next;
    if(listfunc(item) != 1) {
      return 0;
    }
    item = next;
  }
  return 1;
}

void kw_list_free(struct list *list) {
  if(list == NULL || list->head == NULL) {
    return;
  }
  kw_list_iterate(list->head->next, kw_node_free);
  if(list->head) kw_node_free(list->head);
}

int node_print(struct node *item) {
  printf("%s: %s, %"PRIu64"\n", bdata(item->name), bdata(item->content), item->level);
  return 1;
}

void kw_list_print(struct list *list) {
  if(list == NULL) {
    return;
  }
  kw_list_iterate(list->head->next, node_print);
}
