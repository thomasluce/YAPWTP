#ifndef __STACK_H
#define __STACK_H

#define STACK_DEFAULT_SIZE 32

typedef struct stack {
  int pos;	// The current position in the stack array
  int mlen;	// The length of the memory unit allocated for the stack
  void **stack; // The stack array
} stack;

void stack_init(stack *s);
void stack_free(stack *s);
void *stack_grow(stack *s);
int push(stack *s, void *item);
void *pop(stack *s);
#endif
