// Sprint 3 Phase 2c.rest — Draw override.
// Bypasses event_inherited (avoids base placeholder title/hint); calls shared BG+status helper + own UI.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

// ===== Title (SUCCESS green for healing vibe) =====
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_SUCCESS);
draw_text_transformed(_cx, 120, "REST", 1.2, 1.2, 0);

// HP reminder
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, 180, "Current HP: " + string(obj_game.player_hp) + " / " + string(obj_game.player_max_hp), 0.4, 0.4, 0);

// ===== 2 big choice buttons =====
var _btn_w = 200;
var _btn_h = 160;
var _btn_y = 260;
var _heal_x = _cx - 240;
var _upg_x  = _cx + 40;

// --- HEAL card (Phase 2e.5: DIM + "HP FULL" when at max) ---
var _hp_full = obj_game.player_hp >= obj_game.player_max_hp;
var _heal_hover = !_hp_full && point_in_rectangle(mouse_x, mouse_y, _heal_x, _btn_y, _heal_x + _btn_w, _btn_y + _btn_h);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_heal_x, _btn_y, _heal_x + _btn_w, _btn_y + _btn_h, false);
draw_set_colour(_hp_full ? UI_COLOR_DIM : (_heal_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS));
draw_rectangle(_heal_x, _btn_y, _heal_x + _btn_w, _btn_y + _btn_h, true);
if (_heal_hover) draw_rectangle(_heal_x + 1, _btn_y + 1, _heal_x + _btn_w - 1, _btn_y + _btn_h - 1, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_hp_full ? UI_COLOR_DIM : UI_COLOR_SUCCESS);
draw_text_transformed(_heal_x + _btn_w / 2, _btn_y + 50, "HEAL", 0.7, 0.7, 0);
draw_set_colour(_hp_full ? UI_COLOR_DIM : UI_COLOR_NEUTRAL);
draw_text_transformed(_heal_x + _btn_w / 2, _btn_y + 110, _hp_full ? "(HP FULL)" : "+ 2 HP", 0.55, 0.55, 0);

// --- UPGRADE card ---
var _upg_hover = point_in_rectangle(mouse_x, mouse_y, _upg_x, _btn_y, _upg_x + _btn_w, _btn_y + _btn_h);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_upg_x, _btn_y, _upg_x + _btn_w, _btn_y + _btn_h, false);
draw_set_colour(_upg_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_PLAYER);
draw_rectangle(_upg_x, _btn_y, _upg_x + _btn_w, _btn_y + _btn_h, true);
if (_upg_hover) draw_rectangle(_upg_x + 1, _btn_y + 1, _upg_x + _btn_w - 1, _btn_y + _btn_h - 1, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_PLAYER);
draw_text_transformed(_upg_x + _btn_w / 2, _btn_y + 50, "UPGRADE", 0.6, 0.6, 0);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_upg_x + _btn_w / 2, _btn_y + 100, "3 Rules → Pick 1", 0.4, 0.4, 0);
draw_text_transformed(_upg_x + _btn_w / 2, _btn_y + 130, "Apply to a card", 0.35, 0.35, 0);

// ===== LEAVE button (secondary) =====
var _leave_x = _cx - 75;
var _leave_y = 560;
var _leave_hover = point_in_rectangle(mouse_x, mouse_y, _leave_x, _leave_y, _leave_x + 150, _leave_y + 40);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_leave_x, _leave_y, _leave_x + 150, _leave_y + 40, false);
draw_set_colour(_leave_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_leave_x, _leave_y, _leave_x + 150, _leave_y + 40, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_leave_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_leave_x + 75, _leave_y + 20, "LEAVE", 0.4, 0.4, 0);

// ESC / SPACE hint
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 20, "[ESC] Back to Map  |  [SPACE] Skip", 0.3, 0.3, 0);

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
