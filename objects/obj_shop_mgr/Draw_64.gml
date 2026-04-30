// Sprint 3 Phase 2c.shop — Draw override.
// 3-col layout (D49 §O.6): Rules (left) / Items (middle) / Heal (right) + LEAVE.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

// Title
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_text_transformed(_cx, 90, "SHOP", 1.1, 1.1, 0);

// Gold reminder (right of title)
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_text_transformed(_cx, 140, "G: " + string(obj_game.gold), 0.55, 0.55, 0);

// Col headers
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(230,  175, "— RULES —", 0.42, 0.42, 0);
draw_text_transformed(585,  175, "— ITEMS —", 0.42, 0.42, 0);
draw_text_transformed(900,  175, "— HEAL —",  0.42, 0.42, 0);

// ===== 3 rule slots (left col) =====
for (var i = 0; i < array_length(shop_rules); i++) {
    var _r = shop_rules[i];
    var _y = 200 + i * 150;
    var _sold = rules_sold[i];
    var _afford = obj_game.gold >= _r.cost;
    var _hover = (!_sold) && point_in_rectangle(mouse_x, mouse_y, 80, _y, 380, _y + 130);

    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(80, _y, 380, _y + 130, false);
    var _border_col = _sold ? UI_COLOR_DIM : (_hover ? UI_COLOR_HIGHLIGHT : (_afford ? UI_COLOR_PLAYER : UI_COLOR_WARNING));
    draw_set_colour(_border_col);
    draw_rectangle(80, _y, 380, _y + 130, true);
    if (_hover) draw_rectangle(81, _y + 1, 379, _y + 129, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(_sold ? UI_COLOR_DIM : c_white);
    draw_text_transformed(95, _y + 12, _sold ? "(SOLD)" : _r.id, 0.35, 0.35, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(95, _y + 45, _t(_r.description_text), 0.25, 0.25, 0);

    // Cost badge (top right)
    draw_set_halign(fa_right);
    draw_set_colour(_sold ? UI_COLOR_DIM : (_afford ? UI_COLOR_HIGHLIGHT : UI_COLOR_WARNING));
    draw_text_transformed(370, _y + 12, string(_r.cost) + "G", 0.5, 0.5, 0);
}

// ===== 2 item slots (middle col) =====
for (var i = 0; i < array_length(shop_items); i++) {
    var _it = shop_items[i];
    var _y = 250 + i * 180;
    var _afford = obj_game.gold >= _it.cost;
    var _hasroom = array_length(obj_game.items) < 4;
    var _avail = _afford && _hasroom;
    var _hover = _avail && point_in_rectangle(mouse_x, mouse_y, 450, _y, 720, _y + 160);

    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(450, _y, 720, _y + 160, false);
    draw_set_colour(_hover ? UI_COLOR_HIGHLIGHT : (_avail ? UI_COLOR_PLAYER : UI_COLOR_DIM));
    draw_rectangle(450, _y, 720, _y + 160, true);
    if (_hover) draw_rectangle(451, _y + 1, 719, _y + 159, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_text_transformed(465, _y + 15, _it.id, 0.35, 0.35, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(465, _y + 50, _t(_it.description_text), 0.25, 0.25, 0);

    draw_set_halign(fa_right);
    draw_set_colour(_afford ? UI_COLOR_HIGHLIGHT : UI_COLOR_WARNING);
    draw_text_transformed(710, _y + 15, string(_it.cost) + "G", 0.5, 0.5, 0);
}

// ===== Heal slot (right col) =====
var _hp_full = obj_game.player_hp >= obj_game.player_max_hp;
var _can_heal = !_hp_full && obj_game.gold >= 1;
var _heal_hover = _can_heal && point_in_rectangle(mouse_x, mouse_y, 800, 280, 1000, 360);

draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(800, 280, 1000, 360, false);
draw_set_colour(_heal_hover ? UI_COLOR_HIGHLIGHT : (_can_heal ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_rectangle(800, 280, 1000, 360, true);
if (_heal_hover) draw_rectangle(801, 281, 999, 359, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_can_heal ? UI_COLOR_SUCCESS : UI_COLOR_DIM);
draw_text_transformed(900, 310, "+ 1 HP", 0.6, 0.6, 0);
draw_set_colour(_can_heal ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(900, 340, "1 GOLD", 0.4, 0.4, 0);

// HP display below
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(900, 400, "HP: " + string(obj_game.player_hp) + "/" + string(obj_game.player_max_hp), 0.4, 0.4, 0);
if (_hp_full) {
    draw_set_colour(UI_COLOR_DIM);
    draw_text_transformed(900, 430, "(already max)", 0.3, 0.3, 0);
}

// ===== LEAVE SHOP =====
var _leave_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 100, 640, _cx + 100, 680);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 100, 640, _cx + 100, 680, false);
draw_set_colour(_leave_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_cx - 100, 640, _cx + 100, 680, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_leave_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_cx, 660, "LEAVE SHOP", 0.45, 0.45, 0);

// Hint
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 10, "[ESC] Back to Map  |  [SPACE] Skip", 0.28, 0.28, 0);

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
