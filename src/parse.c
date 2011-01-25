#include "bstrlib.h"
#include "yapwtp.h"
#include "content.h"
#include "list.h"
#include "io.h"
#include <inttypes.h>
#include "parse.h"

int yyparse(void);

bstring get_input_buffer(void) {
  return input_buffer;
}

bstring get_output_buffer(void) {
  return output_buffer;
}

char *get_output_buffer_cstr(void) {
  return bdata(output_buffer);
}

void set_base_url(char *str) {
  btrunc(base_url, 0);
  bcatcstr(base_url, str);
}

void set_image_base_url(char *str) {
  btrunc(image_base_url, 0);
  bcatcstr(image_base_url, str);
}

int get_template_count(void) {
  return template_list.size;
}

void reset_template_iter() {
  template_list_iter = template_list.head;
}

struct node *get_next_template(void) {
  if(!template_list_iter) {
	template_list_iter = template_list.head;
  }

  if(template_list_iter->next) {
	template_list_iter = template_list_iter->next;
	return template_list_iter;
  }

  return NULL;
}

KIWI_ACTION(heading_action_1) {
  char tag[4];
  bprintf("\n  ");
  sprintf(tag, "h%d", current_header_level);
  open_tag(tag, NULL);
}

KIWI_ACTION(heading_action_2) {
  brtrimws(tag_content);
  bstring tmp = bstrcpy(tag_content);
  strip_html_markup(tmp);
  urlencode(tmp);
  bprintf("<span class=\"editsection\">[<a href=\"edit\">edit</a>]</span><span class=\"mw-headline\" id=\"%s\">", bdata(tmp));
  bdestroy(tmp);
  
  bprintf("%s</span>", bdata(tag_content));
  char tag[4];
  sprintf(tag, "h%d", current_header_level);
  close_tag(tag);
  bprintf("\n");
  
  struct node *current = kw_list_append_new(&toc_list);
  
  tmp = bstrcpy(tag_content);
  strip_html_markup(tmp);
  urlencode(tmp);
  bprintf("  <a name=\"%s\"></a>\n", bdata(tmp));
  bassign(current->name, tmp);
  
  bstring human_name = bstrcpy(tag_content);
  strip_tags(human_name);
  brtrimws(human_name);
  bassign(current->content, human_name);
  current->level = current_header_level;
  
  bdestroy(tmp);
  bdestroy(human_name);
  
  btrunc(tag_content, 0);
  current_header_level = 0;
}

KIWI_ACTION(bullet_list_action_1) {
  while((current_bullet_list_level > 0) && current_bullet_list_level--) {
    bprintf("</ul>");
  }
}

KIWI_ACTION(bullet_action_1) {
  while((current_bullet_list_level < yyleng) && current_bullet_list_level++) {
      bprintf("<ul>");
  }
  while((current_bullet_list_level > yyleng) && current_bullet_list_level--) {
      bprintf("</ul>");
  }
  current_bullet_list_level = yyleng;
  bprintf("<li>");
}

KIWI_ACTION(definition_list_action_1) {
  while((current_definition_list_level > 0) && current_definition_list_level--) {
    bprintf("</dd>");
    bprintf("</dl>");
  }
}

KIWI_ACTION(definition_action_1) {
  while((current_definition_list_level < yyleng) && current_definition_list_level++) {
      bprintf("<dl>");
  }
  while((current_definition_list_level > yyleng) && current_definition_list_level--) {
      bprintf("</dl>");
  }
  current_definition_list_level = yyleng;
  bprintf("<dd>");
}

KIWI_ACTION(numbered_list_action_1) {
  while((current_numbered_list_level > 0) && current_numbered_list_level--) { 
    bprintf("</ol>"); 
  } 
}

KIWI_ACTION(numbered_action_1) {
  while((current_numbered_list_level < yyleng) && current_numbered_list_level++) {
      bprintf("<ol>");
  }
  while((current_numbered_list_level > yyleng) && current_numbered_list_level--) {
      bprintf("</ol>");
  }
  current_numbered_list_level = yyleng;
  bprintf("<li>");
}

KIWI_ACTION(nowiki_action_1) {
  bstring markup = bfromcstr(yytext);
  strip_tags(markup);
  append_to_tag_content("%s", bdata(markup));
  bdestroy(markup);
}

KIWI_ACTION(local_link_action_1) {
  strip_html_markup(link_path);
  urlencode(link_path);
  remove_parentheticals(link_text);
  btrimws(link_text);
  append_to_tag_content("<a href=\"%s/%s\">%s</a>", bdata(base_url), bdata(link_path), bdata(link_text));
  btrunc(link_path, 0);
  btrunc(link_text, 0);
}

KIWI_ACTION(image_action_1) {
  if(image_attributes & IMAGE_FRAME) {
    bprintf("<div class=\"thumb tright\"><div class=\"thumbinner\">");
  }

  if(!(image_attributes & IMAGE_NOLINK)) {
    if(image_attributes & IMAGE_CUSTOMLINK)
      bprintf("<a href=\"%s\" class=\"image\">", bdata(image_link_url));
    else
      if(image_attributes & IMAGE_HAS_CAPTION)
        bprintf("<a href=\"/File:%s\" class=\"image\" title=\"%s\">", bdata(image_url), bdata(image_caption));
      else
        bprintf("<a href=\"/File:%s\" class=\"image\">", bdata(image_url));
  }

  if(image_attributes & IMAGE_THUMB) {
    bprintf("<img src=\"%s%s\" class=\"thumbimage\"/>", bdata(image_base_url), bdata(image_url));
  } else if((image_attributes & IMAGE_FRAME) || (image_attributes & IMAGE_BORDER)) {
    bprintf("<img src=\"%s%s\" class=\"thumbimage\"/>", bdata(image_base_url), bdata(image_url));
  } else {
    bprintf("<img src=\"%s%s\" %s/>", bdata(image_base_url), bdata(image_url), bdata(image_variables));
  }
  if(!(image_attributes & IMAGE_NOLINK)) {
    bprintf("</a>");
  }

  if(image_attributes & IMAGE_FRAME) {
    bprintf("<div class=\"thumbcaption\">%s</div></div>", bdata(image_caption));
  }
}

KIWI_ACTION(image_link_action_1) {
  if(yyleng == 0) {
    image_attributes |= IMAGE_NOLINK;
  } else {
    image_attributes |= IMAGE_CUSTOMLINK;
    bassignformat(image_link_url, "%s", yytext);
  }
}

KIWI_ACTION(image_caption_action_1) {
  image_attributes |= IMAGE_HAS_CAPTION;
  bassignformat(image_caption, "%s", yytext);
}

KIWI_ACTION(table_open_action_1) {
  init_tag_vars();
  bcatcstr(tag_name, "table");
  tr_found = 0; 
  bprintf("<table");
}

KIWI_ACTION(table_open_action_2) {
  // Simpler to check the last output character than to hack up the LEG rules
  if(bdata(output_buffer)[output_buffer->slen - 1] != '>') {
    bprintf(">"); 
  }
}

KIWI_ACTION(table_caption_action_1) {
  init_tag_vars();
  bcatcstr(tag_name, "caption");
  bprintf("<caption"); 
}

KIWI_ACTION(table_caption_action_2) {
  // Simpler to check the last output character than to hack up the LEG rules
  if(bdata(output_buffer)[output_buffer->slen - 1] != '>') {
    bprintf(">"); 
  }
}

KIWI_ACTION(table_caption_action_3) {
  brtrimws(output_buffer); 
  bprintf("</caption>"); 
}

KIWI_ACTION(cell_attribute_list_action_1) {
  kw_list_iterate(tag_attributes_list.head->next, validate_tag_attributes);
  bprintf("%s>", bdata(tag_attributes_validated));
}

KIWI_ACTION(cell_attribute_name_action_1) {
  btrunc(tag_attribute, 0);
  bcatcstr(tag_attribute, yytext);
}

KIWI_ACTION(cell_attribute_value_action_1) {
  struct node *node = kw_list_append_new(&tag_attributes_list);
  bconcat(node->name, tag_attribute);
  bcatcstr(node->content, yytext);
  btrimws(node->name);
  btrimws(node->content);
}

KIWI_ACTION(cell_close_action_1) {
  brtrimws(output_buffer); 
  bprintf("</td>"); 
}

KIWI_ACTION(sol_cell_open_action_1) {
  init_tag_vars(); 
  bcatcstr(tag_name, "td");
  bprintf("<td"); 
}

KIWI_ACTION(inline_cell_open_action_1) {
  init_tag_vars();
  bcatcstr(tag_name, "td");
  bprintf("<td"); 
}

KIWI_ACTION(complex_header_action_1) {
  init_tag_vars(); 
  bcatcstr(tag_name, "th"); 
  bprintf("<th"); 
}

KIWI_ACTION(complex_header_action_2) {
  // Simpler to check the last output character than to hack up the LEG rules
  if(bdata(output_buffer)[output_buffer->slen - 1] != '>') {
    bprintf(">"); 
  }
}

KIWI_ACTION(template_name_action_1) {
  bcatcstr(template_list.tail->name, yytext);
  brtrimws(template_list.tail->name);
}

KIWI_ACTION(template_content_action_1) {
  bcatcstr(template_list.tail->content, yytext);
  template_list.tail->level = hash(yytext);
}

KIWI_ACTION(template_close_action_1) {
  if(template_list.tail->level == 0) {
    // Cover cases where the template has no arguments
    template_list.tail->level = hash("");
  }
  if(PRESERVE_TEMPLATES) {
    // Some bug in leg prevents using braces here or even in this comment
    bprintf("__%s_%"PRIu64"__", bdata(template_list.tail->name), hash(bdata(template_list.tail->content)));
  }
}

KIWI_ACTION(tag_attribute_name_action_1) {
  btrunc(tag_attribute, 0);
  bcatcstr(tag_attribute, yytext);
}

KIWI_ACTION(tag_attribute_value_action_1) {
  struct node *node = kw_list_append_new(&tag_attributes_list);
  bconcat(node->name, tag_attribute);
  bcatcstr(node->content, yytext);
  btrimws(node->name);
  btrimws(node->content);
}

KIWI_ACTION(tag_close_action_1) {
  kw_list_iterate(tag_attributes_list.head->next, validate_tag_attributes);

  btolower(tag_name);
  if(valid_html_tag(bdata(tag_name), tag_name->slen)) {
    bprintf("<%s%s>", bdata(tag_name), bdata(tag_attributes_validated));
  } else {
    strip_tags(tag_name);
    bprintf("&lt;%s&gt;", bdata(tag_name));
  }
}

void parse() {
  bprintf("<p>");
  while(yyparse()) {}
  bprintf("</p>");
  handle_toc();
}

