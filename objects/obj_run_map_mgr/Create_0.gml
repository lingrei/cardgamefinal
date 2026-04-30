// Sprint 3 Phase 2e.2 — rm_run_map vertical long-axis map + camera follow.
// Replaces Phase 2c MVP (single static branch view) with full-run vertical map.
// Layout: B1 at bottom (world_y ≈ 1800), B6 at top (world_y ≈ 0). Branches between battles.
// Camera: current map_position node → screen y=432 (60% down); top-clamp so topmost node never > y=100.

event_inherited();

// ===== Precompute world y for each map node =====
map_world_y = [];
var _cursor = 1800;
for (var i = 0; i < array_length(obj_game.map); i++) {
    array_push(map_world_y, _cursor);
    var _node = obj_game.map[i];
    _cursor -= (_node.type == "battle") ? 110 : 340;   // branches need room for 2 lane × 3 sub expansion
}

// ===== Camera scroll: current node at screen y=432, clamp so topmost stays on-screen =====
// Fix (Phase 2e review HIGH-1): earlier `min(…, 100)` clamp was wrong magnitude — capped
// scroll at 100 instead of capping based on topmost world_y. Final branch (B6 world_y ≈ -450)
// would have scroll clamped to 100 → current screen_y = -110 + 100 = -10 (culled). Fixed:
// compute `_scroll_max = 100 - topmost_world_y` so topmost node sits at screen y=100 when clamp engages.
var _cur_world_y = (obj_game.map_position < array_length(map_world_y))
                   ? map_world_y[obj_game.map_position]
                   : 0;
var _topmost_wy = map_world_y[array_length(map_world_y) - 1];
var _scroll_max = 100 - _topmost_wy;
scroll_offset = min(432 - _cur_world_y, _scroll_max);

// ===== Current branch cache (reuse Phase 2c logic for branch_marker expansion) =====
current_branch = undefined;
if (obj_game.map_position < array_length(obj_game.map)) {
    var _cur_node = obj_game.map[obj_game.map_position];
    if (_cur_node.type == "branch_marker") {
        current_branch = get_branch_by_id(_cur_node.payload.branch_id);
    }
}

show_debug_message("[rm_run_map] Camera scroll_offset=" + string(scroll_offset) + " current_map_pos=" + string(obj_game.map_position));
