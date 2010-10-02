struct node {
  bstring name;
  int level;
  struct node *next;
};

struct list {
  struct node *tail;
  struct node *head;
};

void init_list(struct list *list);
struct node *node_alloc();
struct node *get_new_tail(struct list *list);
void node_free(struct node *item);
void list_free(struct list *list);
void print_list(struct list *list);
