
#ifndef __LIST_H
#define __LIST_H
struct node {
  bstring name;
  bstring content;
  long long level;
  struct node *next;
};

struct list {
  struct node *tail;
  struct node *head;
  int size;
};

void list_init(struct list *list);
struct node *node_alloc();
struct node *list_append_new(struct list *list);
int node_free(struct node *item);
int list_iterate(struct node *item, int (*listfunc)(struct node *));
void list_free(struct list *list);
void list_print(struct list *list);

#endif
