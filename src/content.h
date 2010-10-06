
#ifndef __CONTENT_H
#define __CONTENT_H
#include "bstrlib.h"
#include <stdbool.h>

// Number of entries on one line of the valid tag lookup table
#define HTML_MAX_TAG_ENTRIES 13
// Longest allowed tag length
#define HTML_MAX_LENGTH 11

void repeat_append(bstring buffer, char chr, int count);
void remove_parentheticals(bstring str);
void strip_tags(bstring str);
void urlencode(bstring b);
void strip_html_markup(bstring str);
bool valid_html_tag(char *html_tag, size_t orig_len);
#endif
