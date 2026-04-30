// Sprint 3 Phase 2a — Base class for all non-battle room managers.
// Shared: record current room name + log entry. Run state held by obj_game (persistent).
// Subclasses (obj_run_map_mgr / obj_shop_mgr / obj_rest_mgr / obj_event_mgr /
// obj_remove_mgr / obj_reward_mgr) inherit by default. Phase 2b/c will override
// specific events (Step_0 / Draw_64) to add per-room UI + interaction.
//
// Subclass override pattern:
//   Create_0:  event_inherited();  // run this + add own init
//   Step_0:    event_inherited();  // shared ESC + base SPACE dispatch first
//              // then add own logic
//   Draw_64:   // either event_inherited() + additions, or full override
//
// ⚠️ If a subclass overrides Step_0 WITHOUT calling event_inherited(), it loses ESC→rm_run_map
// + base SPACE dispatch + A/B lane selection — subclass must either call event_inherited()
// first or re-implement those handlers locally. Same applies to Draw_64 (loses BG fill +
// title + status bar + hint).

_current_room_name = room_get_name(room);
show_debug_message("[obj_room_mgr_base] Entered room: " + _current_room_name);

// 2026-04-27: per-room BGM. Only 4 BGM available; uses bgm_events for all hub rooms (shop/rest/
// event/remove/upgrade/reward) until per-room BGM lands.
switch (_current_room_name) {
    case "rm_run_map":
        _play_bgm(bgm_run_map);
        break;
    case "rm_event":
    case "rm_shop":
    case "rm_rest":
    case "rm_remove":
    case "rm_reward":
    case "rm_upgrade":
        _play_bgm(bgm_events);
        break;
}
