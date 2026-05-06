event_inherited();

shop_stage = _get_stage_by_id(obj_game.current_stage_id);

shop_rules = [];
if (!is_undefined(shop_stage)) {
    var _pool = shop_stage.rule_pool;
    var _n = min(3, array_length(_pool));
    var _used = [];
    var _tries = 0;
    while (array_length(shop_rules) < _n && _tries < _n * 8) {
        var _id = _pool[irandom(array_length(_pool) - 1)];
        if (!array_contains(_used, _id)) {
            var _r = _get_rule_template_by_id(_id);
            if (!is_undefined(_r)) {
                array_push(shop_rules, _r);
                array_push(_used, _id);
            }
        }
        _tries++;
    }
}
rules_sold = [false, false, false];

var _relics = _sample_relic_candidates(1);
shop_relic = (array_length(_relics) > 0) ? _relics[0] : undefined;
relic_sold = false;

show_debug_message("[rm_shop] Stocked: " + string(array_length(shop_rules)) + " rules + relic + heal");
