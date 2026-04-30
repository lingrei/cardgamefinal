// scr_config_stages.gml — Stage configs (D36 + D44 + D48 + D55 multi-field rewards).
// Round 4 MVP: stage_tutorial + stage_1. Stage 2-6 in Round 5-6.

function sample_stage_tutorial() {
    // D44: HP 3 敌人 / deck 4R+4P 无 scissors / 词条池 = 3 条翻转克制 / 奖励 = 起始包
    return new StageStruct(
        "stage_tutorial",
        ["beat_rock", "beat_paper", "beat_scissors"],   // rule_pool: 3 基础翻转克制 (起始包抽取池)
        ["enemy_tutorial_dummy"],                         // enemies
        {
            // D55 multi-field reward: 起始包
            gold:           0,
            card_count:     0,
            card_algorithm: "none",
            item_count:     3,
            item_source:    "starter_pack_peek", // 固定 3 × peek_opp_hand
            upgrade_count:  1                      // 触发 1 次 Unified Upgrade UI
        },
        false  // has_h1 (tutorial 敌人简单, 不启用)
    );
}

function sample_stage_1() {
    // D48: HP 5 / deck 3R+3P+3S 均等 / 0 词条 / AI 规则 F + H1
    return new StageStruct(
        "stage_1",
        ["beat_rock", "beat_paper", "beat_scissors", "high_dmg_on_win", "tie_dmg"],  // 5 条低复杂度
        ["enemy_stage1_scout"],
        {
            gold:           1,
            card_count:     1,
            card_algorithm: "basic_random_rsp_rule",
            item_count:     0,
            item_source:    "",
            upgrade_count:  0
        },
        true   // has_h1: D59 enable H1 hidden draw algorithm
    );
}

/// @desc Lookup stage by id. Returns undefined if not found.
function _get_stage_by_id(stage_id) {
    switch (stage_id) {
        case "stage_tutorial": return sample_stage_tutorial();
        case "stage_1":        return sample_stage_1();
    }
    return undefined;
}

/// @desc Pick a random enemy id from a stage's enemies pool.
function _pick_enemy_from_stage(stage) {
    var _n = array_length(stage.enemies);
    if (_n == 0) return undefined;
    return stage.enemies[irandom(_n - 1)];
}
