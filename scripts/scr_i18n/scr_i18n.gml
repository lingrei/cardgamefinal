// scr_i18n.gml — i18n infrastructure (D30).
// global.i18n_dict[language][key] = translated string
// Call i18n_init() once in obj_game Create, before any UI draw.

function i18n_init() {
    global.current_language = "zh"; // Default, overridden by settings_load() if available
    global.i18n_dict = {
        zh: {},
        en: {}
    };

    // Rule descriptions (11 — D51 only desc, no name)
    _i18n_set("rule_beat_rock_desc",         "这张牌对石头也能赢。",                              "This card also beats rock.");
    _i18n_set("rule_beat_paper_desc",        "这张牌对布也能赢。",                                "This card also beats paper.");
    _i18n_set("rule_beat_scissors_desc",     "这张牌对剪刀也能赢。",                              "This card also beats scissors.");
    _i18n_set("rule_high_dmg_on_win_desc",   "胜利时额外造成 1 点伤害, 每级叠加。",                "On win, deal 1 extra damage per level.");
    _i18n_set("rule_draw_plus_next_turn_desc","出牌后, 下回合多抽 1 张牌。",                       "Next turn, draw 1 extra card.");
    _i18n_set("rule_tie_dmg_desc",           "平局时, 对手受到 1 点伤害。",                       "On tie, opponent takes 1 damage.");
    _i18n_set("rule_win_gives_item_desc",    "胜利时获得一个随机道具。",                          "On win, gain 1 random item.");
    _i18n_set("rule_return_to_deck_desc",    "出牌后, 重新洗回自己的牌堆。",                      "This card shuffles back into your deck after play.");
    _i18n_set("rule_return_to_deck_top_desc","出牌后, 回到自己牌堆的顶上。",                      "This card returns to the top of your deck after play.");
    _i18n_set("rule_power_with_usage_desc",  "这张牌每被打出一次, 下次获胜时伤害 +1, 可叠加。",    "This card's win damage grows by 1 each time it's played.");
    _i18n_set("rule_escalating_damage_desc", "这张牌每赢一局, 下次获胜时伤害 +1, 可叠加。",        "This card's win damage grows by 1 each time it wins.");

    // Item descriptions (10 — D51 only desc, no name)
    _i18n_set("item_peek_opp_hand_desc",          "随机翻开敌人 1 张牌。",                        "Reveal 1 random enemy card.");
    _i18n_set("item_draw_extra_desc",             "立即多抽 1 张牌。",                             "Draw 1 extra card this turn.");
    _i18n_set("item_force_opp_replay_desc",       "替换对手已出的牌：从对手手牌中点击 1 张, 强制改为出这张, 该卡永久公开。", "Swap opp's played card with one you pick from their hand. Chosen card is permanently revealed.");
    _i18n_set("item_discard_own_hand_desc",       "弃掉 1 张手牌, 本场不再出现。",                "Discard 1 hand card; it's gone for this battle.");
    _i18n_set("item_steal_from_opp_discard_desc", "从对手弃牌堆拿 1 张到手牌。",                  "Take 1 card from enemy's discard.");
    _i18n_set("item_recover_from_own_discard_desc","从自己弃牌堆拿回 1 张牌。",                    "Take 1 card from your own discard.");
    _i18n_set("item_scry_top_3_desc",             "查看自己牌堆顶 3 张, 选 1 张加入手牌。",       "Look at the top 3 of your deck and take 1 into your hand.");
    _i18n_set("item_reveal_opp_hand_types_desc",  "查看对手的牌型。",                              "Reveal all enemy cards.");
    _i18n_set("item_immune_this_round_desc",      "本回合不受伤害。",                              "Immune to damage this round.");
    _i18n_set("item_mulligan_desc",               "弃掉所有手牌, 重新抽 3 张。",                   "Discard your hand and draw 3 new cards.");

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
    _i18n_set("ui_replay_tutorial",  "重玩教程",     "REPLAY TUTORIAL");
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
