// Sprint 3 Phase 2e.2 — rm_run_map Draw: vertical long-axis map + camera scroll.
// Draws all 11 map nodes at world_y + scroll_offset. If current is branch_marker, expand 2 lane × 3 sub.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;

// 2026-04-27 debug indicator: confirm room entry. If user sees "RUN MAP" text but otherwise
// sees a near-black screen, then UI is minimal. If they don't see this text → room transition failed.
draw_set_alpha(1);
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_rectangle(0, 50, _w, 110, false);
draw_set_colour(UI_COLOR_BG);
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_transformed(_cx, 80, "RUN MAP — Click a node or press A/B to pick lane", 0.5, 0.5, 0);

// Title
draw_set_colour(UI_COLOR_PLAYER);

// ===== Draw path connectors + nodes (skip off-screen) =====
var _node_w = 60;
var _node_h = 60;
var _center_x = _cx;

// Connector lines between consecutive map nodes (drawn first so nodes overlap them)
for (var i = 0; i < array_length(obj_game.map) - 1; i++) {
    var _y1 = map_world_y[i] + scroll_offset;
    var _y2 = map_world_y[i + 1] + scroll_offset;
    if (max(_y1, _y2) < 80 || min(_y1, _y2) > _h - 20) continue;   // both off-screen
    draw_set_alpha(0.4);
    draw_set_colour(UI_COLOR_DIM);
    draw_line_width(_center_x, _y1, _center_x, _y2, 3);
    draw_set_alpha(1);
}

// Nodes
for (var i = 0; i < array_length(obj_game.map); i++) {
    var _node = obj_game.map[i];
    var _screen_y = map_world_y[i] + scroll_offset;

    if (_screen_y < 80 || _screen_y > _h - 20) continue;   // off-screen cull

    var _is_past    = (i < obj_game.map_position);
    var _is_current = (i == obj_game.map_position);
    var _is_future  = (i > obj_game.map_position);

    var _node_color;
    if (_is_past)    _node_color = UI_COLOR_DIM;
    else if (_is_current) _node_color = UI_COLOR_HIGHLIGHT;
    else             _node_color = UI_COLOR_NEUTRAL;

    var _nx1 = _center_x - _node_w / 2;
    var _ny1 = _screen_y - _node_h / 2;
    var _nx2 = _nx1 + _node_w;
    var _ny2 = _ny1 + _node_h;

    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_nx1, _ny1, _nx2, _ny2, false);
    draw_set_colour(_node_color);
    draw_rectangle(_nx1, _ny1, _nx2, _ny2, true);
    if (_is_current) draw_rectangle(_nx1 + 1, _ny1 + 1, _nx2 - 1, _ny2 - 1, true);

    // Label
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(_node_color);
    var _label = "";
    switch (_node.type) {
        case "battle":        _label = "B" + string(_node.payload.battle_index + 1); break;
        case "branch_marker": _label = "◇"; break;
    }
    draw_text_transformed(_center_x, _screen_y, _label, 0.6, 0.6, 0);

    if (_is_past) {
        draw_set_colour(UI_COLOR_SUCCESS);
        draw_text_transformed(_center_x + 40, _screen_y, "✓", 0.5, 0.5, 0);
    }
}

// ===== Current branch: expand lane A + lane B (3 sub-nodes each) =====
if (!is_undefined(current_branch)) {
    // Phase 1 Batch 3 (E2+E4 review M2 fix): lane Y -130/-250 (0px overlap with main map nodes).
    // Kept in sync with obj_run_map_mgr/Step_0.gml click rects.
    var _lane_a_world_y = map_world_y[obj_game.map_position] - 130;
    var _lane_b_world_y = map_world_y[obj_game.map_position] - 250;
    var _lane_names = ["A", "B"];
    var _lane_world_ys = [_lane_a_world_y, _lane_b_world_y];
    var _sub_node_w = 140;
    var _sub_node_h = 100;

    for (var li = 0; li < 2; li++) {
        var _lane = _lane_names[li];
        var _nodes = (_lane == "A") ? current_branch.line_a_nodes : current_branch.line_b_nodes;
        var _lane_screen_y = _lane_world_ys[li] + scroll_offset;
        var _lane_locked = (obj_game.current_branch_line != "" && obj_game.current_branch_line != _lane);

        // Lane label
        draw_set_halign(fa_right);
        draw_set_valign(fa_middle);
        draw_set_font(fnt_score);
        draw_set_colour(_lane_locked ? UI_COLOR_DIM : UI_COLOR_NEUTRAL);
        draw_text_transformed(_cx - 280, _lane_screen_y + _sub_node_h / 2, "LANE " + _lane, 0.5, 0.5, 0);

        for (var ni = 0; ni < array_length(_nodes); ni++) {
            var _sub = _nodes[ni];
            var _nx = _cx - 240 + ni * 160;

            var _done    = (obj_game.current_branch_line == _lane && ni < obj_game.current_branch_sub_index);
            var _current_sub = (obj_game.current_branch_line == _lane && ni == obj_game.current_branch_sub_index);
            var _entry   = (obj_game.current_branch_line == "" && ni == 0);
            var _color;
            if (_done)          _color = UI_COLOR_SUCCESS;
            else if (_current_sub) _color = UI_COLOR_HIGHLIGHT;
            else if (_entry)    _color = UI_COLOR_HIGHLIGHT;
            else if (_lane_locked) _color = UI_COLOR_DIM;
            else                _color = UI_COLOR_NEUTRAL;

            var _clickable = (_current_sub || _entry);
            var _hover = _clickable && point_in_rectangle(mouse_x, mouse_y, _nx, _lane_screen_y, _nx + _sub_node_w, _lane_screen_y + _sub_node_h);

            draw_set_colour(UI_COLOR_BG_MID);
            draw_rectangle(_nx, _lane_screen_y, _nx + _sub_node_w, _lane_screen_y + _sub_node_h, false);
            draw_set_colour(_hover ? UI_COLOR_HIGHLIGHT : _color);
            draw_rectangle(_nx, _lane_screen_y, _nx + _sub_node_w, _lane_screen_y + _sub_node_h, true);
            if (_hover) draw_rectangle(_nx + 1, _lane_screen_y + 1, _nx + _sub_node_w - 1, _lane_screen_y + _sub_node_h - 1, true);

            // Type label
            var _label2 = "?";
            switch (_sub.type) {
                case "shop":   _label2 = "SHOP";   break;
                case "rest":   _label2 = "REST";   break;
                case "event":  _label2 = "EVENT";  break;
                case "remove": _label2 = "REMOVE"; break;
            }
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(_color);
            draw_text_transformed(_nx + _sub_node_w / 2, _lane_screen_y + 28, _label2, 0.45, 0.45, 0);

            if (_done)         draw_text_transformed(_nx + _sub_node_w / 2, _lane_screen_y + 58, "DONE ✓", 0.35, 0.35, 0);
            else if (_current_sub) draw_text_transformed(_nx + _sub_node_w / 2, _lane_screen_y + 58, "> HERE <", 0.35, 0.35, 0);
            else if (_entry)   draw_text_transformed(_nx + _sub_node_w / 2, _lane_screen_y + 58, "ENTER", 0.35, 0.35, 0);
        }
    }
}

// Hint (bottom)
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_font(fnt_score);
draw_set_colour(UI_COLOR_NEUTRAL);
draw_text_transformed(_cx, _h - 30, "Click a lane entry node — or A/B keys. Camera follows your position.", 0.33, 0.33, 0);
draw_set_colour(UI_COLOR_DIM);
draw_text_transformed(_cx, _h - 10, "[SPACE] debug skip branch → next battle", 0.28, 0.28, 0);

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
