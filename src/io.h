#ifndef __IO_H
#define __IO_H
void bprintf(const char *fmt, ...);
void handle_input(char *buf, int *result, size_t max_size);
void file_get_contents(bstring buffer, char *filename);
void stdin_get_contents(bstring buffer);
#endif
