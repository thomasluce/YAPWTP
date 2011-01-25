#ifndef __PARSE_H
#define __PARSE_H

#define KIWI_ACTION(name) void name(int yyleng, char *yytext)
KIWI_ACTION(heading_action_1);
KIWI_ACTION(heading_action_2);
KIWI_ACTION(bullet_list_action_1);
KIWI_ACTION(bullet_action_1);
KIWI_ACTION(definition_list_action_1);
KIWI_ACTION(definition_action_1);
KIWI_ACTION(numbered_list_action_1);
KIWI_ACTION(numbered_action_1);
KIWI_ACTION(nowiki_action_1);
KIWI_ACTION(local_link_action_1);
KIWI_ACTION(image_action_1);
KIWI_ACTION(image_link_action_1);
KIWI_ACTION(image_caption_action_1);
KIWI_ACTION(table_open_action_1);
KIWI_ACTION(table_open_action_2);
KIWI_ACTION(table_caption_action_1);
KIWI_ACTION(table_caption_action_2);
KIWI_ACTION(table_caption_action_3);
KIWI_ACTION(cell_attribute_list_action_1);
KIWI_ACTION(cell_attribute_name_action_1);
KIWI_ACTION(cell_attribute_value_action_1);
KIWI_ACTION(cell_close_action_1);
KIWI_ACTION(sol_cell_open_action_1);
KIWI_ACTION(inline_cell_open_action_1);
KIWI_ACTION(complex_header_action_1);
KIWI_ACTION(complex_header_action_2);
KIWI_ACTION(template_name_action_1);
KIWI_ACTION(template_content_action_1);
KIWI_ACTION(template_close_action_1);
KIWI_ACTION(tag_attribute_name_action_1);
KIWI_ACTION(tag_attribute_value_action_1);
KIWI_ACTION(tag_close_action_1);

#endif
