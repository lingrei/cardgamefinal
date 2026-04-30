// Sprint 3 Phase 2c.reward — Step override.
// event_inherited() for base ESC + SPACE dispatch; then CLAIM / SKIP click handling.

event_inherited();

if (reward_claimed) exit;
if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;

// CLAIM button (primary)
if (point_in_rectangle(mouse_x, mouse_y, _cx - 100, 520, _cx + 100, 570)) {
    _apply_stage_rewards(reward_stage);
    show_debug_message("[rm_reward] CLAIM → rewards applied");

    // Phase 2d.starter: if this stage grants an upgrade (e.g. Tutorial starter pack), route to rm_upgrade
    // before advancing. `_upgrade_finalize` switch source="starter" then calls `_mgr_advance_reward`.
    if (!is_undefined(reward_stage) && reward_stage.rewards.upgrade_count > 0) {
        var _candidates = _sample_rules_from_pool(reward_stage, 3);
        if (array_length(_candidates) > 0) {
            obj_game.upgrade_context = {
                candidates: _candidates,
                source: "starter",
                return_room: rm_reward,
                pending_gold_deduct: 0,
                shop_slot_idx: -1
            };
            reward_claimed = true;
            show_debug_message("[rm_reward] starter pack → rm_upgrade (" + string(array_length(_candidates)) + " candidates)");
            room_goto(rm_upgrade);
            exit;
        }
    }

    reward_claimed = true;
    _mgr_advance_reward();
    exit;
}

// SKIP (+1 gold) button
if (point_in_rectangle(mouse_x, mouse_y, _cx - 75, 600, _cx + 75, 640)) {
    obj_game.gold += 1;
    show_debug_message("[rm_reward] SKIP (+1 gold bonus). Gold now " + string(obj_game.gold));
    reward_claimed = true;

    // Phase 3.tutorial (review fix): tutorial SKIP must also mark done + TITLE, otherwise
    // _mgr_advance_reward increments map_position past tutorial map's length-1 (out-of-bounds
    // in rm_run_map) AND tutorial_done stays false → tutorial re-runs next boot.
    if (obj_game.is_tutorial_run) {
        settings_mark_tutorial_done();
        obj_game.is_tutorial_run = false;
        obj_game.state = "TITLE";
        obj_game.wait_timer = 10;
        show_debug_message("[tutorial] SKIP path → tutorial_done persisted, returning to TITLE");
        room_goto(room0);
        exit;
    }

    _mgr_advance_reward();
    exit;
}
