// Trait template registry for the RPS cardgame.
// Player-facing strings live in scr_i18n.gml. This file is the canonical list of
// implemented trait ids; deleted legacy ids are intentionally not returned here.

function _rule_make(_id, _trigger, _effect_type, _params, _tag, _icon, _max_level, _cost) {
    return new RuleStruct(
        _id,
        _trigger,
        _effect_type,
        _params,
        "rule_" + _id + "_desc",
        _icon,
        _tag,
        _max_level,
        _cost
    );
}

function rule_beat_rock()        { return _rule_make("beat_rock",        "judge", "custom_matchup", { target_type: "rock" },     "matchup", "target_rock",     1, 2); }
function rule_beat_paper()       { return _rule_make("beat_paper",       "judge", "custom_matchup", { target_type: "paper" },    "matchup", "target_paper",    1, 2); }
function rule_beat_scissors()    { return _rule_make("beat_scissors",    "judge", "custom_matchup", { target_type: "scissors" }, "matchup", "target_scissors", 1, 2); }
function rule_high_dmg_on_win()  { return _rule_make("high_dmg_on_win",  "on_win", "hp_mod",        { delta_per_level: -1 },     "damage",  "impact_plus",     3, 2); }
function rule_tie_dmg()          { return _rule_make("tie_dmg",          "on_tie", "hp_mod",        { delta: -1, tie_target: "opp" }, "damage", "tie_hit",    1, 2); }
function rule_boost_same_name_on_play() { return _rule_make("boost_same_name_on_play", "on_play", "boost_same_name_on_play", { amount: 1 }, "same", "double_card", 1, 0); }
function rule_return_to_deck()   { return _rule_make("return_to_deck",   "on_played", "return_to_deck_random", {}, "route", "return_deck", 1, 3); }
function rule_return_to_top()    { return _rule_make("return_to_deck_top", "on_played", "return_to_deck_top", {}, "route", "return_top", 1, 3); }

function rule_discard_peek_enemy()      { return _rule_make("discard_peek_enemy",      "on_active_discard", "peek_enemy", {}, "peek",  "eye",        1, 2); }
function rule_draw_peek_enemy()         { return _rule_make("draw_peek_enemy",         "on_draw",           "peek_enemy", {}, "peek",  "eye_card",   1, 2); }
function rule_held_start_peek_enemy()   { return _rule_make("held_start_peek_enemy",   "while_held_turn_start", "peek_enemy", {}, "peek", "eye_hour", 1, 3); }
function rule_held_discard_peek_enemy() { return _rule_make("held_discard_peek_enemy", "held_on_owner_active_discard", "peek_enemy", {}, "peek", "eye_discard", 1, 3); }

function rule_discard_draw_one()        { return _rule_make("discard_draw_one",        "on_active_discard", "draw_one", {}, "draw", "draw_card", 1, 2); }
function rule_draw_chain_one()          { return _rule_make("draw_chain_one",          "on_draw", "draw_one", {}, "draw", "draw_chain", 1, 3); }
function rule_held_refill_limit_plus_one() { return _rule_make("held_refill_limit_plus_one", "held_passive", "hand_limit_bonus", { amount: 1 }, "draw", "hand_plus", 1, 3); }

function rule_held_win_damage_growth()  { return _rule_make("held_win_damage_growth",  "while_held_turn_start", "gain_win_damage", { amount: 1 }, "held", "hour_plus", 1, 3); }
function rule_any_active_discard_growth(){ return _rule_make("any_active_discard_growth", "on_any_active_discard", "gain_win_damage", { amount: 1 }, "held", "discard_plus", 1, 3); }
function rule_held_random_trait()       { return _rule_make("held_random_trait",       "while_held_turn_start", "gain_random_trait", {}, "held", "random_stamp", 1, 4); }

function rule_feed_on_prey()            { return _rule_make("feed_on_prey",            "held_on_owner_active_discard", "gain_if_beats_discarded", { amount: 1 }, "rps_discard", "prey", 1, 3); }
function rule_shed_weakness()           { return _rule_make("shed_weakness",           "held_on_owner_active_discard", "gain_if_discarded_beats_self", { amount: 1 }, "rps_discard", "shed", 1, 3); }
function rule_same_type_fuel()          { return _rule_make("same_type_fuel",          "held_on_owner_active_discard", "gain_if_same_type_discarded", { amount: 1 }, "same", "same_fuel", 1, 3); }
function rule_discard_to_topdeck()      { return _rule_make("discard_to_topdeck",      "on_active_discard", "discard_route_topdeck", {}, "route", "topdeck", 1, 3); }

function _get_rule_template_by_id(rule_id) {
    switch (rule_id) {
        case "beat_rock":                  return rule_beat_rock();
        case "beat_paper":                 return rule_beat_paper();
        case "beat_scissors":              return rule_beat_scissors();
        case "high_dmg_on_win":            return rule_high_dmg_on_win();
        case "tie_dmg":                    return rule_tie_dmg();
        case "boost_same_name_on_play":    return rule_boost_same_name_on_play();
        case "return_to_deck":             return rule_return_to_deck();
        case "return_to_deck_top":         return rule_return_to_top();
        case "discard_peek_enemy":         return rule_discard_peek_enemy();
        case "draw_peek_enemy":            return rule_draw_peek_enemy();
        case "held_start_peek_enemy":      return rule_held_start_peek_enemy();
        case "held_discard_peek_enemy":    return rule_held_discard_peek_enemy();
        case "discard_draw_one":           return rule_discard_draw_one();
        case "draw_chain_one":             return rule_draw_chain_one();
        case "held_refill_limit_plus_one": return rule_held_refill_limit_plus_one();
        case "held_win_damage_growth":     return rule_held_win_damage_growth();
        case "any_active_discard_growth":  return rule_any_active_discard_growth();
        case "held_random_trait":          return rule_held_random_trait();
        case "feed_on_prey":               return rule_feed_on_prey();
        case "shed_weakness":              return rule_shed_weakness();
        case "same_type_fuel":             return rule_same_type_fuel();
        case "discard_to_topdeck":         return rule_discard_to_topdeck();
    }
    return undefined;
}

function _get_all_rule_ids() {
    return [
        "high_dmg_on_win",
        "tie_dmg",
        "boost_same_name_on_play",
        "beat_rock",
        "beat_paper",
        "beat_scissors",
        "return_to_deck",
        "return_to_deck_top",
        "discard_peek_enemy",
        "draw_peek_enemy",
        "held_start_peek_enemy",
        "held_discard_peek_enemy",
        "discard_draw_one",
        "draw_chain_one",
        "held_refill_limit_plus_one",
        "held_win_damage_growth",
        "any_active_discard_growth",
        "held_random_trait",
        "feed_on_prey",
        "shed_weakness",
        "same_type_fuel",
        "discard_to_topdeck"
    ];
}

function _get_random_trait_pool() {
    var _ids = _get_all_rule_ids();
    var _out = [];
    for (var i = 0; i < array_length(_ids); i++) {
        var _id = _ids[i];
        // Avoid recursive self-generation and route loops for the first implementation.
        if (_id == "held_random_trait") continue;
        if (_id == "discard_to_topdeck") continue;
        array_push(_out, _id);
    }
    return _out;
}

function _rule_display_key(_rule_id) {
    return "rule_" + string(_rule_id) + "_name";
}

function _rule_icon_id(_rule) {
    if (is_string(_rule)) {
        var _tpl = _get_rule_template_by_id(_rule);
        return is_undefined(_tpl) ? "unknown" : _tpl.icon_sprite;
    }
    return _rule[$ "icon_sprite"] ?? "unknown";
}

function _rule_ui_meta(_rule_or_id) {
    var _rule = is_string(_rule_or_id) ? _get_rule_template_by_id(_rule_or_id) : _rule_or_id;
    if (is_undefined(_rule)) {
        return { id: "unknown", display_text: "rule_unknown_name", description_text: "rule_unknown_desc", icon_id: "unknown", tag: "unknown" };
    }
    return {
        id: _rule.id,
        display_text: _rule_display_key(_rule.id),
        description_text: _rule.description_text,
        icon_id: _rule.icon_sprite,
        tag: _rule.tag
    };
}

function _card_has_implicit_rule(card_type_name, rule_id) {
    if (card_type_name == "rock"     && rule_id == "beat_scissors") return true;
    if (card_type_name == "scissors" && rule_id == "beat_paper")    return true;
    if (card_type_name == "paper"    && rule_id == "beat_rock")     return true;
    return false;
}

function _get_type_that_beats(card_type_name) {
    if (card_type_name == "rock")     return "paper";
    if (card_type_name == "paper")    return "scissors";
    if (card_type_name == "scissors") return "rock";
    return "rock";
}

function _is_legal_target(rule_template, card) {
    var _type_name = "";
    if (variable_struct_exists(card, "type_name")) {
        _type_name = card.type_name;
    } else if (variable_instance_exists(card, "card_type")) {
        _type_name = _int_to_card_type_str(card.card_type);
    }

    if (rule_template.effect_type == "custom_matchup") {
        var _target = rule_template.effect_params.target_type;
        var _implicit_rule_id = "beat_" + _target;
        if (_card_has_implicit_rule(_type_name, _implicit_rule_id)) return false;
    }

    var _existing = card.rules;
    if (!is_array(_existing)) _existing = [];
    for (var i = 0; i < array_length(_existing); i++) {
        var _r = _existing[i];
        if (_r.id == rule_template.id && _r.level >= rule_template.max_level) return false;
    }

    return true;
}

function _enumerate_legal_targets(rule_pool, player_deck) {
    var _combos = [];
    for (var r = 0; r < array_length(rule_pool); r++) {
        var _rule = _get_rule_template_by_id(rule_pool[r]);
        if (is_undefined(_rule)) continue;
        for (var c = 0; c < array_length(player_deck); c++) {
            if (_is_legal_target(_rule, player_deck[c])) {
                array_push(_combos, { rule: _rule, card: player_deck[c] });
            }
        }
    }
    return _combos;
}
