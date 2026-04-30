// scr_config_enemies.gml — Round 4 enemies (D44 tutorial + D48 stage1 + D51/D54 minimal no name).
// EnemyStruct schema D54: no name/desc, only id + max_hp + deck + ai_params + sprite_id.

function enemy_tutorial_dummy() {
    // D44: HP 3, deck 4R + 4P (无 scissors, 故意暴露"paper 永不输"赢法)
    return new EnemyStruct(
        "enemy_tutorial_dummy",
        3,                                    // max_hp
        { rock: 4, scissors: 0, paper: 4 },   // deck: no scissors
        {
            type: "random",                    // tutorial: AI 规则随机出
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

/// @desc Lookup enemy template by id. Returns undefined if not found.
function _get_enemy_template_by_id(enemy_id) {
    switch (enemy_id) {
        case "enemy_tutorial_dummy": return enemy_tutorial_dummy();
        case "enemy_stage1_scout":   return enemy_stage1_scout();
    }
    return undefined;
}
