#ifndef __STACK_H__
#define __STACK_H__

#include "util.h"
#include <stdbool.h>

typedef struct {
	void *arr;
	size_t length, capacity;
} stack_t;

#define stack_empty(s) ((s).length == 0)
#define stack_init(arr, cap) stack_init_int((void*)(arr), (cap))
#define stack_push(s,val) do {                                 \
	if ((s).length == (s).capacity)                        \
		die("stack" #s "has no remaining capacity\n"); \
	((__typeof__(val)*)((s).arr))[(s).length++] = (val);  \
} while (0)

#define stack_peek(s, typevar) ((typevar*)((s).arr))[(s).length - 1]
#define stack_pop(s, typevar)  (((typevar*)(s).arr)[--(s).length])

stack_t stack_init_int (void *arr, size_t cap)
{
	return (stack_t){ .arr = arr, .length = 0, .capacity = cap };
}

#endif //__STACK_H__
