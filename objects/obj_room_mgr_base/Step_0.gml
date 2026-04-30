// Sprint 3 Phase 2a — Base manager Step:
// - Shared navigation helpers (ESC back to map, SPACE "continue" dispatch by room name).
// - Subclasses can override Step_0 entirely or call event_inherited() first and add specific handlers.
// Phase 2b/c will progressively move per-room SPACE advance logic into each subclass, at which
// point the switch below can shrink.

if (!instance_exists(obj_game)) exit;   // Defensive: obj_game must persist across rooms

// ESC = quick exit to run map (except when already there)
if (keyboard_check_pressed(vk_escape) && _current_room_name != "rm_run_map") {
    room_goto(rm_run_map);
    exit;
}

if (keyboard_check_pressed(vk_space)) {
    // Sprint 3 Phase 2c: advance logic extracted to scr_game_helpers so subclasses can call
    // these from their own UI click handlers (e.g. obj_rest_mgr HEAL button → same flow).
    switch (_current_room_name) {
        case "rm_shop":
        case "rm_rest":
        case "rm_event":
        case "rm_remove":  _mgr_advance_non_battle_node(); break;
        case "rm_reward":  _mgr_advance_reward();          break;
        case "rm_run_map": _mgr_advance_run_map_debug();   break;   // Phase 2c.run_map replaces with node click
    }
}

// Sprint 3 H3 fix: lane selection via A/B keys (rm_run_map + state=RUN_MAP_BRANCH)
if (_current_room_name == "rm_run_map" && obj_game.state == "RUN_MAP_BRANCH") {
    var _picked_lane = "";
    if (keyboard_check_pressed(ord("A"))) _picked_lane = "A";
    else if (keyboard_check_pressed(ord("B"))) _picked_lane = "B";
    if (_picked_lane != "") {
        obj_game.current_branch_line = _picked_lane;
        obj_game.current_branch_sub_index = 0;
        _enter_current_node();
        show_debug_message("[Sprint3 H3] Lane " + _picked_lane + " picked via keyboard (rm_run_map skeleton)");
    }
}
