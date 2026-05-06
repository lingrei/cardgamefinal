// Phase 1 Batch 2 (C2): Tier A screen shake — randomize offset per-card during shake window.
var _shake_x = 0;
var _shake_y = 0;
if (instance_exists(obj_game) && obj_game.ui_screen_shake_timer > 0) {
    var _amp = obj_game.ui_screen_shake_timer * 0.4;
    _shake_x = irandom_range(-_amp, _amp);
    _shake_y = irandom_range(-_amp, _amp);
}

// 2026-04-26 Bug C fix: clamp flip_scale to safe minimum. If scale is 0/negative due to a
// state machine race, sprite renders invisible (width=0). Clamp to 0.05 so card always visible.
// Outside of mid-flip animation (state=1 dropping toward 0), flip_scale should be 1 anyway —
// state=0 with scale<1 was already snapped in obj_card/Step_0.
var _safe_scale = max(flip_scale, 0.05);

// Sprint 3 Phase 2b.5: use current_rotation field (non-zero when in discard pile for 凌乱感)
_draw_card_face(card_type, x + _shake_x, y + hover_offset + _shake_y, 100 * _safe_scale, 140, current_rotation, 1, face_up);

if (marked_for_discard) {
    draw_set_alpha(0.95);
    draw_set_colour(UI_COLOR_WARNING);
    draw_rectangle(x - 3 + _shake_x, y + hover_offset - 3 + _shake_y, x + 103 + _shake_x, y + hover_offset + 143 + _shake_y, true);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

if (ui_pulse_timer > 0) {
    draw_set_alpha(0.35 + 0.25 * sin(current_time / 70));
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_rectangle(x - 5 + _shake_x, y + hover_offset - 5 + _shake_y, x + 105 + _shake_x, y + hover_offset + 145 + _shake_y, true);
    draw_rectangle(x - 7 + _shake_x, y + hover_offset - 7 + _shake_y, x + 107 + _shake_x, y + hover_offset + 147 + _shake_y, true);
    draw_set_alpha(1);
}

if (win_damage_bonus > 0 && abs(flip_scale - 1) < 0.1
    && (card_owner != "opp" || face_up || is_peek_revealed)) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_circle(x + 18 + _shake_x, y + hover_offset + 18 + _shake_y, 13, false);
    draw_set_colour(UI_COLOR_BG);
    draw_text_transformed(x + 18 + _shake_x, y + hover_offset + 18 + _shake_y, "+" + string(win_damage_bonus), 0.2, 0.2, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
}

// Round 3: display_name + rule dots (only on face_up + near-static flip)
if (face_up && abs(flip_scale - 1) < 0.1) {
    // display_name at card bottom
    if (false && display_name != "") {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_font(fnt_score);
        draw_set_colour(c_white);
        draw_text_transformed(x + 50 + _shake_x, y + hover_offset + 125 + _shake_y, display_name, 0.2, 0.2, 0);
    }
    // Trait stamps (top-right of card)
    var _rule_total = array_length(rules);
    var _rule_count = min(4, _rule_total);
    for (var i = 0; i < _rule_count; i++) {
        var _dx = x + 76 - i * 17 + _shake_x;
        var _dy = y + hover_offset + 8 + _shake_y;
        if (i == 3 && _rule_total > 4) {
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(UI_COLOR_HIGHLIGHT);
            draw_circle(_dx + 7, _dy + 7, 8, false);
            draw_set_colour(UI_COLOR_BG);
            draw_text_transformed(_dx + 7, _dy + 7, "+" + string(_rule_total - 3), 0.12, 0.12, 0);
        } else {
            var _r = rules[i];
            _draw_rule_chip(_r, _dx, _dy, 15);
            if (_r.level > 1) {
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_colour(c_white);
                draw_text_transformed(_dx + 7, _dy + 7, string(_r.level), 0.10, 0.10, 0);
            }
        }
    }
    // Reset draw state
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
}
