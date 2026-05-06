// Local docket-fork click handling.
// Before route lock: only node 1 of either path is enterable.
// After route lock: only the current node on the chosen path is enterable.

event_inherited();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cur_node = obj_game.map[obj_game.map_position];

map_node_hitboxes = [];
map_battle_hitbox = undefined;
map_battle_preview_enter_rect = undefined;
map_battle_preview_close_rect = undefined;
map_hover_lane = "";
map_hover_sub_index = -1;
map_hover_type = "";

if (_cur_node.type == "battle") {
    var _bx = _w * 0.5;
    var _by = _h * 0.5;
    map_battle_hitbox = {
        x1: _bx - map_hearing_w / 2,
        y1: _by - map_hearing_h / 2,
        x2: _bx + map_hearing_w / 2,
        y2: _by + map_hearing_h / 2
    };

    if (map_battle_preview_open) {
        var _modal_w = 500;
        var _modal_h = 420;
        var _modal_x = (_w - _modal_w) / 2;
        var _modal_y = (_h - _modal_h) / 2;
        map_battle_preview_enter_rect = {
            x1: _modal_x + _modal_w - 225,
            y1: _modal_y + _modal_h - 66,
            x2: _modal_x + _modal_w - 28,
            y2: _modal_y + _modal_h - 22
        };
        map_battle_preview_close_rect = {
            x1: _modal_x + _modal_w - 42,
            y1: _modal_y + 14,
            x2: _modal_x + _modal_w - 18,
            y2: _modal_y + 38
        };

        if (keyboard_check_pressed(vk_escape)) {
            map_battle_preview_open = false;
            exit;
        }

        if (mouse_check_button_pressed(mb_left)) {
            if (point_in_rectangle(mouse_x, mouse_y,
                map_battle_preview_enter_rect.x1, map_battle_preview_enter_rect.y1,
                map_battle_preview_enter_rect.x2, map_battle_preview_enter_rect.y2)) {
                map_battle_preview_open = false;
                obj_game.state = "BATTLE_START";
                obj_game.wait_timer = 10;
                room_goto(room0);
                exit;
            }
            if (point_in_rectangle(mouse_x, mouse_y,
                map_battle_preview_close_rect.x1, map_battle_preview_close_rect.y1,
                map_battle_preview_close_rect.x2, map_battle_preview_close_rect.y2)) {
                map_battle_preview_open = false;
                exit;
            }
        }
        exit;
    }

    if (point_in_rectangle(mouse_x, mouse_y, map_battle_hitbox.x1, map_battle_hitbox.y1, map_battle_hitbox.x2, map_battle_hitbox.y2)) {
        map_hover_type = "battle";
        if (mouse_check_button_pressed(mb_left)) {
            map_battle_preview_open = true;
            exit;
        }
    }
    exit;
}

map_battle_preview_open = false;
if (is_undefined(current_branch)) exit;

var _path_ys = [_h * map_path_top_y_ratio, _h * map_path_bottom_y_ratio];
var _lane_names = ["A", "B"];

for (var li = 0; li < 2; li++) {
    var _lane = _lane_names[li];
    var _nodes = (_lane == "A") ? current_branch.line_a_nodes : current_branch.line_b_nodes;
    var _path_y = _path_ys[li];

    for (var ni = 0; ni < array_length(_nodes); ni++) {
        var _sub = _nodes[ni];
        var _node_x = _w * map_path_node_x_ratios[ni];
        var _x1 = _node_x - map_node_w / 2;
        var _y1 = _path_y - map_node_h / 2;
        var _x2 = _node_x + map_node_w / 2;
        var _y2 = _path_y + map_node_h / 2;

        array_push(map_node_hitboxes, {
            lane: _lane,
            sub_index: ni,
            type: _sub.type,
            x1: _x1,
            y1: _y1,
            x2: _x2,
            y2: _y2
        });

        if (point_in_rectangle(mouse_x, mouse_y, _x1, _y1, _x2, _y2)) {
            map_hover_lane = _lane;
            map_hover_sub_index = ni;
            map_hover_type = _sub.type;
        }
    }
}

if (!mouse_check_button_pressed(mb_left)) exit;

for (var hi = 0; hi < array_length(map_node_hitboxes); hi++) {
    var _hb = map_node_hitboxes[hi];
    if (!point_in_rectangle(mouse_x, mouse_y, _hb.x1, _hb.y1, _hb.x2, _hb.y2)) continue;

    var _clickable = false;
    if (obj_game.current_branch_line == "") {
        _clickable = (_hb.sub_index == 0);
    } else if (obj_game.current_branch_line == _hb.lane) {
        _clickable = (_hb.sub_index == obj_game.current_branch_sub_index);
    }

    if (_clickable) {
        obj_game.current_branch_line = _hb.lane;
        obj_game.current_branch_sub_index = _hb.sub_index;
        _enter_current_node();
        exit;
    }
}
