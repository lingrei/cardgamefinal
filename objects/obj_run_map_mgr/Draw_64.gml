// Local docket-fork run map placeholder art.
// Pure-color version: current battle -> two visible 3-node paths -> next battle.

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cur_node = obj_game.map[obj_game.map_position];

draw_set_alpha(1);
draw_set_colour(UI_COLOR_BG);
draw_rectangle(0, 0, _w, _h, false);
draw_set_alpha(0.18);
draw_set_colour(UI_COLOR_TABLE_LINE);
for (var _grain = 0; _grain < 8; _grain++) {
    var _gy = 84 + _grain * 78;
    draw_line_width(0, _gy, _w, _gy + 10 * sin(_grain), 1);
}
draw_set_alpha(0.72);
draw_set_colour(UI_COLOR_BG_MID);
draw_rectangle(0, 0, _w, 58, false);
draw_set_alpha(1);

draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

draw_set_colour(UI_COLOR_NEUTRAL);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var _status_text = "HP " + string(obj_game.player_hp) + "/" + string(obj_game.player_max_hp)
    + "   Gold " + string(obj_game.gold)
    + "   Deck " + string(array_length(obj_game.player_deck));
draw_text_transformed(18, 15, _status_text, 0.26, 0.26, 0);
_draw_relic_shelf(_w - 238, 18);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

var _mid_y = (_h * map_path_top_y_ratio + _h * map_path_bottom_y_ratio) / 2;
var _current_x = _w * map_current_hearing_x_ratio;
var _next_x = _w * map_next_hearing_x_ratio;

if (_cur_node.type == "battle") {
    var _hover_battle = (map_hover_type == "battle");
    var _x1 = _w * 0.5 - map_hearing_w / 2;
    var _y1 = _h * 0.5 - map_hearing_h / 2;
    var _x2 = _x1 + map_hearing_w;
    var _y2 = _y1 + map_hearing_h;

    draw_set_colour(UI_COLOR_PARCHMENT);
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_colour(_hover_battle ? UI_COLOR_HIGHLIGHT : UI_COLOR_PARCHMENT_D);
    draw_rectangle(_x1, _y1, _x2, _y2, true);

    draw_set_colour(UI_COLOR_OPP);
    draw_circle(_x2 - 24, _y1 + 24, 14, false);
    draw_set_colour(UI_COLOR_INK);
    draw_text_transformed(_w * 0.5, _h * 0.5 - 12, "Battle", 0.42, 0.42, 0);
    draw_text_transformed(_w * 0.5, _h * 0.5 + 20, "OPEN", 0.32, 0.32, 0);

    var _stage = _get_stage_by_id(_cur_node.payload.stage_id);
    var _enemy = undefined;
    if (!is_undefined(_stage)) {
        _enemy = _get_enemy_template_by_id(_pick_enemy_from_stage(_stage));
    }
    if (map_battle_preview_open && !is_undefined(_stage) && !is_undefined(_enemy)) {
        draw_set_alpha(0.62);
        draw_set_colour(UI_COLOR_BG);
        draw_rectangle(0, 0, _w, _h, false);
        draw_set_alpha(1);

        var _modal_w = 500;
        var _modal_h = 420;
        var _modal_x = (_w - _modal_w) / 2;
        var _modal_y = (_h - _modal_h) / 2;
        _draw_enemy_briefing_panel(_modal_x, _modal_y, _modal_w, _modal_h, _stage, _enemy);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);

        var _close_r = map_battle_preview_close_rect;
        if (!is_undefined(_close_r)) {
            draw_set_colour(UI_COLOR_PARCHMENT_D);
            draw_rectangle(_close_r.x1, _close_r.y1, _close_r.x2, _close_r.y2, true);
            draw_set_colour(UI_COLOR_INK);
            draw_text_transformed((_close_r.x1 + _close_r.x2) / 2, (_close_r.y1 + _close_r.y2) / 2, "X", 0.25, 0.25, 0);
        }

        var _enter_r = map_battle_preview_enter_rect;
        if (!is_undefined(_enter_r)) {
            var _enter_hover = point_in_rectangle(mouse_x, mouse_y, _enter_r.x1, _enter_r.y1, _enter_r.x2, _enter_r.y2);
            draw_set_colour(_enter_hover ? UI_COLOR_HIGHLIGHT : UI_COLOR_SUCCESS);
            draw_rectangle(_enter_r.x1, _enter_r.y1, _enter_r.x2, _enter_r.y2, false);
            draw_set_colour(UI_COLOR_INK);
            draw_rectangle(_enter_r.x1, _enter_r.y1, _enter_r.x2, _enter_r.y2, true);
            draw_text_transformed((_enter_r.x1 + _enter_r.x2) / 2, (_enter_r.y1 + _enter_r.y2) / 2, "Enter Battle", 0.22, 0.22, 0);
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_set_alpha(1);
    exit;
}

if (is_undefined(current_branch)) {
    draw_set_colour(UI_COLOR_WARNING);
    draw_text_transformed(_w / 2, _h / 2, "MAP DATA MISSING", 0.45, 0.45, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_set_alpha(1);
    exit;
}

var _prev_battle_index = max(0, obj_game.current_battle_index);
var _next_battle_index = min(_prev_battle_index + 1, 6);

// Battle notices.
var _cur_x1 = _current_x - map_hearing_w / 2;
var _cur_y1 = _mid_y - map_hearing_h / 2;
var _cur_x2 = _cur_x1 + map_hearing_w;
var _cur_y2 = _cur_y1 + map_hearing_h;
var _next_x1 = _next_x - map_hearing_w / 2;
var _next_y1 = _mid_y - map_hearing_h / 2;
var _next_x2 = _next_x1 + map_hearing_w;
var _next_y2 = _next_y1 + map_hearing_h;

draw_set_colour(UI_COLOR_PARCHMENT);
draw_rectangle(_cur_x1, _cur_y1, _cur_x2, _cur_y2, false);
draw_rectangle(_next_x1, _next_y1, _next_x2, _next_y2, false);
draw_set_colour(UI_COLOR_PARCHMENT_D);
draw_rectangle(_cur_x1, _cur_y1, _cur_x2, _cur_y2, true);
draw_rectangle(_next_x1, _next_y1, _next_x2, _next_y2, true);

draw_set_colour(UI_COLOR_SUCCESS);
draw_circle(_cur_x2 - 24, _cur_y1 + 24, 13, false);
draw_set_colour(UI_COLOR_OPP);
draw_circle(_next_x2 - 24, _next_y1 + 24, 13, false);

draw_set_colour(UI_COLOR_INK);
draw_text_transformed(_current_x, _mid_y - 10, "Battle", 0.34, 0.34, 0);
draw_text_transformed(_current_x, _mid_y + 20, "CLEARED", 0.26, 0.26, 0);
draw_text_transformed(_next_x, _mid_y - 10, "Battle", 0.34, 0.34, 0);
draw_text_transformed(_next_x, _mid_y + 20, "NEXT", 0.26, 0.26, 0);

var _lane_names = ["A", "B"];
var _path_ys = [_h * map_path_top_y_ratio, _h * map_path_bottom_y_ratio];

for (var li = 0; li < 2; li++) {
    var _lane = _lane_names[li];
    var _nodes = (_lane == "A") ? current_branch.line_a_nodes : current_branch.line_b_nodes;
    var _path_y = _path_ys[li];
    var _lane_locked = (obj_game.current_branch_line != "" && obj_game.current_branch_line != _lane);
    var _lane_selected = (obj_game.current_branch_line == _lane);
    var _line_col = _lane_locked ? UI_COLOR_DIM : (_lane_selected ? UI_COLOR_HIGHLIGHT : UI_COLOR_TABLE_LINE);

    draw_set_alpha(_lane_locked ? 0.32 : 0.82);
    draw_set_colour(_line_col);

    var _last_x = _cur_x2;
    var _last_y = _mid_y;
    for (var ci = 0; ci < array_length(map_path_node_x_ratios); ci++) {
        var _nx = _w * map_path_node_x_ratios[ci];
        draw_line_width(_last_x, _last_y, _nx - map_node_w / 2, _path_y, _lane_selected ? 5 : 3);
        _last_x = _nx + map_node_w / 2;
        _last_y = _path_y;
    }
    draw_line_width(_last_x, _last_y, _next_x1, _mid_y, _lane_selected ? 5 : 3);
    draw_set_alpha(1);

    if (_lane_locked) {
        draw_set_colour(UI_COLOR_DIM);
        draw_line_width(_w * 0.28, _path_y - 52, _w * 0.72, _path_y + 52, 4);
    }

    for (var ni = 0; ni < array_length(_nodes); ni++) {
        var _sub = _nodes[ni];
        var _node_x = _w * map_path_node_x_ratios[ni];
        var _x1n = _node_x - map_node_w / 2;
        var _y1n = _path_y - map_node_h / 2;
        var _x2n = _node_x + map_node_w / 2;
        var _y2n = _path_y + map_node_h / 2;

        var _done = (_lane_selected && ni < obj_game.current_branch_sub_index);
        var _current_sub = (_lane_selected && ni == obj_game.current_branch_sub_index);
        var _entry = (obj_game.current_branch_line == "" && ni == 0);
        var _hover = (map_hover_lane == _lane && map_hover_sub_index == ni);

        var _fill_col = UI_COLOR_PARCHMENT;
        switch (_sub.type) {
            case "shop":   _fill_col = UI_COLOR_PAPER_ACCENT; break;
            case "rest":   _fill_col = UI_COLOR_SUCCESS; break;
            case "event":  _fill_col = UI_COLOR_RULE_DECK; break;
            case "remove": _fill_col = UI_COLOR_ROCK_ACCENT; break;
        }

        draw_set_alpha(_lane_locked ? 0.34 : 0.92);
        draw_set_colour(_fill_col);
        draw_rectangle(_x1n, _y1n, _x2n, _y2n, false);
        draw_set_alpha(1);

        var _border_col = UI_COLOR_NEUTRAL;
        if (_lane_locked) _border_col = UI_COLOR_DIM;
        else if (_done) _border_col = UI_COLOR_SUCCESS;
        else if (_current_sub || _entry || _hover) _border_col = UI_COLOR_HIGHLIGHT;

        draw_set_colour(_border_col);
        draw_rectangle(_x1n, _y1n, _x2n, _y2n, true);
        if (_hover) draw_rectangle(_x1n + 2, _y1n + 2, _x2n - 2, _y2n - 2, true);

        var _label = "?";
        switch (_sub.type) {
            case "shop":   _label = "SHOP"; break;
            case "rest":   _label = "REST"; break;
            case "event":  _label = "EVENT"; break;
            case "remove": _label = "REMOVE"; break;
        }

        draw_set_colour(UI_COLOR_INK);
        draw_text_transformed(_node_x, _path_y - 8, _label, 0.34, 0.34, 0);

        if (_done) {
            draw_set_colour(UI_COLOR_INK);
            draw_text_transformed(_node_x, _path_y + 20, "DONE", 0.26, 0.26, 0);
        } else if (_current_sub || _entry) {
            draw_set_colour(UI_COLOR_INK);
            draw_text_transformed(_node_x, _path_y + 20, "OPEN", 0.26, 0.26, 0);
        }
    }
}

// Hover tooltip. Node labels are placeholders until production assets replace them.
if (map_hover_type != "" && map_hover_type != "battle") {
    var _tip_x = min(mouse_x + 18, _w - map_tooltip_w - 12);
    var _tip_y = min(mouse_y + 18, _h - map_tooltip_h - 12);
    var _desc = "";
    switch (map_hover_type) {
        case "shop":   _desc = "Buy upgrades, relics, or healing."; break;
        case "rest":   _desc = "Recover or improve a card."; break;
        case "event":  _desc = "Resolve a court incident."; break;
        case "remove": _desc = "Remove one card from the deck."; break;
        default:       _desc = "Unknown docket."; break;
    }

    draw_set_alpha(0.96);
    draw_set_colour(UI_COLOR_PARCHMENT);
    draw_rectangle(_tip_x, _tip_y, _tip_x + map_tooltip_w, _tip_y + map_tooltip_h, false);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_PARCHMENT_D);
    draw_rectangle(_tip_x, _tip_y, _tip_x + map_tooltip_w, _tip_y + map_tooltip_h, true);
    draw_set_colour(UI_COLOR_INK);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_transformed(_tip_x + 12, _tip_y + 12, string_upper(map_hover_type), 0.30, 0.30, 0);
    draw_text_transformed(_tip_x + 12, _tip_y + 42, _desc, 0.24, 0.24, 0);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
