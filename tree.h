/* A simple tree implementation for making a table of contents from headings */

struct node {
  int num_children;
  char name[1024];
  struct node **children;
};

struct node_list {
  int num_nodes;
  struct node **nodes;
};

struct node_list *make_list() {
  struct node_list *list = malloc(sizeof(struct node_list));
  list->num_nodes = 0;
  return list;
};

void node_list_append(struct node_list *list, struct node *tree) {
  if(list->num_nodes == 0) {
    list->nodes = (struct node **)malloc(sizeof(struct node) * 10);
  } else if(list->nodes + 1 % 10 == 0) {
    list->nodes = realloc(list->nodes, sizeof(struct node) * (list->num_nodes + 11));
  }
  list->nodes[list->num_nodes] = tree;
  list->num_nodes++;
}

struct node *make_tree(char *name) {
  struct node *n = malloc(sizeof(struct node));
  n->num_children =0;
  strcpy(n->name, name);
  return n;
}

void node_append_child(struct node *parent, char *name) {
  if(parent->num_children == 0) {
    parent->children = (struct node **)malloc(sizeof(struct node) * 10);
  } else if(parent->num_children + 1 % 10 == 0) {
    parent->children = realloc(parent->children, sizeof(struct node) * (parent->num_children + 11));
  }

  parent->children[parent->num_children] = make_tree(name);
  parent->num_children++;
}

void node_print(struct node *tree) {
  printf("%s\n", tree->name);
  int i;
  for(i = 0; i < tree->num_children; i++) {
    node_print(tree->children[i]);
  }
}

void node_free(struct node *tree) {
  if(tree->num_children > 0) {
    int i;
    for(i = 0; i < tree->num_children; i++) node_free(tree->children[i]);
  }
  free(tree->children);
  free(tree);
}

void list_free(struct node_list *list) {
  int i;
  for(i = 0; i < list->num_nodes; i++) {
    node_free(list->nodes[i]);
  }
  free(list->nodes);
  free(list);
}
