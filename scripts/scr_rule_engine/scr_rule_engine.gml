// Rule engine: handler registration, dispatch, validation.
// Handlers receive (rule, context) — rule gives access to level + effect_params; context gives trigger info + owner.
// HP mod uses additive model: final HP delta = default (-1 for winner's opponent) + sum(rule.level * delta_per_level).

function rule_engine_init() {
    // M2 guard: don't reset handlers if already registered (supports room_restart without losing init-once data)
    if (variable_global_exists("rule_handlers")) return;

    global.rule_handlers = {};
    global.rule_handlers.hp_mod         = effect_hp_mod;
    global.rule_handlers.score_mod      = effect_score_mod;
    global.rule_handlers.peek           = effect_peek;
    global.rule_handlers.custom_matchup = effect_custom_matchup_stub;
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
    show_debug_message("[Round2] custom_matchup stub: owner=" + context.owner
        + " trigger=" + context.trigger_reason
        + " params=" + json_stringify(rule.effect_params)
        + " level=" + string(rule.level));
    // TODO Round 4: implement matchup rewrite (Pillar 2 landing point)
}
