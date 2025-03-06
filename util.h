#ifndef __UTIL_H__
#define __UTIL_H__

#define UNUSED(...) ((void)(__VA_ARGS__))
#define LEN(arr) (sizeof(arr) / sizeof(arr[0]))

#define eprintf(...) fprintf(stderr, "ERR: " __VA_ARGS__)
#define die(...) ({                                  \
		fprintf(stderr, "DIE:" __VA_ARGS__); \
		exit(-1);                            \
		})
#define dbg(x, fmt) \
	eprintf("DBG\t%s:%d\t" #x ":\t" fmt "\n", __FILE__, __LINE__, x);

#endif // __UTIL_H__
