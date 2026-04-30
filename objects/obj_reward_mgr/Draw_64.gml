// Sprint 3 Phase 2c.reward — Draw override.
// Reward stack displays stage.rewards fields dynamically + CLAIM / SKIP buttons.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

// ===== Title: BATTLE X/6 VICTORY =====
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_text_transformed(_cx, 110, "BATTLE " + string(obj_game.current_battle_index + 1) + "/6  VICTORY", 0.9, 0.9, 0);

// ===== Reward stack (dynamic by stage.rewards fields) =====
draw_set_colour(UI_COLOR_NEUTRAL);
draw_set_halign(fa_center);
draw_text_transformed(_cx, 180, "— REWARDS —", 0.45, 0.45, 0);

var _line_y = 240;
var _line_h = 50;

if (!is_undefined(reward_stage)) {
    var _r = reward_stage.rewards;

    if (_r.gold > 0) {
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_cx, _line_y, "+ " + string(_r.gold) + " Gold", 0.6, 0.6, 0);
        _line_y += _line_h;
    }
    if (_r.item_count > 0) {
        draw_set_colour(UI_COLOR_PLAYER);
        var _item_label = (_r.item_source == "starter_pack_peek") ? "Peek Item" : "Item";
        draw_text_transformed(_cx, _line_y, "+ " + string(_r.item_count) + " " + _item_label + "(s)", 0.6, 0.6, 0);
        _line_y += _line_h;
    }
    if (_r.card_count > 0) {
        draw_set_colour(UI_COLOR_SUCCESS);
        draw_text_transformed(_cx, _line_y, "+ " + string(_r.card_count) + " Card  (" + _r.card_algorithm + ")", 0.55, 0.55, 0);
        draw_set_colour(UI_COLOR_DIM);
        draw_text_transformed(_cx, _line_y + 24, "(Phase 2c.card — algorithm TODO)", 0.3, 0.3, 0);
        _line_y += _line_h + 10;
    }
    if (_r.upgrade_count > 0) {
        draw_set_colour(UI_COLOR_OPP);
        draw_text_transformed(_cx, _line_y, string(_r.upgrade_count) + " × Upgrade", 0.55, 0.55, 0);
        draw_set_colour(UI_COLOR_DIM);
        draw_text_transformed(_cx, _line_y + 24, "(Phase 2d — Unified Upgrade UI)", 0.3, 0.3, 0);
        _line_y += _line_h + 10;
    }

    if (_line_y == 240) {   // nothing listed
        draw_set_colour(UI_COLOR_DIM);
        draw_text_transformed(_cx, 260, "(no rewards this stage)", 0.4, 0.4, 0);
    }
} else {
    draw_set_colour(UI_COLOR_WARNING);
    draw_text_transformed(_cx, 260, "(stage lookup failed — check current_stage_id)", 0.4, 0.4, 0);
}

// ===== CLAIM button (primary, HIGHLIGHT) =====
var _claim_x = _cx - 100;
var _claim_y = 520;
var _claim_hover = point_in_rectangle(mouse_x, mouse_y, _claim_x, _claim_y, _claim_x + 200, _claim_y + 50);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_claim_x, _claim_y, _claim_x + 200, _claim_y + 50, false);
draw_set_colour(_claim_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
draw_rectangle(_claim_x, _claim_y, _claim_x + 200, _claim_y + 50, true);
if (_claim_hover) draw_rectangle(_claim_x + 1, _claim_y + 1, _claim_x + 199, _claim_y + 49, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_claim_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
draw_text_transformed(_cx, _claim_y + 25, "CLAIM ALL", 0.55, 0.55, 0);

// ===== SKIP (+1 gold) button (secondary) =====
var _skip_x = _cx - 75;
var _skip_y = 600;
var _skip_hover = point_in_rectangle(mouse_x, mouse_y, _skip_x, _skip_y, _skip_x + 150, _skip_y + 40);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_skip_x, _skip_y, _skip_x + 150, _skip_y + 40, false);
draw_set_colour(_skip_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_skip_x, _skip_y, _skip_x + 150, _skip_y + 40, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_skip_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_skip_x + 75, _skip_y + 20, "SKIP (+1G)", 0.4, 0.4, 0);

// Hint
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 20, "[SPACE] also advances", 0.3, 0.3, 0);

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
