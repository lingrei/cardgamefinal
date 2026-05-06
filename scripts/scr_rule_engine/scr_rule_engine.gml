// Rule engine: handler registration, dispatch, validation.
// Handlers receive (rule, context) — rule gives access to level + effect_params; context gives trigger info + owner.
// HP mod uses additive model: final HP delta = default (-1 for winner's opponent) + sum(rule.level * delta_per_level).

function rule_engine_init() {
    if (!variable_global_exists("rule_handlers")) global.rule_handlers = {};
    global.rule_handlers.hp_mod         = effect_hp_mod;
    global.rule_handlers.score_mod      = effect_score_mod;
    global.rule_handlers.peek           = effect_peek;
    global.rule_handlers.custom_matchup = effect_custom_matchup_stub;
    global.rule_handlers.boost_same_name_on_play = effect_boost_same_name_on_play;
    global.rule_handlers.peek_enemy = effect_peek_enemy;
    global.rule_handlers.draw_one = effect_draw_one;
    global.rule_handlers.gain_win_damage = effect_gain_win_damage;
    global.rule_handlers.gain_random_trait = effect_gain_random_trait;
    global.rule_handlers.gain_if_beats_discarded = effect_gain_if_beats_discarded;
    global.rule_handlers.gain_if_discarded_beats_self = effect_gain_if_discarded_beats_self;
    global.rule_handlers.gain_if_same_type_discarded = effect_gain_if_same_type_discarded;
    global.rule_handlers.discard_route_topdeck = effect_discard_route_topdeck;
    global.rule_handlers.return_to_deck_random = effect_return_to_deck_random;
    global.rule_handlers.return_to_deck_top = effect_return_to_deck_top;
    global.rule_handlers.hand_limit_bonus = effect_hand_limit_bonus;
}

function rule_apply(card, rule, context) {
    // Recursion guard
    var _depth = context[$ "rule_depth"] ?? 0;
    if (_depth >= 5) {
        show_debug_message("[WARN] rule_apply depth limit reached, aborting. rule.id=" + string(rule.id));
        return;
    }

    var _h = global.rule_handlers[$ rule.effect_type];
    if (is_undefined(_h)) {
        show_debug_message("[WARN] Unknown effect_type: " + string(rule.effect_type));
        return;
    }
    // Pass rule itself (handler reads rule.level + rule.effect_params)
    _h(rule, context);
}

function rule_apply_all(card, trigger, context) {
    var _rules = card.rules;
    for (var i = 0; i < array_length(_rules); i++) {
        var _r = _rules[i];
        if (_r.trigger == trigger) {
            var _ctx = variable_clone(context);
            _ctx.rule_depth = (context[$ "rule_depth"] ?? 0) + 1;
            rule_apply(card, _r, _ctx);
        }
    }
}

function validate_rule_struct(rule) {
    // Template-level check: max_level is required, level is NOT (runtime field, constructor default = 1)
    var _required = ["id", "trigger", "effect_type", "effect_params", "description_text", "max_level"];
    var _ok = true;
    for (var i = 0; i < array_length(_required); i++) {
        var _f = _required[i];
        if (!variable_struct_exists(rule, _f)) {
            var _id = rule[$ "id"] ?? "<unknown>";
            show_debug_message("[FATAL] Rule missing field: " + _f + " — rule.id=" + string(_id));
            _ok = false;
        }
    }
    return _ok;
}

// ===== Effect handlers (Round 2 real impl for hp_mod; others remain stubs) =====

function effect_hp_mod(rule, context) {
    var _params = rule.effect_params;
    var _level = rule.level;
    var _delta = _params[$ "delta"] ?? 0;
    if (variable_struct_exists(_params, "delta_per_level")) {
        _delta = _params.delta_per_level * _level;
    }

    // Target resolution by trigger_reason:
    // - on_win: owner is winner -> damage opponent
    // - on_lose: owner is loser -> damage winner (retaliation semantic)
    // - on_tie: default self-damage; params.tie_target overrides ("self" | "opp" | "both")
    var _target = "";
    if (context.trigger_reason == "on_win") {
        _target = (context.owner == "player") ? "opp" : "player";
    } else if (context.trigger_reason == "on_lose") {
        _target = (context.owner == "player") ? "player" : "opp";
    } else if (context.trigger_reason == "on_tie") {
        var _tie_target = _params[$ "tie_target"] ?? "self";
        if (_tie_target == "self") {
            _target = context.owner;
        } else if (_tie_target == "opp") {
            _target = (context.owner == "player") ? "opp" : "player";
        } else if (_tie_target == "both") {
            // Apply delta to both
            obj_game.player_hp += _delta;
            obj_game.opp_hp += _delta;
            show_debug_message("[Round2] hp_mod tie both: delta=" + string(_delta)
                + " player_hp=" + string(obj_game.player_hp) + " opp_hp=" + string(obj_game.opp_hp));
            return;
        }
    } else {
        show_debug_message("[WARN] effect_hp_mod: unsupported trigger_reason=" + string(context.trigger_reason));
        return;
    }

    if (_target == "opp") {
        obj_game.opp_hp += _delta;
    } else if (_target == "player") {
        obj_game.player_hp += _delta;
    } else {
        show_debug_message("[WARN] effect_hp_mod: cannot resolve target, owner=" + string(context.owner));
        return;
    }

    show_debug_message("[Round2] hp_mod: target=" + _target
        + " delta=" + string(_delta) + " level=" + string(_level)
        + " new_hp=" + string((_target == "opp") ? obj_game.opp_hp : obj_game.player_hp));
}

function effect_score_mod(rule, context) {
    show_debug_message("[Round2] score_mod stub: owner=" + context.owner
        + " trigger=" + context.trigger_reason
        + " params=" + json_stringify(rule.effect_params)
        + " level=" + string(rule.level));
    // TODO Round 4+: if score system is revived for some rules (non-HP flow)
}

function effect_peek(rule, context) {
    show_debug_message("[Round2] peek stub: owner=" + context.owner
        + " trigger=" + context.trigger_reason
        + " params=" + json_stringify(rule.effect_params)
        + " level=" + string(rule.level));
    // TODO Round 4: trigger peek on random opp hand card, count = params.count
}

function effect_custom_matchup_stub(rule, context) {
    // Matchup traits are read by _card_beats_type during JUDGE. This handler exists
    // only so validation can dispatch judge-tagged traits without warning.
}

function effect_boost_same_name_on_play(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    if (_source == noone) return;

    var _amount = (rule.effect_params[$ "amount"] ?? 1) * rule.level;
    var _owner = context.owner;
    var _limit = (_owner == "player") ? obj_game.player_hand_limit : obj_game.opp_hand_limit;
    var _boosted = 0;
    for (var i = 0; i < _limit; i++) {
        var _card = (_owner == "player") ? obj_game.plr_hand[i] : obj_game.opp_hand[i];
        if (_card == noone || _card == _source) continue;
        if (_card.card_type == _source.card_type) {
            _card.win_damage_bonus += _amount;
            _boosted++;
        }
    }

    show_debug_message("[rule boost_same_name_on_play] owner=" + _owner
        + " type=" + string(_source.card_type)
        + " boosted=" + string(_boosted)
        + " amount=" + string(_amount));
}

function effect_peek_enemy(rule, context) {
    _peek_enemy_hand(context.owner);
}

function effect_draw_one(rule, context) {
    if (!variable_instance_exists(obj_game, "rule_draw_chain_depth")) obj_game.rule_draw_chain_depth = 0;
    if (obj_game.rule_draw_chain_depth >= 4) {
        show_debug_message("[rule draw_one] depth guard");
        return;
    }
    obj_game.rule_draw_chain_depth += 1;
    _draw_one_to_hand(context.owner);
    obj_game.rule_draw_chain_depth -= 1;
}

function effect_gain_win_damage(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    var _amount = (rule.effect_params[$ "amount"] ?? 1) * rule.level;
    _boost_card_win_damage(_source, _amount, rule.id);
}

function effect_gain_random_trait(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    _add_random_trait_to_instance(_source);
}

function effect_gain_if_beats_discarded(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    var _discarded = context[$ "discarded_card"] ?? noone;
    if (_source == noone || _discarded == noone) return;
    if (_card_beats_type(_source, _int_to_card_type_str(_discarded.card_type))) {
        var _amount = (rule.effect_params[$ "amount"] ?? 1) * rule.level;
        _boost_card_win_damage(_source, _amount, rule.id);
    }
}

function effect_gain_if_discarded_beats_self(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    var _discarded = context[$ "discarded_card"] ?? noone;
    if (_source == noone || _discarded == noone) return;
    if (_card_beats_type(_discarded, _int_to_card_type_str(_source.card_type))) {
        var _amount = (rule.effect_params[$ "amount"] ?? 1) * rule.level;
        _boost_card_win_damage(_source, _amount, rule.id);
    }
}

function effect_gain_if_same_type_discarded(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    var _discarded = context[$ "discarded_card"] ?? noone;
    if (_source == noone || _discarded == noone) return;
    if (_source.card_type == _discarded.card_type) {
        var _amount = (rule.effect_params[$ "amount"] ?? 1) * rule.level;
        _boost_card_win_damage(_source, _amount, rule.id);
    }
}

function effect_discard_route_topdeck(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    if (_source != noone) _source.discard_route_override = "draw_top";
}

function effect_return_to_deck_random(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    if (_source != noone) _source.played_route_override = "draw_random";
}

function effect_return_to_deck_top(rule, context) {
    var _source = context[$ "source_card"] ?? noone;
    if (_source != noone) _source.played_route_override = "draw_top";
}

function effect_hand_limit_bonus(rule, context) {
    // Passive: read by _owner_hand_limit.
}
