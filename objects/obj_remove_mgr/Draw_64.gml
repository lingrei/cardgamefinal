// Sprint 3 Phase 2e.1 — rm_remove fan picker Draw.
// Title + deck composition readout (top) + fan deck (lower) + CANCEL/CONFIRM buttons.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;
var _deck_size = array_length(obj_game.player_deck);

// Title
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_RULE_DECK);   // purple — deck-manipulating
draw_text_transformed(_cx, 90, "REMOVE A CARD", 1.0, 1.0, 0);

// Deck counts
var _counts = _count_deck_by_type();
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, 140, "Deck: " + string(_deck_size) + " cards  (R:" + string(_counts.rock) + "  S:" + string(_counts.scissors) + "  P:" + string(_counts.paper) + ")", 0.4, 0.4, 0);

// Hint / status
if (_deck_size <= 1) {
    draw_set_colour(UI_COLOR_WARNING);
    draw_text_transformed(_cx, 190, "Cannot remove — deck must keep at least 1 card", 0.4, 0.4, 0);
} else if (selected_card_idx < 0) {
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_cx, 190, "Click a card to select it for removal", 0.4, 0.4, 0);
} else {
    var _sel = obj_game.player_deck[selected_card_idx];
    draw_set_colour(UI_COLOR_SUCCESS);
    draw_text_transformed(_cx, 190, "Selected: " + _sel.type_name + "  (rules: " + string(array_length(_sel.rules)) + ") — click CONFIRM", 0.4, 0.4, 0);
}

// ===== Fan deck =====
var _hovered_card_for_tip = -1;
for (var i = 0; i < array_length(fan_positions); i++) {
    var _p = fan_positions[i];
    var _card = obj_game.player_deck[i];
    var _is_hover = (hovered_card_idx == i) && (_deck_size > 1);
    var _is_selected = (selected_card_idx == i);
    if (_is_hover) _hovered_card_for_tip = i;

    var _cx_card = _p.x;
    var _cy_card = _p.y;
    if (_is_hover || _is_selected) {
        var _ang_rad = degtorad(_p.angle_deg);
        _cx_card += sin(_ang_rad) * fan_hover_pop;
        _cy_card -= cos(_ang_rad) * fan_hover_pop;
    }

    var _alpha = (_deck_size <= 1) ? 0.5 : 1.0;
    draw_set_alpha(_alpha);
    _draw_card_face(_card.type_name, _cx_card - fan_card_w / 2, _cy_card - fan_card_h / 2, fan_card_w, fan_card_h, 0, _alpha, true);

    // Selection / hover border
    if (_is_selected) {
        draw_set_alpha(1);
        draw_set_colour(UI_COLOR_OPP);   // red — "about to remove"
        draw_rectangle(_cx_card - fan_card_w / 2 - 2, _cy_card - fan_card_h / 2 - 2,
                       _cx_card + fan_card_w / 2 + 2, _cy_card + fan_card_h / 2 + 2, true);
        draw_rectangle(_cx_card - fan_card_w / 2 - 3, _cy_card - fan_card_h / 2 - 3,
                       _cx_card + fan_card_w / 2 + 3, _cy_card + fan_card_h / 2 + 3, true);
    } else if (_is_hover) {
        draw_set_alpha(1);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_rectangle(_cx_card - fan_card_w / 2 - 2, _cy_card - fan_card_h / 2 - 2,
                       _cx_card + fan_card_w / 2 + 2, _cy_card + fan_card_h / 2 + 2, true);
    }

    // Existing trait stamps
    if (array_length(_card.rules) > 0) {
        draw_set_alpha(1);
        var _stamp_n = min(3, array_length(_card.rules));
        for (var _ri = 0; _ri < _stamp_n; _ri++) {
            _draw_rule_chip(_card.rules[_ri], _cx_card + fan_card_w / 2 - 24 - _ri * 16, _cy_card - fan_card_h / 2 + 6, 14);
        }
    }

    draw_set_alpha(1);
}

if (_hovered_card_for_tip >= 0) {
    _draw_card_struct_tooltip(obj_game.player_deck[_hovered_card_for_tip], mouse_x + 18, mouse_y + 18);
}

// ===== CANCEL (LEAVE) / CONFIRM buttons =====
var _cancel_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 250, 660, _cx - 50, 700);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 250, 660, _cx - 50, 700, false);
draw_set_colour(_cancel_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_cx - 250, 660, _cx - 50, 700, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_cancel_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_cx - 150, 680, "LEAVE", 0.45, 0.45, 0);

var _confirm_enabled = (selected_card_idx >= 0 && _deck_size > 1);
var _confirm_hover = _confirm_enabled && point_in_rectangle(mouse_x, mouse_y, _cx + 50, 660, _cx + 250, 700);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx + 50, 660, _cx + 250, 700, false);
draw_set_colour(_confirm_hover ? UI_COLOR_HIGHLIGHT : (_confirm_enabled ? UI_COLOR_OPP : UI_COLOR_DIM));
draw_rectangle(_cx + 50, 660, _cx + 250, 700, true);
if (_confirm_hover) draw_rectangle(_cx + 51, 661, _cx + 249, 699, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_confirm_hover ? UI_COLOR_HIGHLIGHT : (_confirm_enabled ? UI_COLOR_OPP : UI_COLOR_DIM));
draw_text_transformed(_cx + 150, 680, "REMOVE", 0.45, 0.45, 0);

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
