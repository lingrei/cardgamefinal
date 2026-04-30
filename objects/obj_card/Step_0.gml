if (is_moving) {
    x = lerp(x, target_x, move_speed);
    y = lerp(y, target_y, move_speed);
    if (abs(x - target_x) < 0.5 && abs(y - target_y) < 0.5) {
        x = target_x;
        y = target_y;
        is_moving = false;
    }
}

// Backlog cleanup: smooth current_rotation → target_rotation lerp (matches position lerp pace).
// Without this, Phase 1 Batch 3 E1 fan rotation snaps to 0 instantly when hand collapses while
// position eases — visible jarring. Now both ease together.
if (abs(current_rotation - target_rotation) > 0.1) {
    current_rotation = lerp(current_rotation, target_rotation, 0.25);
} else if (current_rotation != target_rotation) {
    current_rotation = target_rotation;
}

if (flip_state == 1) {
    flip_scale -= 0.1;
    if (flip_scale <= 0) {
        flip_scale = 0;
        face_up = flip_to_face;
        flip_state = 2;
    }
} else if (flip_state == 2) {
    flip_scale += 0.1;
    if (flip_scale >= 1) {
        flip_scale = 1;
        flip_state = 0;
	}
} else if (flip_state == 0 && flip_scale < 1) {
    // 2026-04-26 defensive: stuck cards (flip_scale stuck at 0 with state=0) become invisible.
    // Snap back to 1 — likely a state machine race or external mutation we missed.
    flip_scale = 1;
}

var _ox = sprite_get_xoffset(spr_card_back);
var _oy = sprite_get_yoffset(spr_card_back);
var _sw = sprite_get_width(spr_card_back);
var _sh = sprite_get_height(spr_card_back);
var _mouse_over = point_in_rectangle(mouse_x, mouse_y, x - _ox, y - _oy, x - _ox + _sw, y - _oy + _sh);

// Round 3: set tooltip target when hovered on face-up static card (and no overlay open)
if (_mouse_over && flip_state == 0 && face_up && obj_game.ui_overlay_open == OV_NONE) {
    obj_game.ui_tooltip_target = id;
}

if (hoverable && _mouse_over) {
    // 2026-04-26: owner-aware pop direction — player hand pops UP (-18, away from bottom HUD),
    // opp hand pops DOWN (+18, toward play area = "card pulled out before play" feel).
    // Used by force_opp_replay picker so opp hand cards visually rise toward opp_play position.
    var _pop_y = (card_owner == "opp") ? 18 : -18;
    hover_offset = lerp(hover_offset, _pop_y, 0.3);
} else {
    hover_offset = lerp(hover_offset, 0, 0.6);
}

// Round 3: block card click when any UI overlay is open
if (obj_game.ui_overlay_open != OV_NONE) exit;

// D60: peekable click path removed — peek now handled by item_use (scr_item_engine).
if (_mouse_over && mouse_check_button_pressed(mb_left) && clickable) {
    // Phase 1 Batch 4 (B3): if a "select card from hand" item is active, the click resolves
    // to that callback instead of normal selected_card targeting. Only applies to player hand
    // cards (clickable=true gates this — opp_hand has clickable=false).
    if (obj_game.ui_select_card_mode) {
        _resolve_select_card_pick(id);
    } else {
        // 2026-04-26: option B select-immediate-preview — clicked card moves to PLR_PLAY position
        // (preview slot). DUEL button still commits. Re-clicking another card swaps selection
        // (old card returns to fan via _update_plr_hand_fan, new one moves to play slot).
        _player_select_card(id);
    }
}