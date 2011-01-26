#include "bstrlib.h"
#include "stdbool.h"
#include "list.h"
#include "content.h"
#include "kiwi.h"
#include "io.h"
#include <stdio.h>

// Render the ToC from a list, output to buffer
void assemble_toc(struct node *item, bstring toc_buffer) {
  if(!item) {
    printf("Bad list passed to assemble_toc\n");
    return;
  }

  struct node *next;
  int previous_level = item->level;
  int total_layers = 0;
  int i;
  bformata(toc_buffer, "%s", "<div id=\"toc\" class=\"toc\">\n<div id=\"toctitle\">Contents</div>\n<ol>\n");
  while(item != NULL) {
    next = item->next;

    // Layer the list deeper as necessary
    if(item->level > previous_level) {
      repeat_append(toc_buffer, ' ', (total_layers + 1) * 2);
      for(i = previous_level; i < item->level; i++) {
        bformata(toc_buffer, "%s", "<ol>\n");
        total_layers++;
      }
    } else if(item->level < previous_level) {
      for(i = previous_level; i > item->level; i--) {
        repeat_append(toc_buffer, ' ', (total_layers) * 2);
        bformata(toc_buffer, "%s", "</ol></li>\n");
        total_layers--;
      }
    }

    // Add the item
    if(item->name && item->content) {
      repeat_append(toc_buffer, ' ', (total_layers + 1) * 2);
      bformata(toc_buffer, "  <li><a href=\"#%s\">%s</a>", bdata(item->name), bdata(item->content));
      if(next && next->level > item->level) {
        bcatcstr(toc_buffer, "\n");
      } else {
        bcatcstr(toc_buffer, "</li>\n");
      }
    }
    previous_level = item->level;
    item = next;
  }

  // Clean up lists left open
  while(total_layers > 0) {
    bformata(toc_buffer, "%s", "</ol>\n");
    total_layers--;
  }
  bformata(toc_buffer, "%s", "</ol>\n</div>\n");
}

// Insert the ToC into the output buffer in place of the __TOC__ tag
void insert_reloc_toc(bstring toc_buffer) {
  bstring find = bfromcstr("__TOC__");
  if(bfindreplace(output_buffer, find, toc_buffer, 0) == BSTR_ERR) {
    printf("Error inserting toc_buffer into output_buffer\n");
  }
  bdestroy(find);
}

// Main ToC routine
void handle_toc(void) {
  if(toc_attributes & TOC_NOTOC) {
    return;
  }

  if((toc_list.size > 3) || (toc_attributes & TOC_FORCETOC)) {
    bstring toc_buffer = bfromcstr("");
    assemble_toc(toc_list.head->next, toc_buffer);

    if(toc_attributes & TOC_RELOC) {
      insert_reloc_toc(toc_buffer);
      bdestroy(toc_buffer);
      return;
    }

    if(binsert(output_buffer, 0, toc_buffer, ' ') != BSTR_OK) {
      printf("Error prepending toc_buffer to output_buffer\n");
    }
    bdestroy(toc_buffer);
  }
}

void open_tag(char *tag, char *args) {
  if(args) {
    bprintf("<%s %s>", tag, args);
  } else {
    bprintf("<%s>", tag);
  }

  in_tag = 1;
  if(tag_content) {
    btrunc(tag_content,0 );
  }
}

void close_tag(char *tag) {
  bprintf("</%s>", tag);
  in_tag = 0;
}

void append_to_tag_content(char *fmt, ...) {
  int ret;

  if(!in_tag) {
    bvformata(ret, output_buffer, fmt, fmt);
    return;
  }

  bvformata(ret, tag_content, fmt, fmt);
}

// Initialize variables used in html tag processing
void init_tag_vars(void) {
  btrunc(tag_name, 0);
  btrunc(tag_attribute, 0);
  btrunc(tag_attributes_validated, 0);
  if(tag_attributes_list.size > 0) {
    kw_list_free(&tag_attributes_list);
    kw_list_init(&tag_attributes_list);
  }
}

// Append a character to a buffer a repeat number of times
void repeat_append(bstring buffer, char chr, int count) {
  binsertch(buffer, blength(buffer), count + 1, chr);
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
uint64_t hash(char *str) {
  uint64_t hash = 5381;

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
  bool self_closing;     // Is the tag an inherently self-closing tag?
};

// This data structure is a pre-hashed table of allowed HTML tags
// and each tag's corresponding allowed attributes.  These are also used for
// validating attributes on wikitext equivalents of some of these tags
// (e.g. tables).  The hashing algorithm is Dan Bernstein's % 512.
static const struct hashed_tag tags_hash[512] = {
  [7]   { "b",          { "id", "name" }, 2, false },
  [14]  { "i",          { "id", "name" }, 2, false },
  [21]  { "p",          { "id", "name" }, 2, false },
  [24]  { "s",          { "id", "name" }, 2, false },
  [31]  { "hr",         { "id", "name" }, 2, true },
  [47]  { "ins",        { "id", "name" }, 2, false },
  [60]  { "abbr",       { "id", "name" }, 2, false },
  [72]  { "div",        { "id", "name" }, 2, true },
  [94]  { "small",      { "id", "name" }, 2, false },
  [108] { "pre",        { "id", "name" }, 2, false },
  [119] { "span",       { "id", "name" }, 2, true },
  [128] { "code",       { "id", "name" }, 2, false },
  [134] { "center",     { "id", "name" }, 2, false },
  [141] { "table",      { "id", "name", "cellspacing", "cellpadding", "border", "style", "width" }, 7, false },
  [154] { "li",         { "id", "name" }, 2, false },
  [158] { "blockquote", { "id", "name" }, 2, false },
  [211] { "caption",    { "id", "name", "align", "style" }, 4, false },
  [252] { "font",       { "id", "name" }, 2, false },
  [256] { "ol",         { "id", "name" }, 2, false },
  [266] { "cite",       { "id", "name" }, 2, false },
  [345] { "br",         { "id", "name" }, 2, true },
  [386] { "strong",     { "id", "name" }, 2, false },
  [397] { "dd",         { "id", "name" }, 2, false },
  [399] { "sub",        { "id", "name" }, 2, false },
  [405] { "dl",         { "id", "name" }, 2, false },
  [407] { "strike",     { "id", "name" }, 2, false },
  [413] { "dt",         { "id", "name" }, 2, false },
  [413] { "sup",        { "id", "name" }, 2, false },
  [413] { "td",         { "id", "name", "align", "colspan", "style", "width" }, 6, false },
  [417] { "th",         { "id", "name", "align", "colspan", "scope", "style", "width" }, 7, false },
  [427] { "tr",         { "id", "name", "border", "style" }, 4, false },
  [429] { "tt",         { "id", "name" }, 2, false },
  [439] { "big",        { "id", "name" }, 2, false },
  [439] { "em",         { "id", "name" }, 2, false },
  [442] { "del",        { "id", "name" }, 2, false },
  [454] { "ul",         { "id", "name" }, 2, false },
  [478] { "h1",         { "id", "name", "style" }, 3, false },
  [479] { "h2",         { "id", "name", "style" }, 3, false },
  [480] { "h3",         { "id", "name", "style" }, 3, false },
  [481] { "h4",         { "id", "name", "style" }, 3, false },
  [482] { "h5",         { "id", "name", "style" }, 3, false },
  [483] { "h6",         { "id", "name", "style" }, 3, false }
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

bool tag_self_closing(char *tag) {
  int hashed_key = hash(tag) % 512;
  int len = strlen(tag);

  return tags_hash[hashed_key].key && 
    !strncmp(tag, tags_hash[hashed_key].key, len) && 
    tags_hash[hashed_key].self_closing;

}

// Validate whether a particular attribute is allowed on a tag. 
int validate_tag_attributes(struct node *item) {
  if((item == NULL) || (item->name == NULL) || (item->content == NULL)) {
    return 1;
  }

  btolower(item->name);
  int hashed_key = hash(bdata(tag_name)) % 512;

  if(!tags_hash[hashed_key].key || (tags_hash[hashed_key].size < 1)) {
    return 1;
  }

  //printf("--%s--%s: %s--\n", bdata(tag_name), bdata(item->name), bdata(item->content));

  // The purpose of this is just to make GCC shut up about non-null arguments to strcmp
  char *item_name = NULL;
  if(item && item->name) item_name = bdata(item->name);

  int i;
  for(i = 0; i < tags_hash[hashed_key].size; i++) {
    // Do an integer compare on the first character first, then match the whole tag
    if(tags_hash[hashed_key].attributes[i][0] == bdata(item->name)[0]) { 
      if(item_name && !strncmp(item_name, tags_hash[hashed_key].attributes[i], item->name->slen)) {
        bformata(tag_attributes_validated, " %s=\"%s\"", item_name, bdata(item->content));
        return 1;
      }
    }
  }

  return 1;
}

bool close_needed_tags() {
  bstring last_tag = (bstring)peek(&tag_stack, 0);
  if(!last_tag || bstrcmp(last_tag, tag_name) != 0) {
    //Walk down stack
    bstring this_tag;
    while((this_tag = (bstring)pop(&tag_stack)) != NULL) {
      bstring tmp = bmidstr(tag_name, 1, blength(tag_name));
      if(bstrcmp(this_tag, tmp) == 0) {
        bdestroy(tmp);
        break;
      } else {
        bprintf("</%s>", bdata(this_tag));
        bdestroy(this_tag);
      }
      bdestroy(tmp);
    }
    if(tag_name && blength(tag_name) != 0) bprintf("<%s>", bdata(tag_name)); 
    return true;
  }
  return false;
}
