_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_text_transformed(_cx, 90, "VICTORY", 0.85, 0.85, 0);

draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, 145, "REWARDS", 0.45, 0.45, 0);

var _line_y = 200;
var _claim_enabled = true;
var _hovered_relic_idx = -1;

if (!is_undefined(reward_stage)) {
    var _r = reward_stage.rewards;

    if (_r.gold > 0) {
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_cx, _line_y, "+ " + string(_r.gold) + " Gold", 0.55, 0.55, 0);
        _line_y += 44;
    }
    if (_r.card_count > 0) {
        draw_set_colour(UI_COLOR_SUCCESS);
        draw_text_transformed(_cx, _line_y, "+ " + string(_r.card_count) + " Card", 0.55, 0.55, 0);
        _line_y += 44;
    }
    if (_r.upgrade_count > 0) {
        draw_set_colour(UI_COLOR_PLAYER);
        draw_text_transformed(_cx, _line_y, string(_r.upgrade_count) + " Upgrade", 0.55, 0.55, 0);
        _line_y += 44;
    }
    if (_r.relic_choice_count > 0) {
        _claim_enabled = (selected_relic_idx >= 0);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_cx, _line_y, "Choose 1 Relic", 0.55, 0.55, 0);
        var _start_x = _cx - 465;
        for (var ri = 0; ri < array_length(relic_candidates); ri++) {
            var _rx = _start_x + ri * 330;
            var _ry = _line_y + 34;
            _draw_relic_card(relic_candidates[ri], _rx, _ry, 300, 128, selected_relic_idx == ri);
            if (point_in_rectangle(mouse_x, mouse_y, _rx, _ry, _rx + 300, _ry + 128)) {
                _hovered_relic_idx = ri;
            }
        }
        _line_y += 178;
    }

    if (_line_y == 200) {
        draw_set_colour(UI_COLOR_DIM);
        draw_text_transformed(_cx, 260, "(no rewards this stage)", 0.4, 0.4, 0);
    }
} else {
    draw_set_colour(UI_COLOR_WARNING);
    draw_text_transformed(_cx, 260, "(stage lookup failed)", 0.4, 0.4, 0);
}

var _claim_x = _cx - 100;
var _claim_y = 545;
var _claim_hover = _claim_enabled && point_in_rectangle(mouse_x, mouse_y, _claim_x, _claim_y, _claim_x + 200, _claim_y + 50);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_claim_x, _claim_y, _claim_x + 200, _claim_y + 50, false);
draw_set_colour(_claim_hover ? UI_COLOR_HIGHLIGHT : (_claim_enabled ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_rectangle(_claim_x, _claim_y, _claim_x + 200, _claim_y + 50, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_claim_hover ? UI_COLOR_HIGHLIGHT : (_claim_enabled ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_text_transformed(_cx, _claim_y + 25, "CLAIM", 0.55, 0.55, 0);

var _skip_x = _cx - 75;
var _skip_y = 615;
var _skip_hover = point_in_rectangle(mouse_x, mouse_y, _skip_x, _skip_y, _skip_x + 150, _skip_y + 40);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_skip_x, _skip_y, _skip_x + 150, _skip_y + 40, false);
draw_set_colour(_skip_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_skip_x, _skip_y, _skip_x + 150, _skip_y + 40, true);
draw_set_colour(_skip_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_skip_x + 75, _skip_y + 20, "SKIP (+1G)", 0.38, 0.38, 0);

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 20, "[SPACE] advances only when no relic choice is pending", 0.25, 0.25, 0);

if (_hovered_relic_idx >= 0) {
    _draw_relic_hover_tooltip(relic_candidates[_hovered_relic_idx], mouse_x + 18, mouse_y + 18);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
