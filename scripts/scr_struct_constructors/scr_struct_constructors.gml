// Struct constructors for cards, rules, enemies, relics, nodes, branches, run state, stages.
// All config-level structs are pure data (json_stringify-safe, no instance references).
// Runtime struct (RunStateStruct) may hold instance refs — not serializable.
// Round 4 updates: D51 minimal naming (no name/desc on Item/Enemy/Card),
//                  D54 敌人 minimal, D55 StageStruct multi-field rewards, D49 Rule/Item cost.

// ===== Config structs =====

function CardStruct(_type_name, _rules) constructor {
    // D33 + D51: 卡无名字, 身份 = type sprite + 词条 icon
    type_name = _type_name;   // "rock" | "scissors" | "paper"
    rules = _rules;            // Array<RuleStruct>
}

function RuleStruct(_id, _trigger, _effect_type, _effect_params, _description_text, _icon_sprite, _tag, _max_level, _cost) constructor {
    // D51: 无 name, 只 description_text (i18n key) + icon_sprite
    id = _id;
    trigger = _trigger;
    effect_type = _effect_type;
    effect_params = _effect_params;
    description_text = _description_text;  // i18n key
    icon_sprite = _icon_sprite;
    tag = _tag;
    max_level = _max_level;
    cost = _cost;              // D49: Shop 购买金币 + 奖励价值度量
    level = 1;                 // Runtime: newly instantiated rules level 1
}

function EnemyStruct(_id, _max_hp, _deck_composition, _ai_params, _sprite_id) constructor {
    // D54: 无 name/desc, 身份 = id + sprite_id + stage 序列
    id = _id;
    sprite_id = _sprite_id;
    max_hp = _max_hp;
    deck_composition = _deck_composition;
    ai_params = _ai_params;           // Struct: { type: "random" | "stage1_f", ... }
}

function ItemStruct(_id, _effect_type, _effect_params, _cost, _max_charges, _icon_sprite, _description_text) constructor {
    // D51: 无 name, 只 description_text (i18n key)
    id = _id;
    icon_sprite = _icon_sprite;
    description_text = _description_text;  // i18n key
    effect_type = _effect_type;
    effect_params = _effect_params;
    cost = _cost;
    max_charges = _max_charges;
    current_charges = _max_charges;
}

function RelicStruct(_id, _display_text, _description_text, _icon_id, _route_tag, _cost) constructor {
    id = _id;
    display_text = _display_text;          // i18n key
    description_text = _description_text;  // i18n key
    icon_id = _icon_id;
    route_tag = _route_tag;
    cost = _cost;
    pulse_timer = 0;                       // runtime UI feedback
}

function StageStruct(_id, _rule_pool, _enemies, _rewards, _has_h1, _mechanics) constructor {
    // D55: 多字段 reward 组合
    // _rewards struct fields: gold, card_count, card_algorithm, upgrade_count, relic_choice_count
    id = _id;
    rule_pool = _rule_pool;
    enemies = _enemies;
    rewards = _rewards;
    has_h1 = _has_h1;                // D59: enable H1 hidden draw
    mechanics = _mechanics;          // MVP: { hand_limit_delta_both }
}

// Round 2 new: Run map nodes, branches, run state

function NodeStruct(_type, _payload) constructor {
    // type: "battle" | "shop" | "rest" | "event" | "remove" | "branch_marker"
    // payload: battle = { stage_id } (D55)
    type = _type;
    payload = _payload;
}

function BranchStruct(_id, _line_a_nodes, _line_b_nodes) constructor {
    id = _id;
    line_a_nodes = _line_a_nodes;
    line_b_nodes = _line_b_nodes;
}

function RunStateStruct() constructor {
    // Run progress
    map = [];
    map_position = 0;
    current_battle_index = 0;
    current_stage_id = "";          // D55: current stage id (used for rule_pool / reward lookup)

    // HP (D49 revised 2026-04-26: player starts at 5, was 10)
    player_hp = 5;
    player_max_hp = 5;
    opp_hp = 0;
    opp_max_hp = 0;

    // Resources
    gold = 0;
    relics = [];

    // Deck (config layer)
    player_deck = [];

    // Branch selection (only meaningful between RUN_MAP_BRANCH and BATTLE_START)
    current_branch_line = "";
    current_branch_sub_index = 0;
}
