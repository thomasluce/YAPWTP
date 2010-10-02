#include "bstrlib.h"
#include "list.h"
#include <stdlib.h>
#include <stdio.h>

void init_list(struct list *list) {
  if(list == NULL) {
    return;
  }
  list->head = node_alloc();
  list->tail = list->head;
}

struct node *node_alloc() {
  struct node *item = (struct node *)malloc(sizeof(struct node));
  item->name = bfromcstr("");
  item->next = NULL;
  return item;
}

struct node *get_new_tail(struct list *list) {
  if(list == NULL) {
    return NULL;
  }

  struct node *child = node_alloc();
  list->tail->next = child;
  list->tail = child;
  return list->tail;
}

void node_free(struct node *item) {
  if(item == NULL) {
    return;
  }
  bdestroy(item->name);
  free(item);
}

void list_free(struct list *list) {
  if(list == NULL) {
    return;
  }
  struct node *i = list->head->next;
  struct node *next;
  while(i != NULL) {
	next = i->next;
    node_free(i);
	i = next;
  }
  node_free(list->head);
}

void print_list(struct list *list) {
  struct node *i = list->head->next;
  struct node *next;
  while(i != NULL) {
	next = i->next;
	printf("%s: %d\n", bdata(i->name), i->level);
	i = next;
  }
}
