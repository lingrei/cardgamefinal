event_inherited();

if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;

for (var i = 0; i < array_length(shop_rules); i++) {
    if (rules_sold[i]) continue;
    var _r = shop_rules[i];
    var _y = 205 + i * 135;
    if (point_in_rectangle(mouse_x, mouse_y, 80, _y, 400, _y + 112)) {
        if (obj_game.gold >= _r.cost) {
            rules_sold[i] = true;
            obj_game.upgrade_context = {
                candidates: [_r],
                source: "shop",
                return_room: rm_shop,
                pending_gold_deduct: _r.cost,
                shop_slot_idx: i
            };
            room_goto(rm_upgrade);
        }
        exit;
    }
}

if (!is_undefined(shop_relic) && !relic_sold && point_in_rectangle(mouse_x, mouse_y, 490, 250, 790, 400)) {
    if (obj_game.gold >= shop_relic.cost) {
        obj_game.gold -= shop_relic.cost;
        _add_relic_to_run(shop_relic.id);
        relic_sold = true;
    }
    exit;
}

if (point_in_rectangle(mouse_x, mouse_y, 880, 250, 1080, 340)) {
    if (obj_game.gold >= 1 && obj_game.player_hp < obj_game.player_max_hp) {
        obj_game.gold -= 1;
        obj_game.player_hp += 1;
    }
    exit;
}

if (point_in_rectangle(mouse_x, mouse_y, _cx - 100, 640, _cx + 100, 680)) {
    _mgr_advance_non_battle_node();
    exit;
}
