// Sprint 3 Phase 2e.2 — rm_run_map Step: sub-node click detection accounting for scroll_offset.
// Visible map nodes + (if at branch_marker) 2 lane × 3 sub on-screen click.

event_inherited();

if (is_undefined(current_branch)) exit;
if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;
var _node_w = 140;
// Phase 1 Batch 3 (E4): click rect _node_h synced to Draw_64 _sub_node_h (80→100 breathing).
// Without this, click rect would be 20px shorter than visual → bottom 20px appears clickable but isn't.
var _node_h = 100;
// Phase 1 Batch 3 (E2+E4 review M2 fix): lane Y offsets shifted to -130/-250 (was -90/-210).
// lane A bottom (Y0-130+100 = Y0-30) exactly touches main map node top (Y0-30, _node_h=60),
// achieving 0px overlap (E2 plan intent). Lane B follows with 20px breathing between lanes.
var _lane_a_world_y = map_world_y[obj_game.map_position] - 130;   // lane A row above branch center
var _lane_b_world_y = map_world_y[obj_game.map_position] - 250;   // lane B row further up
var _lane_ys_world = [_lane_a_world_y, _lane_b_world_y];
var _lane_names = ["A", "B"];

for (var li = 0; li < 2; li++) {
    var _lane = _lane_names[li];
    var _nodes = (_lane == "A") ? current_branch.line_a_nodes : current_branch.line_b_nodes;
    var _lane_world_y = _lane_ys_world[li];
    var _lane_screen_y = _lane_world_y + scroll_offset;

    for (var ni = 0; ni < array_length(_nodes); ni++) {
        var _nx = _cx - 240 + ni * 160;

        var _clickable = false;
        if (obj_game.current_branch_line == "") {
            _clickable = (ni == 0);   // entry only
        } else if (obj_game.current_branch_line == _lane) {
            _clickable = (ni == obj_game.current_branch_sub_index);
        }

        if (_clickable && point_in_rectangle(mouse_x, mouse_y, _nx, _lane_screen_y, _nx + _node_w, _lane_screen_y + _node_h)) {
            obj_game.current_branch_line = _lane;
            obj_game.current_branch_sub_index = ni;
            _enter_current_node();
            exit;
        }
    }
}
