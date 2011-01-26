#include "stack.h"
#include <stdlib.h>
#include <stdio.h>

void stack_init(stack *s) {
  s->stack = malloc(STACK_DEFAULT_SIZE * sizeof(void*));
  s->pos = 0;
  s->mlen = STACK_DEFAULT_SIZE;
}

void stack_free(stack *s) {
  if(!s) return;
  if(!s->stack) return;

  free(s->stack);
}

void *stack_grow(stack *s) {
  void *junk;   // So we don't whack s->stack on failure
  s->mlen *= 2; // Double it
  junk = realloc(s->stack, sizeof(void *) * s->mlen);
  return junk;
}

int push(stack *s, void *item) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to push()\n");
	return -1;
  }
  if(!item) return -1;
  if(s->pos >= s->mlen && !stack_grow(s)) {
    fprintf(stderr, "Realloc failed\n"); 
    return -1;
  }

  s->stack[s->pos] = item;
  return ++s->pos;
}

void *pop(stack *s) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to pop()\n");
	return NULL;
  }
  if(s->pos > s->mlen) return NULL;
  if(s->pos - 1 < 0) return NULL;

  return s->stack[--s->pos];
}

void *peek(stack *s, int back) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to peek()\n");
	return NULL;
  }
  int pos = s->pos - back - 1;
  if(pos < 0) {
	return NULL;
  }

  return s->stack[pos];
}
