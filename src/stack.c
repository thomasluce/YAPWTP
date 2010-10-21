#include <stdio.h>
#include <stdlib.h>

#define STACK_MAX_SIZE 50

typedef struct stack {
  void **stack;
  int pos;
} stack;

void stack_init(stack *s) {
  s = malloc(sizeof(stack));
  s->stack = malloc(STACK_MAX_SIZE * sizeof(s->stack));
  s->pos = 0;
}

void stack_free(stack *stack) {
  if(!stack) return;
  if(!stack->stack) return;

  free(stack->stack);
  free(stack);
}

int push(stack *s, void *item) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to push()\n");
	return -1;
  }
  if(s->pos >= STACK_MAX_SIZE) return -1;
  if(!item) return -1;

  s->stack[s->pos] = item;
  return ++s->pos;
}

void *pop(stack *s) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to pop()\n");
	return NULL;
  }
  if(s->pos > STACK_MAX_SIZE) return NULL;

  return s->stack[s->pos--];
}

int main(void) {
  long i;
  stack *m;

  stack_init(m);

  for(i = 0; i < 50; i++) {
    printf("--%ld\n", i);
  	push(m, (void *)i);
  }

  for(i = 49; i >= 0; i--) {
    printf("%ld\n", (long int)pop(m));
  }

  stack_free(m);
}
