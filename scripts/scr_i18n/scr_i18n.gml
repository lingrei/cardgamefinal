// scr_i18n.gml — i18n infrastructure (D30).
// global.i18n_dict[language][key] = translated string
// Call i18n_init() once in obj_game Create, before any UI draw.

function i18n_init() {
    global.current_language = "en"; // Default, overridden by settings_load() if available
    global.i18n_dict = {
        zh: {},
        en: {}
    };

    // Rule descriptions (11 — D51 only desc, no name)
    _i18n_set("rule_beat_rock_desc",         "这张牌对石头也能赢。",                              "This card also beats rock.");
    _i18n_set("rule_beat_paper_desc",        "这张牌对布也能赢。",                                "This card also beats paper.");
    _i18n_set("rule_beat_scissors_desc",     "这张牌对剪刀也能赢。",                              "This card also beats scissors.");
    _i18n_set("rule_high_dmg_on_win_desc",   "胜利时额外造成 1 点伤害, 每级叠加。",                "On win, deal 1 extra damage per level.");
    _i18n_set("rule_tie_dmg_desc",           "平局时, 对手受到 1 点伤害。",                       "On tie, opponent takes 1 damage.");
    _i18n_set("rule_return_to_deck_desc",    "出牌后, 重新洗回自己的牌堆。",                      "This card shuffles back into your deck after play.");
    _i18n_set("rule_return_to_deck_top_desc","出牌后, 回到自己牌堆的顶上。",                      "This card returns to the top of your deck after play.");
_i18n_set("rule_boost_same_name_on_play_desc", "打出时, 其余同名手牌获胜伤害 +1。", "On play, other same-name hand cards gain +1 win damage.");

    // Current MVP trait names/descriptions. ASCII fallback keeps HTML export readable until a TTF UI font lands.
    _i18n_set("rule_unknown_name", "Unknown", "Unknown");
    _i18n_set("rule_unknown_desc", "Unknown effect.", "Unknown effect.");
    _i18n_set("rule_beat_rock_name", "Can Beat Rock", "Can Beat Rock");
    _i18n_set("rule_beat_rock_desc", "Can also beat Rock. If both cards can beat each other, the duel is a tie.", "Can also beat Rock. If both cards can beat each other, the duel is a tie.");
    _i18n_set("rule_beat_paper_name", "Can Beat Paper", "Can Beat Paper");
    _i18n_set("rule_beat_paper_desc", "Can also beat Paper. If both cards can beat each other, the duel is a tie.", "Can also beat Paper. If both cards can beat each other, the duel is a tie.");
    _i18n_set("rule_beat_scissors_name", "Can Beat Scissors", "Can Beat Scissors");
    _i18n_set("rule_beat_scissors_desc", "Can also beat Scissors. If both cards can beat each other, the duel is a tie.", "Can also beat Scissors. If both cards can beat each other, the duel is a tie.");
    _i18n_set("rule_high_dmg_on_win_name", "Win +1", "Win +1");
    _i18n_set("rule_high_dmg_on_win_desc", "On win, deal +1 damage per level.", "On win, deal +1 damage per level.");
    _i18n_set("rule_tie_dmg_name", "Tie Scratch", "Tie Scratch");
    _i18n_set("rule_tie_dmg_desc", "On tie, deal 1 damage.", "On tie, deal 1 damage.");
    _i18n_set("rule_boost_same_name_on_play_name", "Echo Hand", "Echo Hand");
    _i18n_set("rule_boost_same_name_on_play_desc", "When played, other same-type hand cards gain +1 damage.", "When played, other same-type hand cards gain +1 damage.");
    _i18n_set("rule_return_to_deck_name", "Return", "Return");
    _i18n_set("rule_return_to_deck_desc", "After play, shuffle this card back into your deck.", "After play, shuffle this card back into your deck.");
    _i18n_set("rule_return_to_deck_top_name", "Top Return", "Top Return");
    _i18n_set("rule_return_to_deck_top_desc", "After play, put this card on top of your deck.", "After play, put this card on top of your deck.");
    _i18n_set("rule_discard_peek_enemy_name", "Discard Peek", "Discard Peek");
    _i18n_set("rule_discard_peek_enemy_desc", "When discarded, reveal 1 enemy hand card.", "When discarded, reveal 1 enemy hand card.");
    _i18n_set("rule_draw_peek_enemy_name", "Draw Peek", "Draw Peek");
    _i18n_set("rule_draw_peek_enemy_desc", "When drawn, reveal 1 enemy hand card.", "When drawn, reveal 1 enemy hand card.");
    _i18n_set("rule_held_start_peek_enemy_name", "Held Eye", "Held Eye");
    _i18n_set("rule_held_start_peek_enemy_desc", "At turn start while held, reveal 1 enemy hand card.", "At turn start while held, reveal 1 enemy hand card.");
    _i18n_set("rule_held_discard_peek_enemy_name", "Watch Discard", "Watch Discard");
    _i18n_set("rule_held_discard_peek_enemy_desc", "While held, when you discard another card, reveal 1 enemy hand card.", "While held, when you discard another card, reveal 1 enemy hand card.");
    _i18n_set("rule_discard_draw_one_name", "Discard Draw", "Discard Draw");
    _i18n_set("rule_discard_draw_one_desc", "When discarded, draw 1 card.", "When discarded, draw 1 card.");
    _i18n_set("rule_draw_chain_one_name", "Draw Chain", "Draw Chain");
    _i18n_set("rule_draw_chain_one_desc", "When drawn, draw 1 extra card.", "When drawn, draw 1 extra card.");
    _i18n_set("rule_held_refill_limit_plus_one_name", "Wide Hand", "Wide Hand");
    _i18n_set("rule_held_refill_limit_plus_one_desc", "While held, refill limit is +1.", "While held, refill limit is +1.");
    _i18n_set("rule_held_win_damage_growth_name", "Seasoned", "Seasoned");
    _i18n_set("rule_held_win_damage_growth_desc", "Each turn held, this card gains +1 damage.", "Each turn held, this card gains +1 damage.");
    _i18n_set("rule_any_active_discard_growth_name", "Discard Hunger", "Discard Hunger");
    _i18n_set("rule_any_active_discard_growth_desc", "While held, any active discard gives this card +1 damage.", "While held, any active discard gives this card +1 damage.");
    _i18n_set("rule_held_random_trait_name", "Ink Bloom", "Ink Bloom");
    _i18n_set("rule_held_random_trait_desc", "At turn start while held, gain 1 random trait.", "At turn start while held, gain 1 random trait.");
    _i18n_set("rule_feed_on_prey_name", "Feed", "Feed");
    _i18n_set("rule_feed_on_prey_desc", "When you discard a card this beats, gain +1 damage.", "When you discard a card this beats, gain +1 damage.");
    _i18n_set("rule_shed_weakness_name", "Shed", "Shed");
    _i18n_set("rule_shed_weakness_desc", "When you discard a card that beats this, gain +1 damage.", "When you discard a card that beats this, gain +1 damage.");
    _i18n_set("rule_same_type_fuel_name", "Same Fuel", "Same Fuel");
    _i18n_set("rule_same_type_fuel_desc", "When you discard a same-type card, gain +1 damage.", "When you discard a same-type card, gain +1 damage.");
    _i18n_set("rule_discard_to_topdeck_name", "Topdeck", "Topdeck");
    _i18n_set("rule_discard_to_topdeck_desc", "When discarded, put this card on top of your deck instead.", "When discarded, put this card on top of your deck instead.");

    _i18n_set("relic_unknown_name", "Unknown Relic", "Unknown Relic");
    _i18n_set("relic_unknown_desc", "Unknown relic.", "Unknown relic.");
    _i18n_set("relic_ember_furnace_name", "Ember Furnace", "Ember Furnace");
    _i18n_set("relic_ember_furnace_desc", "After your first discard each turn, the next card that beats it gains +2 damage.", "After your first discard each turn, the next card that beats it gains +2 damage.");
    _i18n_set("relic_ballast_stone_name", "Ballast Stone", "Ballast Stone");
    _i18n_set("relic_ballast_stone_desc", "At turn start, your longest-held hand card gains +1 damage. It also deals 1 on tie.", "At turn start, your longest-held hand card gains +1 damage. It also deals 1 on tie.");
    _i18n_set("relic_copy_seal_name", "Copy Seal", "Copy Seal");
    _i18n_set("relic_copy_seal_desc", "When you play a card, each same-type hand card gives it +1 damage.", "When you play a card, each same-type hand card gives it +1 damage.");
    _i18n_set("relic_shuffle_funnel_name", "Shuffle Funnel", "Shuffle Funnel");
    _i18n_set("relic_shuffle_funnel_desc", "Your first discard each turn draws 1 card.", "Your first discard each turn draws 1 card.");
    _i18n_set("relic_cold_box_name", "Cold Box", "Cold Box");
    _i18n_set("relic_cold_box_desc", "Once per battle per card, after 2 held turns, gain 1 trait.", "Once per battle per card, after 2 held turns, gain 1 trait.");
    _i18n_set("relic_predator_totem_name", "Predator Totem", "Predator Totem");
    _i18n_set("relic_predator_totem_desc", "When you discard a card, hand cards that beat it gain +1 damage.", "When you discard a card, hand cards that beat it gain +1 damage.");
    _i18n_set("relic_observation_mirror_name", "Observation Mirror", "Observation Mirror");
    _i18n_set("relic_observation_mirror_desc", "Whenever you reveal enemy hand cards, a random hand card gains +1 damage.", "Whenever you reveal enemy hand cards, a random hand card gains +1 damage.");
    _i18n_set("relic_buffer_ring_name", "Buffer Ring", "Buffer Ring");
    _i18n_set("relic_buffer_ring_desc", "Ties trigger win effects, but deal no duel damage.", "Ties trigger win effects, but deal no duel damage.");
    _i18n_set("relic_tri_compass_name", "Tri-Compass", "Tri-Compass");
    _i18n_set("relic_tri_compass_desc", "If your hand has Rock, Scissors, and Paper, your played card gains +1 damage.", "If your hand has Rock, Scissors, and Paper, your played card gains +1 damage.");
    _i18n_set("relic_lone_blade_name", "Lone Blade", "Lone Blade");
    _i18n_set("relic_lone_blade_desc", "If you play the only hand card of its type, it gains +2 damage.", "If you play the only hand card of its type, it gains +2 damage.");
    _i18n_set("relic_zealot_mask_name", "Zealot Mask", "Zealot Mask");
    _i18n_set("relic_zealot_mask_desc", "At battle start, your most common card type gains +1 damage.", "At battle start, your most common card type gains +1 damage.");
    _i18n_set("relic_balance_scales_name", "Balance Scales", "Balance Scales");
    _i18n_set("relic_balance_scales_desc", "At battle start, your least common card type gains +2 damage.", "At battle start, your least common card type gains +2 damage.");
    _i18n_set("relic_backlight_lamp_name", "Backlight Lamp", "Backlight Lamp");
    _i18n_set("relic_backlight_lamp_desc", "When the enemy plays a card you had seen, your card gains +2 damage.", "When the enemy plays a card you had seen, your card gains +2 damage.");
    _i18n_set("relic_blind_die_name", "Blind Die", "Blind Die");
    _i18n_set("relic_blind_die_desc", "When you beat an unseen enemy card, gain +2 damage.", "When you beat an unseen enemy card, gain +2 damage.");
    _i18n_set("relic_lag_clock_name", "Lag Clock", "Lag Clock");
    _i18n_set("relic_lag_clock_desc", "At turn end, if you did not discard, all hand cards gain +1 damage.", "At turn end, if you did not discard, all hand cards gain +1 damage.");
    _i18n_set("relic_card_spark_name", "Card Spark", "Card Spark");
    _i18n_set("relic_card_spark_desc", "Your first discard each turn gives a random hand card +1 damage.", "Your first discard each turn gives a random hand card +1 damage.");
    _i18n_set("relic_protective_knot_name", "Protective Knot", "Protective Knot");
    _i18n_set("relic_protective_knot_desc", "Once per battle, your first loss becomes a tie.", "Once per battle, your first loss becomes a tie.");

    // UI common words (D51 保留)
    _i18n_set("ui_shop",         "商店",  "SHOP");
    _i18n_set("ui_rest",         "休息",  "REST");
    _i18n_set("ui_event",        "事件",  "EVENT");
    _i18n_set("ui_remove",       "移除",  "REMOVE");
    _i18n_set("ui_battle",       "战斗",  "BATTLE");
    _i18n_set("ui_reward",       "奖励",  "REWARD");
    _i18n_set("ui_duel",         "对决",  "DUEL");
    _i18n_set("ui_confirm",      "确认",  "CONFIRM");
    _i18n_set("ui_cancel",       "取消",  "CANCEL");
    _i18n_set("ui_skip",         "跳过",  "SKIP");
    _i18n_set("ui_heal",         "回血",  "HEAL");
    _i18n_set("ui_upgrade",      "升级",  "UPGRADE");
    _i18n_set("ui_continue",     "继续",  "CONTINUE");
    _i18n_set("ui_retry",        "重来",  "RETRY");
    _i18n_set("ui_settings",     "设置",  "SETTINGS");
    _i18n_set("ui_deck",         "牌堆",  "DECK");
    _i18n_set("ui_hand",         "手牌",  "HAND");
    _i18n_set("ui_discard",      "弃牌",  "DISCARD");
    _i18n_set("ui_hp",           "血量",  "HP");
    _i18n_set("ui_gold",         "金币",  "GOLD");
    _i18n_set("ui_run_victory",  "胜利",  "VICTORY");
    _i18n_set("ui_run_defeat",   "失败",  "DEFEAT");
    _i18n_set("ui_title",        "主菜单","TITLE");
    _i18n_set("ui_enemy",        "敌人",  "ENEMY");

    // Phase 1 Batch 5 (D1/D2/D3) — settings + pause UI keys.
    _i18n_set("ui_pause",            "暂停",         "PAUSED");
    _i18n_set("ui_resume",           "继续游戏",     "RESUME");
    _i18n_set("ui_quit_to_title",    "返回主菜单",   "QUIT TO TITLE");
    _i18n_set("ui_volume_master",    "主音量",       "MASTER VOLUME");
    _i18n_set("ui_volume_sfx",       "音效",         "SFX VOLUME");
    _i18n_set("ui_volume_music",     "音乐",         "MUSIC VOLUME");
    _i18n_set("ui_fullscreen",       "全屏",         "FULLSCREEN");
    _i18n_set("ui_language",         "语言",         "LANGUAGE");
    _i18n_set("ui_on",               "开",           "ON");
    _i18n_set("ui_off",              "关",           "OFF");
    _i18n_set("ui_close",            "关闭",         "CLOSE");
}

function _i18n_set(key, zh_text, en_text) {
    global.i18n_dict.zh[$ key] = zh_text;
    global.i18n_dict.en[$ key] = en_text;
}

/// @desc Translate a key to current-language string. Returns "[missing: KEY]" if key absent.
function _t(key) {
    var _dict = global.i18n_dict[$ global.current_language];
    if (is_undefined(_dict)) return "[missing lang]";
    var _v = _dict[$ key];
    if (is_undefined(_v)) return "[missing: " + string(key) + "]";
    return _v;
}

function _set_language(lang) {
    if (lang == "zh" || lang == "en") {
        global.current_language = lang;
    }
}
