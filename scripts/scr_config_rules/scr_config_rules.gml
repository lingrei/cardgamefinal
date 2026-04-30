// scr_config_rules.gml — 11 rule templates (Round 4, D49 cost + D39 implicit rules + D51 no name).
// All rules use description_text as i18n key.
// Legal target logic: use _enumerate_legal_targets + _card_has_implicit_rule helpers.

// ===== 11 rule templates (D51: id / trigger / effect_type / effect_params / desc_key / icon / tag / max_level / cost) =====

function rule_beat_rock()        { return new RuleStruct("beat_rock",        "judge",     "custom_matchup",        { target_type: "rock" },     "rule_beat_rock_desc",         "", "matchup", 1, 2); }
function rule_beat_paper()       { return new RuleStruct("beat_paper",       "judge",     "custom_matchup",        { target_type: "paper" },    "rule_beat_paper_desc",        "", "matchup", 1, 2); }
function rule_beat_scissors()    { return new RuleStruct("beat_scissors",    "judge",     "custom_matchup",        { target_type: "scissors" }, "rule_beat_scissors_desc",     "", "matchup", 1, 2); }
function rule_high_dmg_on_win()  { return new RuleStruct("high_dmg_on_win",  "on_win",    "hp_mod",                { delta_per_level: -1 },     "rule_high_dmg_on_win_desc",   "", "dmg",     2, 2); }
function rule_draw_plus_next()   { return new RuleStruct("draw_plus_next_turn","on_play", "next_turn_draw_bonus",  { bonus: 1 },                "rule_draw_plus_next_turn_desc","", "draw",   1, 3); }
function rule_tie_dmg()          { return new RuleStruct("tie_dmg",          "on_tie",    "hp_mod",                { delta: -1, tie_target: "opp" }, "rule_tie_dmg_desc",     "", "dmg",     1, 2); }
function rule_win_gives_item()   { return new RuleStruct("win_gives_item",   "on_win",    "grant_random_item",     {},                          "rule_win_gives_item_desc",    "", "produce", 1, 3); }
function rule_return_to_deck()   { return new RuleStruct("return_to_deck",   "on_played", "return_to_deck_random", {},                          "rule_return_to_deck_desc",    "", "deck",    1, 3); }
function rule_return_to_top()    { return new RuleStruct("return_to_deck_top","on_played","return_to_deck_top",    {},                          "rule_return_to_deck_top_desc","", "deck",    1, 3); }
function rule_power_with_usage() { return new RuleStruct("power_with_usage", "passive",   "boost_per_local_use",   { bonus_per_use: 1 },        "rule_power_with_usage_desc",  "", "stack",   1, 4); }
function rule_escalating_damage(){ return new RuleStruct("escalating_damage","on_win",    "escalating_damage",     { per_win_bonus: 1 },        "rule_escalating_damage_desc", "", "stack",   1, 4); }

/// @desc Get rule template by id. Returns undefined if not found.
function _get_rule_template_by_id(rule_id) {
    switch (rule_id) {
        case "beat_rock":           return rule_beat_rock();
        case "beat_paper":          return rule_beat_paper();
        case "beat_scissors":       return rule_beat_scissors();
        case "high_dmg_on_win":     return rule_high_dmg_on_win();
        case "draw_plus_next_turn": return rule_draw_plus_next();
        case "tie_dmg":             return rule_tie_dmg();
        case "win_gives_item":      return rule_win_gives_item();
        case "return_to_deck":      return rule_return_to_deck();
        case "return_to_deck_top":  return rule_return_to_top();
        case "power_with_usage":    return rule_power_with_usage();
        case "escalating_damage":   return rule_escalating_damage();
    }
    return undefined;
}

// ===== D39 implicit rules =====
// rock 自带 beat_scissors / scissors 自带 beat_paper / paper 自带 beat_rock

/// @desc Check if a card_type string has the given rule implicitly.
/// @param card_type_name String "rock" | "paper" | "scissors"
/// @param rule_id String
function _card_has_implicit_rule(card_type_name, rule_id) {
    if (card_type_name == "rock"     && rule_id == "beat_scissors") return true;
    if (card_type_name == "scissors" && rule_id == "beat_paper")    return true;
    if (card_type_name == "paper"    && rule_id == "beat_rock")     return true;
    return false;
}

// ===== D47 helper: type that beats T (standard RPS) =====
// Used by Stage 1 AI rule F: "opponent plays type that beats player's last type"

/// @desc Returns the card_type_name that beats given type. rock->paper / paper->scissors / scissors->rock.
function _get_type_that_beats(card_type_name) {
    if (card_type_name == "rock")     return "paper";
    if (card_type_name == "paper")    return "scissors";
    if (card_type_name == "scissors") return "rock";
    return "rock"; // fallback
}

// ===== Legal target enumeration (D39 + §3.4.1 border B) =====

/// @desc Check if a rule can legally be placed on a card instance (considering implicit rules + max_level).
/// @param rule_template RuleStruct (template, not instance — checks id/max_level)
/// @param card CardStruct (config layer) OR card instance (has type_name + rules)
function _is_legal_target(rule_template, card) {
    // Get card's type name (support both CardStruct and obj_card instance)
    var _type_name = "";
    if (variable_struct_exists(card, "type_name")) {
        _type_name = card.type_name;
    } else if (variable_instance_exists(card, "card_type")) {
        // obj_card instance: card_type Int 0=rock 1=scissors 2=paper
        var _ct = card.card_type;
        if (_ct == 0) _type_name = "rock";
        else if (_ct == 1) _type_name = "scissors";
        else if (_ct == 2) _type_name = "paper";
    }

    // D39: custom_matchup rule cannot target a card that already implicitly beats that type
    if (rule_template.effect_type == "custom_matchup") {
        var _target = rule_template.effect_params.target_type;
        var _implicit_rule_id = "beat_" + _target;
        if (_card_has_implicit_rule(_type_name, _implicit_rule_id)) {
            return false; // already implicitly has this rule
        }
    }

    // Check if card already has this rule at max_level
    var _existing = card.rules;
    if (!is_array(_existing)) _existing = [];
    for (var i = 0; i < array_length(_existing); i++) {
        var _r = _existing[i];
        if (_r.id == rule_template.id) {
            if (_r.level >= rule_template.max_level) {
                return false; // already at max level
            }
            // Otherwise legal (will upgrade)
        }
    }

    return true;
}

/// @desc Enumerate all legal (rule_template, card) combos given a rule_pool and player's deck.
/// @param rule_pool Array<rule_id String> — e.g., stage.rule_pool
/// @param player_deck Array<CardStruct or card instance>
/// @return Array<{rule, card}> — all legal combos
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
