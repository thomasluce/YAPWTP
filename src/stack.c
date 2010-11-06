#include "stack.h"
#include <stdlib.h>
#include <stdio.h>

/* INFO: This stack copies what is passed in to it so that it
   owns the data.  The pop() function copies the data out and
   frees the original copy.
 */

void stack_init(stack *s) {
  s->stack = (bstring *)malloc(STACK_DEFAULT_SIZE * sizeof(void*));
  s->pos = 0;
  s->mlen = STACK_DEFAULT_SIZE;
}

void stack_free(stack *s) {
  if(!s || !s->stack) return;

  if(s->pos > 0 || (s->stack[s->pos])) {
    bstring tmp = bfromcstr("");
    while(pop(tmp, s)){};
	bdestroy(tmp);
  }
  free(s->stack);
}

void *stack_grow(stack *s) {
  void *junk;   // So we don't whack s->stack on failure
  s->mlen *= 2; // Double it
  junk = realloc(s->stack, sizeof(void *) * s->mlen);
  return junk;
}

int push(stack *s, char *item) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to push()\n");
	return -1;
  }
  if(!item) return -1;
  if(s->pos >= s->mlen && !stack_grow(s)) {
    fprintf(stderr, "Realloc failed\n"); 
    return -1;
  }

  s->stack[s->pos] = bfromcstr(item);
  return ++s->pos;
}

int pop(bstring target, stack *s) {
  if(!s) {
    fprintf(stderr, "Bad stack passed to pop()\n");
	return 0;
  }
  if(s->pos > s->mlen) return 0;
  if(s->pos - 1 < 0) return 0;

  s->pos--;
  bassign(target, s->stack[s->pos]);
  bdestroy(s->stack[s->pos]);

  return 1;
}
