// Sprint 3 Phase 2c base Draw_64: placeholder UI used when a subclass doesn't override Draw_64.
// Subclasses that implement real UI (e.g. obj_rest_mgr) override Draw_64 and call
// `_draw_room_bg_and_status()` directly instead of event_inherited, so they get BG + status bar
// but not the placeholder title/hint below.

_draw_room_bg_and_status();

var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _cx = _w / 2;
var _cy = _h / 2;

// Placeholder title (visible when no subclass override)
draw_set_font(fnt_score);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(UI_COLOR_PLAYER);

var _title = "";
switch (_current_room_name) {
    case "rm_run_map": _title = "RUN MAP  (Phase 2c fill)";   break;
    case "rm_shop":    _title = "SHOP  (Phase 2c fill)";      break;
    case "rm_rest":    _title = "REST  (Phase 2c fill)";      break;
    case "rm_event":   _title = "EVENT  (Phase 2c fill)";     break;
    case "rm_remove":  _title = "REMOVE  (Phase 2c fill)";    break;
    case "rm_reward":  _title = "REWARD  (Phase 2c fill)";    break;
    default:           _title = "(unknown room: " + _current_room_name + ")"; break;
}
draw_text_transformed(_cx, _cy - 60, _title, 0.9, 0.9, 0);

// Hint
draw_set_colour(UI_COLOR_HIGHLIGHT);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_transformed(_cx, _cy + 40, "[SPACE] Continue", 0.4, 0.4, 0);
if (_current_room_name == "rm_run_map") {
    draw_text_transformed(_cx, _cy + 80, "[A/B] Pick Lane (when at branch)", 0.35, 0.35, 0);
} else {
    draw_text_transformed(_cx, _cy + 80, "[ESC] Back to Run Map", 0.35, 0.35, 0);
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
