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

// Dan Bernstein's djb2 hash function
unsigned long hash(char *str) {
  unsigned long hash = 5381;

  while(*str!='\0') {
    int c = *str;
    /* hash = hash*33 + c */
    hash = ((hash << 5) + hash) + c;
    str++;
  }
  return hash;
}

// The value structure used in the below hash table
struct hashed_tag {
  char *key;             // The hash key
  char *attributes[10];  // An array of allowed attributes
  int size;              // The number of allowed attributes for this key
};

// This data structure is a pre-hashed table of allowed HTML tags
// and each tag's corresponding allowed attributes.  These are also used for
// validating attributes on wikitext equivalents of some of these tags
// (e.g. tables).  The hashing algorithm is Dan Bernstein's % 512.
static const struct hashed_tag tags_hash[455] = {
  [7]   { "b",          { "id", "name" }, 2 },
  [14]  { "i",          { "id", "name" }, 2 },
  [21]  { "p",          { "id", "name" }, 2 },
  [24]  { "s",          { "id", "name" }, 2 },
  [31]  { "hr",         { "id", "name" }, 2 },
  [47]  { "ins",        { "id", "name" }, 2 },
  [60]  { "abbr",       { "id", "name" }, 2 },
  [72]  { "div",        { "id", "name" }, 2 },
  [94]  { "small",      { "id", "name" }, 2 },
  [108] { "pre",        { "id", "name" }, 2 },
  [119] { "span",       { "id", "name" }, 2 },
  [128] { "code",       { "id", "name" }, 2 },
  [134] { "center",     { "id", "name" }, 2 },
  [141] { "table",      { "id", "name", "cellpadding", "border", "style", "width" }, 6 },
  [154] { "li",         { "id", "name" }, 2 },
  [158] { "blockquote", { "id", "name" }, 2 },
  [211] { "caption",    { "id", "name" }, 2 },
  [252] { "font",       { "id", "name" }, 2 },
  [256] { "ol",         { "id", "name" }, 2 },
  [266] { "cite",       { "id", "name" }, 2 },
  [345] { "br",         { "id", "name" }, 2 },
  [386] { "strong",     { "id", "name" }, 2 },
  [397] { "dd",         { "id", "name" }, 2 },
  [399] { "sub",        { "id", "name" }, 2 },
  [405] { "dl",         { "id", "name" }, 2 },
  [407] { "strike",     { "id", "name" }, 2 },
  [413] { "dt",         { "id", "name" }, 2 },
  [413] { "sup",        { "id", "name" }, 2 },
  [413] { "td",         { "id", "name", "align", "style", "width" }, 5 },
  [417] { "th",         { "id", "name", "align", "colspan", "style", "width" }, 6 },
  [427] { "tr",         { "id", "name", "border", "style" }, 4 },
  [429] { "tt",         { "id", "name" }, 2 },
  [439] { "big",        { "id", "name" }, 2 },
  [439] { "em",         { "id", "name" }, 2 },
  [442] { "del",        { "id", "name" }, 2 },
  [454] { "ul",         { "id", "name" }, 2 },
};

// Validate whether or not a specific HTML tag is allowed.
// Only compares lower case, so process the text first as needed.
bool valid_html_tag(char *html_tag, size_t orig_len) {

  char *tag = html_tag;
  int len = orig_len;

  if((tag[0] == '/') && (len > 1)) {
    tag++;
    len--;
  }

  if(len == 0) {
    return false;
  }

  int hashed_key = hash(tag) % 512;
  if(tags_hash[hashed_key].key && !strncmp(tag, tags_hash[hashed_key].key, len)) {
    return true;
  } 

  return false;
}

// Validate whether a particular attribute is allowed on a tag.  Naive implementation.
int validate_tag_attributes(struct node *item) {
  if((item == NULL) || (item->name == NULL) || (item->content == NULL)) {
    return 1;
  }

  btolower(item->name);
  int hashed_key = hash(bdata(tag_name)) % 512;

  if(!tags_hash[hashed_key].key || (tags_hash[hashed_key].size < 1)) {
    return 1;
  }

  //printf("--%s: %s--\n", bdata(item->name), bdata(item->content));

  int i;
  for(i = 0; i < tags_hash[hashed_key].size; i++) {
    // Do an integer compare on the first character first, then match the whole tag
    if(tags_hash[hashed_key].attributes[i][0] == bdata(item->name)[0]) { 
      if(!strncasecmp(bdata(item->name), tags_hash[hashed_key].attributes[i], item->name->slen)) {
        bformata(tag_attributes_validated, " %s=\"%s\"", bdata(item->name), bdata(item->content));
        return 1;
      }
    }
  }

  return 1;
}
