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
        case "rm_reward":  show_debug_message("[rm_reward] SPACE ignored; use CLAIM/SKIP"); break;
        case "rm_run_map": show_debug_message("[rm_run_map] SPACE ignored; use the visible path nodes"); break;
    }
}

// Keyboard shortcut support for the two branch paths.
if (_current_room_name == "rm_run_map" && obj_game.state == "RUN_MAP_BRANCH") {
    var _picked_lane = "";
    if (keyboard_check_pressed(ord("A"))) _picked_lane = "A";
    else if (keyboard_check_pressed(ord("B"))) _picked_lane = "B";
    if (_picked_lane != "") {
        if (obj_game.current_branch_line == "") {
            obj_game.current_branch_line = _picked_lane;
            obj_game.current_branch_sub_index = 0;
            _enter_current_node();
            show_debug_message("[rm_run_map] Path " + _picked_lane + " picked via keyboard");
        } else if (obj_game.current_branch_line == _picked_lane) {
            _enter_current_node();
            show_debug_message("[rm_run_map] Path " + _picked_lane + " current sub-node entered via keyboard");
        } else {
            show_debug_message("[rm_run_map] Path " + _picked_lane + " ignored; locked to path " + obj_game.current_branch_line);
        }
    }
}
