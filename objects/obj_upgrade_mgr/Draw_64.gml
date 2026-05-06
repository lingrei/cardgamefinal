// Unified Upgrade Draw.
// UI pass 2026-05-04: separate the rule choice row from the deck target row.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

if (is_undefined(upgrade_ctx)) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_WARNING);
    draw_text_transformed(_cx, _h / 2, "Upgrade context missing - press ESC", 0.5, 0.5, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    exit;
}

// ===== Header =====
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_PLAYER);
draw_text_transformed(_cx, 72, "CHOOSE AN UPGRADE", 0.64, 0.64, 0);

draw_set_colour(UI_COLOR_DIM);
var _src_label = "(from " + upgrade_ctx.source + ")";
if (upgrade_ctx.source == "shop" && upgrade_ctx.pending_gold_deduct > 0) {
    _src_label += "  -  CANCEL refunds " + string(upgrade_ctx.pending_gold_deduct) + "G";
}
draw_text_transformed(_cx, 102, _src_label, 0.22, 0.22, 0);

// ===== Candidate rule cards =====
var _n = array_length(upgrade_ctx.candidates);
var _cand_y = 118;
var _cand_w = 300;
var _cand_h = 154;
var _hovered_rule_for_tip = -1;

if (_n == 1) {
    if (_draw_upgrade_candidate(upgrade_ctx.candidates[0], _cx, _cand_y, _cand_w, _cand_h, selected_rule_idx == 0)) {
        _hovered_rule_for_tip = 0;
    }
} else {
    var _cand_xs = [260, 640, 1020];
    for (var i = 0; i < _n; i++) {
        if (_draw_upgrade_candidate(upgrade_ctx.candidates[i], _cand_xs[i], _cand_y, _cand_w, _cand_h, selected_rule_idx == i)) {
            _hovered_rule_for_tip = i;
        }
    }
}

// ===== Status strip =====
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_score);
if (selected_rule_idx < 0) {
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_cx, 304, "Select a trait", 0.32, 0.32, 0);
} else if (selected_target_card_idx < 0) {
    if (array_length(legal_targets_per_candidate[selected_rule_idx]) == 0) {
        draw_set_colour(UI_COLOR_WARNING);
        draw_text_transformed(_cx, 304, "No legal targets - pick another trait or cancel", 0.30, 0.30, 0);
    } else {
        draw_set_colour(UI_COLOR_NEUTRAL);
        draw_text_transformed(_cx, 304, "Pick a target card", 0.32, 0.32, 0);
    }
} else {
    draw_set_colour(UI_COLOR_SUCCESS);
    draw_text_transformed(_cx, 304, "Ready", 0.32, 0.32, 0);
}

draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(190, 330, _w - 190, 648, false);
draw_set_colour(UI_COLOR_DIM);
draw_rectangle(190, 330, _w - 190, 648, true);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_colour(UI_COLOR_DIM);
draw_text_transformed(_cx, 344, "YOUR DECK", 0.22, 0.22, 0);

// Legal targets for currently-selected rule.
var _legal_set = (selected_rule_idx >= 0) ? legal_targets_per_candidate[selected_rule_idx] : [];
var _hovered_card_for_tip = -1;

for (var i = 0; i < array_length(fan_positions); i++) {
    var _p = fan_positions[i];
    var _card = obj_game.player_deck[i];
    var _is_legal = true;
    if (selected_rule_idx >= 0) {
        _is_legal = false;
        for (var j = 0; j < array_length(_legal_set); j++) {
            if (_legal_set[j] == i) { _is_legal = true; break; }
        }
    }

    var _is_hover = (hovered_deck_idx == i) && _is_legal;
    var _is_selected = (selected_target_card_idx == i);
    if (_is_hover) _hovered_card_for_tip = i;

    var _cx_card = _p.x;
    var _cy_card = _p.y;
    if (_is_hover || _is_selected) {
        var _ang_rad = degtorad(_p.angle_deg);
        _cx_card += sin(_ang_rad) * fan_hover_pop;
        _cy_card -= cos(_ang_rad) * fan_hover_pop;
    }

    var _alpha = _is_legal ? 1.0 : 0.22;
    draw_set_alpha(_alpha);
    _draw_card_face(_card.type_name, _cx_card - fan_card_w / 2, _cy_card - fan_card_h / 2, fan_card_w, fan_card_h, 0, _alpha, true);

    draw_set_alpha(1);
    if (_is_selected) {
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_rectangle(_cx_card - fan_card_w / 2 - 3, _cy_card - fan_card_h / 2 - 3,
                       _cx_card + fan_card_w / 2 + 3, _cy_card + fan_card_h / 2 + 3, true);
        draw_rectangle(_cx_card - fan_card_w / 2 - 5, _cy_card - fan_card_h / 2 - 5,
                       _cx_card + fan_card_w / 2 + 5, _cy_card + fan_card_h / 2 + 5, true);
    } else if (_is_hover) {
        draw_set_colour(UI_COLOR_PLAYER);
        draw_rectangle(_cx_card - fan_card_w / 2 - 3, _cy_card - fan_card_h / 2 - 3,
                       _cx_card + fan_card_w / 2 + 3, _cy_card + fan_card_h / 2 + 3, true);
    }

    if (_is_legal && array_length(_card.rules) > 0) {
        var _stamp_n = min(3, array_length(_card.rules));
        for (var _ri = 0; _ri < _stamp_n; _ri++) {
            _draw_rule_chip(_card.rules[_ri], _cx_card + fan_card_w / 2 - 20 - _ri * 14, _cy_card - fan_card_h / 2 + 6, 13);
        }
    }
}

if (_hovered_card_for_tip >= 0) {
    _draw_card_struct_tooltip(obj_game.player_deck[_hovered_card_for_tip], mouse_x + 18, mouse_y + 18);
}

// ===== CANCEL / CONFIRM buttons =====
var _cancel_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 250, 660, _cx - 50, 700);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 250, 660, _cx - 50, 700, false);
draw_set_colour(_cancel_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_cx - 250, 660, _cx - 50, 700, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_cancel_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_cx - 150, 680, "CANCEL", 0.42, 0.42, 0);

var _confirm_enabled = (selected_rule_idx >= 0 && selected_target_card_idx >= 0);
var _confirm_hover = _confirm_enabled && point_in_rectangle(mouse_x, mouse_y, _cx + 50, 660, _cx + 250, 700);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx + 50, 660, _cx + 250, 700, false);
draw_set_colour(_confirm_hover ? UI_COLOR_HIGHLIGHT : (_confirm_enabled ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_rectangle(_cx + 50, 660, _cx + 250, 700, true);
if (_confirm_hover) draw_rectangle(_cx + 51, 661, _cx + 249, 699, true);
draw_set_colour(_confirm_hover ? UI_COLOR_HIGHLIGHT : (_confirm_enabled ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_text_transformed(_cx + 150, 680, "CONFIRM", 0.42, 0.42, 0);

if (_hovered_rule_for_tip >= 0) {
    _draw_rule_hover_tooltip(upgrade_ctx.candidates[_hovered_rule_for_tip], mouse_x + 18, mouse_y + 18);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);

function _draw_upgrade_candidate(_rule, _cx_center, _y, _w, _h, _selected) {
    var _x = _cx_center - _w / 2;
    _draw_rule_info_card(_rule, _x, _y, _w, _h, _selected);
    return point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h);
}
