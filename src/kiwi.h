#ifndef __COMMON_H
#define __COMON_H
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <stdarg.h>
#include <stdbool.h>
#include <ctype.h>
#include "bstrlib.h"
#include "list.h"

#define KBYTE 1024
#define MBYTE KBYTE * 1024

#define PRESERVE_TEMPLATES 1

#define IMAGE_FRAME 1
#define IMAGE_THUMB ( 1 << 1 )
#define IMAGE_NOLINK ( 1 << 2 )
#define IMAGE_CUSTOMLINK ( 1 << 3 )
#define IMAGE_HAS_CAPTION ( 1 << 4 )
#define IMAGE_BORDER ( 1 << 5 )

#define TOC_NOTOC ( 1 << 1 )
#define TOC_FORCETOC ( 1 << 2 )
#define TOC_RELOC ( 1 << 3 )

int current_header_level;
int current_bullet_list_level;
int current_numbered_list_level;
int current_definition_list_level;

int start_of_line;
char protocol[5];

// Images
int image_attributes;
bstring image_url;
bstring image_variables;
bstring image_link_url;
bstring image_caption;

// Links
bstring link_path;
bstring link_text;

// HTML tags
bstring tag_name;
bstring tag_attribute;
bstring tag_attributes_validated;
struct list tag_attributes_list;

// Tables
int tr_found;

// ToC
int toc_attributes;
struct list toc_list;

// Wikitext
int in_tag;
bstring tag_content;
unsigned int tag_content_size;

// Templates
struct list template_list;
struct node *template_list_iter;
int template_noinclude;

// General
bstring output_buffer;
bstring input_buffer;
long input_buffer_pos;
bstring base_url;
bstring image_base_url;

void init(void);
void cleanup(void);
void parse(void);
void handle_toc(void);
bstring get_output_buffer();
char *get_output_buffer_cstr(void);
bstring get_input_buffer();
void set_base_url(char *str);
void set_image_base_url(char *str);
#endif
