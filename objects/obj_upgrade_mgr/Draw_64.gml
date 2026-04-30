// Sprint 3 Phase 2d — Unified Upgrade Draw (D50 §3.13.1 layout).
// Upper: N candidate rule cards. Middle: hint. Lower: deck fan. Bottom: CANCEL/CONFIRM.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

if (is_undefined(upgrade_ctx)) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_WARNING);
    draw_text_transformed(_cx, _h / 2, "Upgrade context missing — press ESC", 0.5, 0.5, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    exit;
}

// ===== Title =====
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_PLAYER);
draw_text_transformed(_cx, 90, "CHOOSE AN UPGRADE", 0.9, 0.9, 0);

// Source badge (rest/shop/event_d/starter) + shop refund hint
draw_set_colour(UI_COLOR_DIM);
var _src_label = "(from " + upgrade_ctx.source + ")";
if (upgrade_ctx.source == "shop" && upgrade_ctx.pending_gold_deduct > 0) {
    _src_label += "  —  CANCEL refunds " + string(upgrade_ctx.pending_gold_deduct) + "G";
}
draw_text_transformed(_cx, 135, _src_label, 0.3, 0.3, 0);

// ===== Candidate rule cards (upper) =====
var _n = array_length(upgrade_ctx.candidates);
var _cand_y = 180;
var _cand_h = 180;

if (_n == 1) {
    // Single candidate center
    _draw_upgrade_candidate(upgrade_ctx.candidates[0], _cx, _cand_y, 280, _cand_h, selected_rule_idx == 0);
} else {
    var _cand_xs = [350, 640, 930];
    for (var i = 0; i < _n; i++) {
        _draw_upgrade_candidate(upgrade_ctx.candidates[i], _cand_xs[i], _cand_y, 250, _cand_h, selected_rule_idx == i);
    }
}

// ===== Hint middle =====
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_NEUTRAL);
if (selected_rule_idx < 0) {
    draw_text_transformed(_cx, 400, "Select a rule above", 0.4, 0.4, 0);
} else if (selected_target_card_idx < 0) {
    // Phase 2d review M1 fix: surface "no legal targets" when deck can't accept this rule
    if (array_length(legal_targets_per_candidate[selected_rule_idx]) == 0) {
        draw_set_colour(UI_COLOR_WARNING);
        draw_text_transformed(_cx, 400, "No legal targets for this rule — pick another or CANCEL", 0.4, 0.4, 0);
    } else {
        draw_text_transformed(_cx, 400, "Pick a card below (legal targets highlighted)", 0.4, 0.4, 0);
    }
} else {
    draw_set_colour(UI_COLOR_SUCCESS);
    draw_text_transformed(_cx, 400, "Ready — click CONFIRM to apply", 0.4, 0.4, 0);
}

// ===== Deck fan (lower) =====
// Legal targets for currently-selected rule (for desaturation filter)
var _legal_set = (selected_rule_idx >= 0) ? legal_targets_per_candidate[selected_rule_idx] : [];

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

    // Radial pop for hover
    var _cx_card = _p.x;
    var _cy_card = _p.y;
    if (_is_hover || _is_selected) {
        var _ang_rad = degtorad(_p.angle_deg);
        _cx_card += sin(_ang_rad) * fan_hover_pop;
        _cy_card -= cos(_ang_rad) * fan_hover_pop;
    }

    // Select sprite by card type
    var _spr = spr_card_back;
    switch (_card.type_name) {
        case "rock":     _spr = spr_card_rock; break;
        case "scissors": _spr = spr_card_scissors; break;
        case "paper":    _spr = spr_card_paper; break;
    }

    // Alpha: legal full / illegal 0.3
    var _alpha = _is_legal ? 1.0 : 0.3;
    draw_set_alpha(_alpha);
    draw_sprite_stretched(_spr, 0, _cx_card - fan_card_w / 2, _cy_card - fan_card_h / 2, fan_card_w, fan_card_h);

    // Selection border
    if (_is_selected) {
        draw_set_alpha(1);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_rectangle(_cx_card - fan_card_w / 2 - 2, _cy_card - fan_card_h / 2 - 2,
                       _cx_card + fan_card_w / 2 + 2, _cy_card + fan_card_h / 2 + 2, true);
        draw_rectangle(_cx_card - fan_card_w / 2 - 3, _cy_card - fan_card_h / 2 - 3,
                       _cx_card + fan_card_w / 2 + 3, _cy_card + fan_card_h / 2 + 3, true);
    } else if (_is_hover) {
        draw_set_alpha(1);
        draw_set_colour(UI_COLOR_PLAYER);
        draw_rectangle(_cx_card - fan_card_w / 2 - 2, _cy_card - fan_card_h / 2 - 2,
                       _cx_card + fan_card_w / 2 + 2, _cy_card + fan_card_h / 2 + 2, true);
    }

    // Existing rules count label (bottom-right corner of card)
    if (_is_legal && array_length(_card.rules) > 0) {
        draw_set_alpha(1);
        draw_set_colour(UI_COLOR_OPP);
        draw_set_halign(fa_right);
        draw_set_valign(fa_top);
        draw_set_font(fnt_score);
        draw_text_transformed(_cx_card + fan_card_w / 2 - 5, _cy_card - fan_card_h / 2 + 3, "+" + string(array_length(_card.rules)), 0.3, 0.3, 0);
    }

    draw_set_alpha(1);
}

// ===== CANCEL / CONFIRM buttons (bottom) =====
var _cancel_hover = point_in_rectangle(mouse_x, mouse_y, _cx - 250, 660, _cx - 50, 700);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx - 250, 660, _cx - 50, 700, false);
draw_set_colour(_cancel_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_rectangle(_cx - 250, 660, _cx - 50, 700, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_cancel_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
draw_text_transformed(_cx - 150, 680, "CANCEL", 0.45, 0.45, 0);

var _confirm_enabled = (selected_rule_idx >= 0 && selected_target_card_idx >= 0);
var _confirm_hover = _confirm_enabled && point_in_rectangle(mouse_x, mouse_y, _cx + 50, 660, _cx + 250, 700);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(_cx + 50, 660, _cx + 250, 700, false);
draw_set_colour(_confirm_hover ? UI_COLOR_HIGHLIGHT : (_confirm_enabled ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_rectangle(_cx + 50, 660, _cx + 250, 700, true);
if (_confirm_hover) draw_rectangle(_cx + 51, 661, _cx + 249, 699, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(_confirm_hover ? UI_COLOR_HIGHLIGHT : (_confirm_enabled ? UI_COLOR_SUCCESS : UI_COLOR_DIM));
draw_text_transformed(_cx + 150, 680, "CONFIRM", 0.45, 0.45, 0);

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);


// ===== Helper function (local to this event): draw a single candidate rule card =====
function _draw_upgrade_candidate(_rule, _cx_center, _y, _w, _h, _selected) {
    var _x = _cx_center - _w / 2;
    var _hover = point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h);

    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    var _border_col = _selected ? UI_COLOR_HIGHLIGHT : (_hover ? UI_COLOR_PLAYER : UI_COLOR_NEUTRAL);
    draw_set_colour(_border_col);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    if (_selected || _hover) draw_rectangle(_x + 1, _y + 1, _x + _w - 1, _y + _h - 1, true);

    // Rule id
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(c_white);
    draw_text_transformed(_cx_center, _y + 20, _rule.id, 0.4, 0.4, 0);

    // Description (i18n)
    draw_set_colour(UI_COLOR_NEUTRAL);
    var _desc = _t(_rule.description_text);
    draw_text_ext_transformed(_cx_center, _y + 60, _desc, 18, _w - 30, 0.28, 0.28, 0);

    // Cost badge (top right)
    if (variable_struct_exists(_rule, "cost") && _rule.cost > 0) {
        draw_set_halign(fa_right);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_x + _w - 15, _y + 15, string(_rule.cost) + "G", 0.45, 0.45, 0);
    }
}
