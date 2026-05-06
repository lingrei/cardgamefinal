// scr_config_enemies.gml — Round 4 enemies (D48 stage1 + D51/D54 minimal no name).
// EnemyStruct schema D54: no name/desc, only id + max_hp + deck + ai_params + sprite_id.

function enemy_b01_intro_dummy() {
    // D44: HP 3, deck 4R + 4P (无 scissors, 故意暴露"paper 永不输"赢法)
    return new EnemyStruct(
        "enemy_b01_intro_dummy",
        3,                                    // max_hp
        { rock: 4, scissors: 0, paper: 4 },   // deck: no scissors
        {
            type: "fixed_first",
            reads_discard: false,
            memory_length: 0,
            counter_threshold: 0,
            preference: {}
        },
        ""                                    // sprite_id (Round 7 polish)
    );
}

function enemy_stage1_scout() {
    // D48: HP 5, deck 3R+3P+3S 均等 9 张, 手牌 3, 0 词条
    // AI 规则 F: "被克了下回合打克玩家上回合 type 的 type" + H1 隐藏抽牌算法 (D59)
    return new EnemyStruct(
        "enemy_stage1_scout",
        5,
        { rock: 3, scissors: 3, paper: 3 },
        {
            type: "stage1_f",                  // D58: 第 1 局 fallback 随机 + 第 2 局起应用 F
            reads_discard: false,              // F 规则只依赖 last_player_play_type, 不读 discard
            memory_length: 1,                  // 记住玩家上一回合 type
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

function enemy_stage2_balanced() {
    return new EnemyStruct(
        "enemy_stage2_balanced",
        5,
        {
            rock: 3,
            scissors: 3,
            paper: 3,
            rules_by_type: { scissors: ["high_dmg_on_win"] }
        },
        {
            type: "stage1_f",
            reads_discard: false,
            memory_length: 1,
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

function enemy_stage3_rock_trainer() {
    return new EnemyStruct(
        "enemy_stage3_rock_trainer",
        4,
        {
            rock: 3,
            scissors: 3,
            paper: 3,
            rules_by_type: { rock: ["tie_dmg"] }
        },
        {
            type: "stage3_rock",
            reads_discard: false,
            memory_length: 0,
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

function enemy_stage4_paper_hoarder() {
    return new EnemyStruct(
        "enemy_stage4_paper_hoarder",
        6,
        {
            rock: 2,
            scissors: 2,
            paper: 6,
            rules_by_type: { paper: ["boost_same_name_on_play"] }
        },
        {
            type: "stage4_paper_hoarder",
            reads_discard: false,
            memory_length: 0,
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

function enemy_stage5_draw_keeper() {
    return new EnemyStruct(
        "enemy_stage5_draw_keeper",
        7,
        {
            rock: 4,
            scissors: 3,
            paper: 4,
            rules_by_type: { paper: ["return_to_deck_top"], rock: ["tie_dmg"] }
        },
        {
            type: "fixed_first",
            reads_discard: false,
            memory_length: 0,
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

function enemy_stage6_discard_duelist() {
    return new EnemyStruct(
        "enemy_stage6_discard_duelist",
        8,
        {
            rock: 4,
            scissors: 4,
            paper: 4,
            rules_by_type: { scissors: ["boost_same_name_on_play"], rock: ["feed_on_prey"] }
        },
        {
            type: "stage4_paper_hoarder",
            reads_discard: false,
            memory_length: 0,
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

function enemy_stage7_final() {
    return new EnemyStruct(
        "enemy_stage7_final",
        10,
        {
            rock: 5,
            scissors: 5,
            paper: 5,
            rules_by_type: {
                rock: ["tie_dmg", "return_to_deck"],
                scissors: ["high_dmg_on_win"],
                paper: ["boost_same_name_on_play"]
            }
        },
        {
            type: "stage1_f",
            reads_discard: false,
            memory_length: 1,
            counter_threshold: 0,
            preference: {}
        },
        ""
    );
}

/// @desc Lookup enemy template by id. Returns undefined if not found.
function _get_enemy_template_by_id(enemy_id) {
    switch (enemy_id) {
        case "enemy_b01_intro_dummy": return enemy_b01_intro_dummy();
        case "enemy_stage1_scout":   return enemy_stage1_scout();
        case "enemy_stage2_balanced": return enemy_stage2_balanced();
        case "enemy_stage3_rock_trainer":   return enemy_stage3_rock_trainer();
        case "enemy_stage4_paper_hoarder":  return enemy_stage4_paper_hoarder();
        case "enemy_stage5_draw_keeper":     return enemy_stage5_draw_keeper();
        case "enemy_stage6_discard_duelist": return enemy_stage6_discard_duelist();
        case "enemy_stage7_final":           return enemy_stage7_final();
    }
    return undefined;
}
