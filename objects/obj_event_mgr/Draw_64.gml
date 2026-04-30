// Sprint 3 Phase 2c.event — Draw override.
// D63 §3.13.4: upper 60% 立绘 placeholder, lower 40% subtype indicator + CLAIM.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

// Title
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_PLAYER);
draw_text_transformed(_cx, 90, "EVENT", 1.0, 1.0, 0);

// ===== 立绘 placeholder (280×280 centered top) =====
// D52: 5 sprites pending (spr_event_a_gold / b_card / c_item / d_upgrade_choice / e_upgrade_double)
// Round 7 polish: "dark bg + hands extending with subtype item" motif.
var _portrait_w = 280;
var _portrait_h = 280;
var _portrait_x = _cx - _portrait_w / 2;
var _portrait_y = 140;
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_portrait_x, _portrait_y, _portrait_x + _portrait_w, _portrait_y + _portrait_h, false);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_rectangle(_portrait_x, _portrait_y, _portrait_x + _portrait_w, _portrait_y + _portrait_h, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_DIM);
draw_text_transformed(_cx, _portrait_y + _portrait_h / 2 - 20, "立绘 PLACEHOLDER", 0.4, 0.4, 0);
draw_text_transformed(_cx, _portrait_y + _portrait_h / 2 + 10, "(spr_event_" + string_lower(event_subtype) + "_*)", 0.3, 0.3, 0);

// ===== Subtype label + payload description =====
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_text_transformed(_cx, 460, "SUBTYPE " + event_subtype, 0.65, 0.65, 0);

draw_set_colour(UI_COLOR_SUCCESS);
draw_text_transformed(_cx, 505, event_label, 0.5, 0.5, 0);

// ===== CLAIM button =====
var _btn_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 100, 560, _cx + 100, 610);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 100, 560, _cx + 100, 610, false);
draw_set_colour(_btn_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
draw_rectangle(_cx - 100, 560, _cx + 100, 610, true);
if (_btn_hover) draw_rectangle(_cx - 99, 561, _cx + 99, 609, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_btn_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
draw_text_transformed(_cx, 585, "CLAIM", 0.55, 0.55, 0);

// Hint
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 20, "[SPACE] also advances  |  [ESC] back to map", 0.3, 0.3, 0);

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
