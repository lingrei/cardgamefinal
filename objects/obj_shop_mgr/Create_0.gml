// Sprint 3 Phase 2c.shop — Create override (D49 §O.6).
// Stock: 3 rules from current stage rule_pool + 2 items from MVP item pool + unlimited 1G/1HP heal.
// Rules are one-time purchase (Shop visit-scoped). Items unlimited per visit. Heal consumes 1 gold per HP.

event_inherited();

shop_stage = _get_stage_by_id(obj_game.current_stage_id);

// Sample 3 rules (D61: random pick from rule_pool; Phase 2c MVP takes first 3, randomize later)
shop_rules = [];
if (!is_undefined(shop_stage)) {
    var _pool = shop_stage.rule_pool;
    var _n = min(3, array_length(_pool));
    for (var i = 0; i < _n; i++) {
        var _r = _get_rule_template_by_id(_pool[i]);
        if (!is_undefined(_r)) array_push(shop_rules, _r);
    }
}
rules_sold = [false, false, false];   // per-slot sold flag (rules one-time)

// Sample 2 items from MVP pool.
// Fix (Phase 2c review HIGH-1): item IDs are unprefixed in scr_config_items — use _get_mvp_item_pool()
// which returns canonical ["peek_opp_hand", "draw_extra", "immune_this_round"].
var _item_pool = _get_mvp_item_pool();
shop_items = [];
for (var i = 0; i < 2; i++) {
    var _id = _item_pool[irandom(array_length(_item_pool) - 1)];
    var _it = _get_item_template_by_id(_id);
    if (!is_undefined(_it)) array_push(shop_items, _it);
}

show_debug_message("[rm_shop] Stocked: " + string(array_length(shop_rules)) + " rules + " + string(array_length(shop_items)) + " items + heal");
