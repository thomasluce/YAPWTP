#include "bstrlib.h"
#include "stdbool.h"
#include "list.h"
#include "content.h"

extern bstring tag_attributes_validated;

// Append a character to a buffer a repeat number of times
void repeat_append(bstring buffer, char chr, int count) {
  int i;
  bstring tmp = bfromcstr("");
  balloc(tmp, count);
  for(i = 0; i <= count; i++) {
      tmp->data[i] = chr;
    tmp->slen++;
  }
  bconcat(buffer, tmp);
  bdestroy(tmp);
}

void remove_parentheticals(bstring str) {
  bstring temp = bstrcpy(str);

  int i, index = 0;
  int in_tag = 0;
  for(i = 0; i < blength(str); i++) {
    if((bdata(str))[i] == '(') {
      in_tag++;
      continue;
    } else if((bdata(str))[i] == ')') {
      in_tag--;
      continue;
    }
    if(in_tag < 1) temp->data[index++] = (bdata(str))[i];
  }
  temp->slen = index;
  bassign(str, temp);
  bdestroy(temp);
}

void strip_tags(bstring str) {
  bstring temp = bstrcpy(str);

  int i, index = 0;
  int in_tag = 0;
  for(i = 0; i < blength(str); i++) {
    if((bdata(str))[i] == '<') {
      in_tag++;
      continue;
    } else if((bdata(str))[i] == '>') {
      in_tag--;
      continue;
    }
    if(in_tag < 1) temp->data[index++] = (bdata(str))[i];
  }
  temp->slen = index;
  bassign(str, temp);
  bdestroy(temp);
}

void urlencode(bstring b) {
  char *p;
  int c, e;
  bstring target = bfromcstr("");

  static const int whitelist[] = {
    /* reserved characters */
    [36] '$',
    [38] '&',
    [43] '+',
    [44] ',',
    [46] '.',
    [47] '/',
    [58] ':',
    [59] ';',
    [61] '=',
    [63] '?',
    [64] '@',
    [95] '_'
  };

  p = bdata(b);
  while ((c = *p++)) { // Double parens to make gcc shut up
    /* [0-9A-Za-z] */
    if (('0' <= c && c <= '9') ||
        ('A' <= c && c <= 'Z') ||
        ('a' <= c && c <= 'z')) {
      bformata(target, "%c", c);
      continue;
    }
    e = whitelist[c];
    if (e) {
      bformata(target, "%c", c);
      continue;
    }
    bformata(target, "%%%02x", c);
  }
  bassign(b, target);
  bdestroy(target);
}

void strip_html_markup(bstring str) {
  strip_tags(str);
  brtrimws(str);
  bstring find = bfromcstr(" ");
  bstring replace = bfromcstr("_");
  bfindreplace(str, find, replace, 0);
  bdestroy(find);
  bdestroy(replace);
}

// Validate whether or not a specific HTML tag is allowed.
bool valid_html_tag(char *html_tag, size_t orig_len) {

  // Lookup table based on tag length
  static const char valid_tags[HTML_MAX_LENGTH][HTML_MAX_TAG_ENTRIES][10] = {
    [1]  { "b", "i", "p", "s" },
    [2]  { "br", "dd", "dl", "dt", "em", "hr", "li", "ol", "td", "th", "tr", "tt", "ul" },
    [3]  { "big", "del", "div", "ins", "pre", "sub", "sup" },
    [4]  { "abbr", "cite", "code", "font", "span" },
    [5]  { "small", "table" }, 
    [6]  { "strong", "strike", "center" },
    [7]  { "caption" },
    [10] { "blockquote" }
  };

  char *tag = html_tag;
  int len = orig_len;

  if((tag[0] == '/') && (len > 1)) {
    tag++;
    len--;
  }

  if(len == 0) {
    return false;
  }

  // If there are no allowed tags this length
  if(!valid_tags[len]) {
    return false;
  }

  int i;
  char c = tolower(tag[0]);
  for(i = 0; i < HTML_MAX_TAG_ENTRIES; i++) {
    if(tolower(valid_tags[len][i][0]) == c) { // Integer comparison on first character
      if(!strncasecmp(tag, valid_tags[len][i], len)) {
        return true;
      }
    }
  }

  return false;
}

// Validate whether a particular attribute is allowed on a tag.  Naive implementation.
int validate_tag_attributes(struct node *item) {
  if((item == NULL) || (item->name == NULL) || (item->content == NULL)) {
    return 0;
  }

  btolower(item->name);
  bstring name = bfromcstr("name");
  bstring id = bfromcstr("id");
  if((!bstrcmp(item->name, name)) || (!bstrcmp(item->name, id))) {
    bformata(tag_attributes_validated, " %s=\"%s\"", bdata(item->name), bdata(item->content));
  }
  bdestroy(name);
  bdestroy(id);

  //printf("%s: %s\n", bdata(item->name), bdata(item->content));
  return 1;
}
