_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_PLAYER);
draw_text_transformed(_cx, 90, "EVENT", 1.0, 1.0, 0);

var _portrait_w = 300;
var _portrait_h = 260;
var _portrait_x = _cx - _portrait_w / 2;
var _portrait_y = 145;
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_portrait_x, _portrait_y, _portrait_x + _portrait_w, _portrait_y + _portrait_h, false);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_rectangle(_portrait_x, _portrait_y, _portrait_x + _portrait_w, _portrait_y + _portrait_h, true);

draw_set_colour(UI_COLOR_HIGHLIGHT);
_draw_effect_icon(encounter_type, _cx - 22, _portrait_y + 80, 44, UI_COLOR_HIGHLIGHT);
draw_set_colour(UI_COLOR_DIM);
draw_text_transformed(_cx, _portrait_y + 155, string_upper(encounter_type), 0.34, 0.34, 0);

draw_set_colour(UI_COLOR_SUCCESS);
draw_text_transformed(_cx, 465, event_label, 0.5, 0.5, 0);

var _btn_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 100, 560, _cx + 100, 610);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 100, 560, _cx + 100, 610, false);
draw_set_colour(_btn_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
draw_rectangle(_cx - 100, 560, _cx + 100, 610, true);
draw_set_colour(_btn_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
draw_text_transformed(_cx, 585, "CLAIM", 0.55, 0.55, 0);

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 20, "[ESC] back to map", 0.3, 0.3, 0);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
