// Local docket-fork run map.
// The map shows only the current interval: current battle -> two 3-node paths -> next battle.

event_inherited();

// Layout source of truth. Draw and Step derive actual GUI positions from these fields.
map_hearing_w = 150;
map_hearing_h = 92;
map_node_w = 118;
map_node_h = 72;
map_current_hearing_x_ratio = 0.14;
map_next_hearing_x_ratio = 0.86;
map_path_node_x_ratios = [0.34, 0.50, 0.66];
map_path_top_y_ratio = 0.35;
map_path_bottom_y_ratio = 0.63;
map_tooltip_w = 220;
map_tooltip_h = 78;

// Hitbox / hover state. Step rebuilds hitboxes before click checks; Draw only reads this state.
map_node_hitboxes = [];
map_battle_hitbox = undefined;
map_battle_preview_open = false;
map_battle_preview_enter_rect = undefined;
map_battle_preview_close_rect = undefined;
map_hover_lane = "";
map_hover_sub_index = -1;
map_hover_type = "";
map_layout_ready = true;

// Current branch cache.
current_branch = undefined;
if (obj_game.map_position < array_length(obj_game.map)) {
    var _cur_node = obj_game.map[obj_game.map_position];
    if (_cur_node.type == "branch_marker") {
        current_branch = get_branch_by_id(_cur_node.payload.branch_id);
    }
}

show_debug_message("[rm_run_map] local docket fork initialized at map_position=" + string(obj_game.map_position));
