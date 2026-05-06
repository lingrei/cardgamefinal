_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_text_transformed(_cx, 80, "SHOP", 1.0, 1.0, 0);
draw_text_transformed(_cx, 128, "G: " + string(obj_game.gold), 0.5, 0.5, 0);

draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(240, 170, "TRAITS", 0.42, 0.42, 0);
draw_text_transformed(640, 170, "RELIC", 0.42, 0.42, 0);
draw_text_transformed(980, 170, "HEAL", 0.42, 0.42, 0);

var _hovered_rule_idx = -1;
var _hovered_relic_for_tip = false;

for (var i = 0; i < array_length(shop_rules); i++) {
    var _r = shop_rules[i];
    var _y = 205 + i * 135;
    var _sold = rules_sold[i];
    var _afford = obj_game.gold >= _r.cost;
    var _hover = (!_sold) && point_in_rectangle(mouse_x, mouse_y, 80, _y, 400, _y + 112);
    if (_hover) _hovered_rule_idx = i;

    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(80, _y, 400, _y + 112, false);
    draw_set_colour(_sold ? UI_COLOR_DIM : (_hover ? UI_COLOR_HIGHLIGHT : (_afford ? UI_COLOR_PLAYER : UI_COLOR_WARNING)));
    draw_rectangle(80, _y, 400, _y + 112, true);
    _draw_rule_chip(_r, 105, _y + 22, 24);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(_sold ? UI_COLOR_DIM : c_white);
    draw_text_transformed(140, _y + 14, _t(_rule_display_key(_r.id)), 0.3, 0.3, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    _draw_text_ext_scaled(140, _y + 44, _t(_r.description_text), 18, 210, 0.22);
    draw_set_halign(fa_right);
    draw_set_colour(_afford ? UI_COLOR_HIGHLIGHT : UI_COLOR_WARNING);
    draw_text_transformed(385, _y + 14, string(_r.cost) + "G", 0.42, 0.42, 0);
}

if (!is_undefined(shop_relic)) {
    _draw_relic_card(shop_relic, 490, 250, 300, 150, false);
    var _afford_relic = obj_game.gold >= shop_relic.cost && !relic_sold;
    draw_set_colour(_afford_relic ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
    draw_text_transformed(640, 430, relic_sold ? "SOLD" : string(shop_relic.cost) + "G", 0.45, 0.45, 0);
    if (!relic_sold && point_in_rectangle(mouse_x, mouse_y, 490, 250, 790, 400)) {
        _hovered_relic_for_tip = true;
    }
}

var _hp_full = obj_game.player_hp >= obj_game.player_max_hp;
var _can_heal = !_hp_full && obj_game.gold >= 1;
var _heal_hover = _can_heal && point_in_rectangle(mouse_x, mouse_y, 880, 250, 1080, 340);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(880, 250, 1080, 340, false);
draw_set_colour(_heal_hover ? UI_COLOR_HIGHLIGHT : (_can_heal ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_rectangle(880, 250, 1080, 340, true);
draw_set_colour(_can_heal ? UI_COLOR_SUCCESS : UI_COLOR_DIM);
draw_text_transformed(980, 285, "+1 HP", 0.55, 0.55, 0);
draw_set_colour(_can_heal ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(980, 320, "1G", 0.4, 0.4, 0);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(980, 385, "HP: " + string(obj_game.player_hp) + "/" + string(obj_game.player_max_hp), 0.36, 0.36, 0);

var _leave_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 100, 640, _cx + 100, 680);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 100, 640, _cx + 100, 680, false);
draw_set_colour(_leave_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_cx - 100, 640, _cx + 100, 680, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_leave_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_cx, 660, "LEAVE SHOP", 0.42, 0.42, 0);

if (_hovered_rule_idx >= 0) {
    _draw_rule_hover_tooltip(shop_rules[_hovered_rule_idx], mouse_x + 18, mouse_y + 18);
} else if (_hovered_relic_for_tip) {
    _draw_relic_hover_tooltip(shop_relic, mouse_x + 18, mouse_y + 18);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
