// Sprint 3 Phase 2c.rest — Step override.
// event_inherited() first: base ESC + SPACE dispatch + A/B lane selection (no-op here).
// Then rest-specific click: HEAL / UPGRADE / LEAVE buttons.

event_inherited();

// Guard against double-click after choice already made (prevents re-advance race)
if (rest_choice_made) exit;

// Click must happen inside this frame
if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;
var _btn_w = 200;
var _btn_h = 160;
var _btn_y = 260;

// HEAL button (left big card) — match Draw_64 rect exactly
// Phase 2e.5 polish: refuse click when HP already full (allow player to still pick UPGRADE)
if (point_in_rectangle(mouse_x, mouse_y, _cx - 240, _btn_y, _cx - 40, _btn_y + _btn_h)) {
    if (obj_game.player_hp >= obj_game.player_max_hp) {
        show_debug_message("[rm_rest] HP already full, HEAL disabled");
        exit;
    }
    var _heal = 2;
    obj_game.player_hp = min(obj_game.player_hp + _heal, obj_game.player_max_hp);
    show_debug_message("[rm_rest] HEAL +" + string(_heal) + " HP → " + string(obj_game.player_hp));
    rest_choice_made = true;
    _mgr_advance_non_battle_node();
    exit;
}

// UPGRADE button (right big card) — Phase 2d: trigger Unified Upgrade UI with 3 candidates
if (point_in_rectangle(mouse_x, mouse_y, _cx + 40, _btn_y, _cx + 240, _btn_y + _btn_h)) {
    var _stage = _get_stage_by_id(obj_game.current_stage_id);
    var _candidates = _sample_rules_from_pool(_stage, 3);
    if (array_length(_candidates) == 0) {
        show_debug_message("[rm_rest] UPGRADE failed: no rules available in stage pool; advancing without upgrade");
        rest_choice_made = true;
        _mgr_advance_non_battle_node();
        exit;
    }
    obj_game.upgrade_context = {
        candidates: _candidates,
        source: "rest",
        return_room: rm_rest,
        pending_gold_deduct: 0,
        shop_slot_idx: -1
    };
    rest_choice_made = true;
    show_debug_message("[rm_rest] UPGRADE → rm_upgrade (" + string(array_length(_candidates)) + " candidates)");
    room_goto(rm_upgrade);
    exit;
}

// LEAVE button (skip without heal/upgrade)
if (point_in_rectangle(mouse_x, mouse_y, _cx - 75, 560, _cx + 75, 600)) {
    show_debug_message("[rm_rest] LEAVE (no heal/upgrade)");
    rest_choice_made = true;
    _mgr_advance_non_battle_node();
    exit;
}
