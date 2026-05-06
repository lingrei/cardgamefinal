// Consumable tools are deleted from the formal MVP.
// The legacy script name now hosts the relic registry.

function _relic_make(_id, _icon_id, _route_tag, _cost) {
    return new RelicStruct(
        _id,
        "relic_" + _id + "_name",
        "relic_" + _id + "_desc",
        _icon_id,
        _route_tag,
        _cost
    );
}

function relic_ember_furnace()      { return _relic_make("ember_furnace",      "ember_bowl",      "discard_burst", 3); }
function relic_ballast_stone()      { return _relic_make("ballast_stone",      "anchor_stone",    "held",          3); }
function relic_copy_seal()          { return _relic_make("copy_seal",          "stamp_press",     "same_type",     3); }
function relic_shuffle_funnel()     { return _relic_make("shuffle_funnel",     "funnel_card",     "discard_draw",  3); }
function relic_cold_box()           { return _relic_make("cold_box",           "ice_box",         "held_growth",   3); }
function relic_predator_totem()     { return _relic_make("predator_totem",     "tooth_totem",     "rps_discard",   3); }
function relic_observation_mirror() { return _relic_make("observation_mirror", "hand_mirror",     "information",   3); }
function relic_buffer_ring()        { return _relic_make("buffer_ring",        "equal_ring",      "tie",           3); }
function relic_tri_compass()        { return _relic_make("tri_compass",        "tri_compass",     "hand_diverse",  3); }
function relic_lone_blade()         { return _relic_make("lone_blade",         "single_blade",    "singleton",     3); }
function relic_zealot_mask()        { return _relic_make("zealot_mask",        "half_mask",       "deck_majority", 3); }
function relic_balance_scales()     { return _relic_make("balance_scales",     "balance_scales",  "deck_minority", 3); }
function relic_backlight_lamp()     { return _relic_make("backlight_lamp",     "backlight_lamp",  "information",   3); }
function relic_blind_die()          { return _relic_make("blind_die",          "blind_die",       "blind_read",    3); }
function relic_lag_clock()          { return _relic_make("lag_clock",          "slow_clock",      "no_discard",    3); }
function relic_card_spark()         { return _relic_make("card_spark",         "card_spark",      "discard_growth",3); }
function relic_protective_knot()    { return _relic_make("protective_knot",    "knot_charm",      "failure_tie",   3); }

function _get_relic_template_by_id(relic_id) {
    switch (relic_id) {
        case "ember_furnace":      return relic_ember_furnace();
        case "ballast_stone":      return relic_ballast_stone();
        case "copy_seal":          return relic_copy_seal();
        case "shuffle_funnel":     return relic_shuffle_funnel();
        case "cold_box":           return relic_cold_box();
        case "predator_totem":     return relic_predator_totem();
        case "observation_mirror": return relic_observation_mirror();
        case "buffer_ring":        return relic_buffer_ring();
        case "tri_compass":        return relic_tri_compass();
        case "lone_blade":         return relic_lone_blade();
        case "zealot_mask":        return relic_zealot_mask();
        case "balance_scales":     return relic_balance_scales();
        case "backlight_lamp":     return relic_backlight_lamp();
        case "blind_die":          return relic_blind_die();
        case "lag_clock":          return relic_lag_clock();
        case "card_spark":         return relic_card_spark();
        case "protective_knot":    return relic_protective_knot();
    }
    return undefined;
}

function _get_all_relic_ids() {
    return [
        "ember_furnace",
        "ballast_stone",
        "copy_seal",
        "shuffle_funnel",
        "cold_box",
        "predator_totem",
        "observation_mirror",
        "buffer_ring",
        "tri_compass",
        "lone_blade",
        "zealot_mask",
        "balance_scales",
        "backlight_lamp",
        "blind_die",
        "lag_clock",
        "card_spark",
        "protective_knot"
    ];
}

function _relic_ui_meta(_relic_or_id) {
    var _relic = is_string(_relic_or_id) ? _get_relic_template_by_id(_relic_or_id) : _relic_or_id;
    if (is_undefined(_relic)) {
        return { id: "unknown", display_text: "relic_unknown_name", description_text: "relic_unknown_desc", icon_id: "unknown", route_tag: "unknown" };
    }
    return {
        id: _relic.id,
        display_text: _relic.display_text,
        description_text: _relic.description_text,
        icon_id: _relic.icon_id,
        route_tag: _relic.route_tag
    };
}

function _has_relic_id(_relic_id) {
    if (!instance_exists(obj_game)) return false;
    for (var i = 0; i < array_length(obj_game.relics); i++) {
        if (obj_game.relics[i].id == _relic_id) return true;
    }
    return false;
}

function _sample_relic_candidates(_count) {
    var _pool = _get_all_relic_ids();
    var _available = [];
    for (var i = 0; i < array_length(_pool); i++) {
        if (!_has_relic_id(_pool[i])) array_push(_available, _pool[i]);
    }
    if (array_length(_available) == 0) _available = _pool;

    var _out = [];
    var _tries = 0;
    while (array_length(_out) < min(_count, array_length(_available)) && _tries < _count * 12) {
        var _id = _available[irandom(array_length(_available) - 1)];
        var _dup = false;
        for (var j = 0; j < array_length(_out); j++) {
            if (_out[j].id == _id) { _dup = true; break; }
        }
        if (!_dup) {
            var _tpl = _get_relic_template_by_id(_id);
            if (!is_undefined(_tpl)) array_push(_out, _tpl);
        }
        _tries++;
    }
    return _out;
}
