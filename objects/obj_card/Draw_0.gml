var _spr;
if (face_up) {
    switch (card_type) {
        case 0: _spr = spr_card_rock;     break;
        case 1: _spr = spr_card_scissors; break;
        case 2: _spr = spr_card_paper;    break;
        default: _spr = spr_card_back;    // 2026-04-26 fallback: undefined card_type → back
    }
} else {
    _spr = spr_card_back;
}

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
draw_sprite_ext(_spr, 0, x + _shake_x, y + hover_offset + _shake_y, _safe_scale, 1, current_rotation, c_white, 1);

// Round 3: display_name + rule dots (only on face_up + near-static flip)
if (face_up && abs(flip_scale - 1) < 0.1) {
    // display_name at card bottom
    if (display_name != "") {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_font(fnt_score);
        draw_set_colour(c_white);
        draw_text_transformed(x + 50 + _shake_x, y + hover_offset + 125 + _shake_y, display_name, 0.2, 0.2, 0);
    }
    // Rule dots (top-right of card)
    var _rule_count = min(3, array_length(rules));
    for (var i = 0; i < _rule_count; i++) {
        var _r = rules[i];
        var _col = _get_rule_color(_r);
        var _dx = x + 80 - i * 10 + _shake_x;
        var _dy = y + hover_offset + 8 + _shake_y;
        draw_set_colour(_col);
        draw_circle(_dx, _dy, 4, false);
        if (_r.level > 1) {
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(c_white);
            draw_text_transformed(_dx, _dy, string(_r.level), 0.12, 0.12, 0);
        }
    }
    // Reset draw state
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
}
