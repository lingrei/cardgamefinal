// Seven-battle route stage configs. StageStruct is kept as the current engine
// container; ids use level_bXX_* names from the design docs.

function _reward(_gold, _card_count, _card_algo, _upgrade_count, _relic_choice_count) {
    return {
        gold: _gold,
        card_count: _card_count,
        card_algorithm: _card_algo,
        upgrade_count: _upgrade_count,
        relic_choice_count: _relic_choice_count
    };
}

function level_b01_intro() {
    return new StageStruct(
        "level_b01_intro",
        ["beat_rock", "beat_paper", "beat_scissors"],
        ["enemy_b01_intro_dummy"],
        _reward(0, 0, "none", 1, 0),
        false,
        { hand_limit_delta_both: 0 }
    );
}

function level_b02_default() {
    return new StageStruct(
        "level_b02_default",
        ["beat_rock", "beat_paper", "beat_scissors", "high_dmg_on_win", "tie_dmg", "discard_peek_enemy", "draw_peek_enemy", "discard_draw_one"],
        ["enemy_stage2_balanced"],
        _reward(1, 1, "basic_random_rsp_rule", 0, 3),
        true,
        { hand_limit_delta_both: 0 }
    );
}

function level_b03_rock_trainer() {
    return new StageStruct(
        "level_b03_rock_trainer",
        ["beat_rock", "beat_paper", "beat_scissors", "high_dmg_on_win", "tie_dmg", "return_to_deck", "return_to_deck_top"],
        ["enemy_stage3_rock_trainer"],
        _reward(1, 1, "basic_random_rsp_rule", 0, 0),
        false,
        { hand_limit_delta_both: 0 }
    );
}

function level_b04_paper_hoarder() {
    return new StageStruct(
        "level_b04_paper_hoarder",
        ["beat_rock", "beat_paper", "beat_scissors", "high_dmg_on_win", "tie_dmg", "boost_same_name_on_play", "same_type_fuel", "held_discard_peek_enemy"],
        ["enemy_stage4_paper_hoarder"],
        _reward(1, 1, "basic_random_rsp_rule", 0, 3),
        false,
        { hand_limit_delta_both: 1 }
    );
}

function level_b05_default() {
    return new StageStruct(
        "level_b05_default",
        ["discard_peek_enemy", "draw_peek_enemy", "discard_draw_one", "draw_chain_one", "held_start_peek_enemy", "held_refill_limit_plus_one", "held_win_damage_growth", "return_to_deck", "return_to_deck_top", "discard_to_topdeck"],
        ["enemy_stage5_draw_keeper"],
        _reward(2, 1, "basic_random_rsp_rule", 0, 0),
        false,
        { hand_limit_delta_both: 0 }
    );
}

function level_b06_default() {
    return new StageStruct(
        "level_b06_default",
        ["feed_on_prey", "shed_weakness", "same_type_fuel", "any_active_discard_growth", "held_random_trait", "boost_same_name_on_play", "high_dmg_on_win", "tie_dmg"],
        ["enemy_stage6_discard_duelist"],
        _reward(2, 1, "basic_random_rsp_rule", 1, 0),
        false,
        { hand_limit_delta_both: 0 }
    );
}

function level_b07_final() {
    return new StageStruct(
        "level_b07_final",
        _get_all_rule_ids(),
        ["enemy_stage7_final"],
        _reward(3, 1, "basic_random_rsp_rule", 1, 0),
        true,
        { hand_limit_delta_both: 1 }
    );
}

function _get_stage_by_id(stage_id) {
    switch (stage_id) {
        case "level_b01_intro":
        case "stage_1":                 return level_b01_intro();
        case "level_b02_default":        return level_b02_default();
        case "level_b03_rock_trainer":
        case "stage_3":                 return level_b03_rock_trainer();
        case "level_b04_paper_hoarder":
        case "stage_4":                 return level_b04_paper_hoarder();
        case "level_b05_default":        return level_b05_default();
        case "level_b06_default":        return level_b06_default();
        case "level_b07_final":          return level_b07_final();
    }
    return undefined;
}

function _pick_enemy_from_stage(stage) {
    var _n = array_length(stage.enemies);
    if (_n == 0) return undefined;
    return stage.enemies[0];
}
