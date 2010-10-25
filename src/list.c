#include "bstrlib.h"
#include <stdint.h>
#include "list.h"
#include <stdlib.h>
#include <stdio.h>

void list_init(struct list *list) {
  if(list == NULL) {
    return;
  }
  list->head = node_alloc();
  list->tail = list->head;
  list->size = 0;
}

struct node *node_alloc() {
  struct node *item = (struct node *)malloc(sizeof(struct node));
  item->name = bfromcstr("");
  item->content = bfromcstr("");
  item->next = NULL;
  item->level = 0;
  return item;
}

struct node *list_append_new(struct list *list) {
  if(list == NULL) {
    return NULL;
  }

  struct node *child = node_alloc();
  list->tail->next = child;
  list->tail = child;
  list->size++;
  return list->tail;
}

int node_free(struct node *item) {
  if(item == NULL) {
    return 0;
  }
  bdestroy(item->name);
  bdestroy(item->content);
  free(item);
  return 1;
}

int list_iterate(struct node *item, int (*listfunc)(struct node *)) {
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

void list_free(struct list *list) {
  if(list == NULL) {
    return;
  }
  list_iterate(list->head->next, node_free);
  node_free(list->head);
}

int node_print(struct node *item) {
  printf("%s: %s, %llu\n", bdata(item->name), bdata(item->content), item->level);
  return 1;
}

void list_print(struct list *list) {
  if(list == NULL) {
    return;
  }
  list_iterate(list->head->next, node_print);
}
