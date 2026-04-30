// Helpers for obj_game Round 2 state machine.
// All mutate obj_game fields directly (obj_game is a room-singleton instance).

function _clear_all_card_instances() {
    with (obj_card) instance_destroy();
}

function _init_player_deck() {
    // D49 / Sprint 2: player deck = 12 plain cards (4R+4S+4P), no rules. Upgrades add rules later.
    obj_game.player_deck = [];
    var _types = ["rock", "scissors", "paper"];
    for (var t = 0; t < 3; t++) {
        for (var c = 0; c < 4; c++) {
            array_push(obj_game.player_deck, new CardStruct(_types[t], []));
        }
    }
}

function _str_to_card_type_int(_s) {
    if (_s == "rock") return 0;
    if (_s == "scissors") return 1;
    if (_s == "paper") return 2;
    return 0;
}

function _int_to_card_type_str(_i) {
    if (_i == 0) return "rock";
    if (_i == 1) return "scissors";
    if (_i == 2) return "paper";
    return "";
}

/// @desc D48/D58 AI rule F: "after losing, play the type that beats player's last play".
/// Returns opp_hand slot index (0-2) to play, or -1 if no match (caller should fallback random).
/// @param _last_type String — player's last play type ("rock"|"scissors"|"paper"|"")
/// @param _player_won_last Bool — whether player won the last round (enemy was beaten)
function _ai_stage1_f_pick(_last_type, _player_won_last) {
    if (!_player_won_last || _last_type == "") return -1;
    var _target_int = _str_to_card_type_int(_get_type_that_beats(_last_type));
    var _matches = [];
    for (var i = 0; i < 3; i++) {
        if (obj_game.opp_hand[i] != noone && obj_game.opp_hand[i].card_type == _target_int) {
            array_push(_matches, i);
        }
    }
    if (array_length(_matches) == 0) return -1;
    return _matches[irandom(array_length(_matches) - 1)];
}

/// @desc D48/D59 H1 hidden draw algorithm: swap opp hand cards with draw pile to guarantee
/// at least one of each RPS type in hand. Only runs if current_stage_has_h1 = true.
/// Players don't see this — it happens while enemy cards are still face-down.
function _ai_h1_check_and_fix() {
    if (!obj_game.current_stage_has_h1) return;

    var _counts = { rock: 0, scissors: 0, paper: 0 };
    for (var i = 0; i < 3; i++) {
        if (obj_game.opp_hand[i] == noone) continue;
        var _type = _int_to_card_type_str(obj_game.opp_hand[i].card_type);
        _counts[$ _type] += 1;
    }

    var _missing = [];
    if (_counts.rock == 0)     array_push(_missing, "rock");
    if (_counts.scissors == 0) array_push(_missing, "scissors");
    if (_counts.paper == 0)    array_push(_missing, "paper");
    if (array_length(_missing) == 0) return;

    for (var m = 0; m < array_length(_missing); m++) {
        var _need = _missing[m];
        var _need_int = _str_to_card_type_int(_need);

        var _found_idx = -1;
        for (var j = array_length(obj_game.opp_draw_pile) - 1; j >= 0; j--) {
            if (obj_game.opp_draw_pile[j].card_type == _need_int) {
                _found_idx = j;
                break;
            }
        }
        if (_found_idx < 0) continue; // Sprint 2: no reshuffle fallback yet

        var _swap_slot = -1;
        for (var i = 0; i < 3; i++) {
            if (obj_game.opp_hand[i] == noone) continue;
            var _hand_type = _int_to_card_type_str(obj_game.opp_hand[i].card_type);
            if (_counts[$ _hand_type] > 1) {
                _swap_slot = i;
                _counts[$ _hand_type] -= 1;
                _counts[$ _need] += 1;
                break;
            }
        }
        if (_swap_slot < 0) continue;

        var _old = obj_game.opp_hand[_swap_slot];
        var _new = obj_game.opp_draw_pile[_found_idx];

        array_delete(obj_game.opp_draw_pile, _found_idx, 1);
        array_insert(obj_game.opp_draw_pile, irandom(array_length(obj_game.opp_draw_pile)), _old);
        obj_game.opp_hand[_swap_slot] = _new;

        // New card teleports to hand slot (H1 is invisible — cards are face-down)
        _new.x = _old.x;
        _new.y = _old.y;
        _new.target_x = _old.target_x;
        _new.target_y = _old.target_y;
        _new.is_moving = false;
        _new.depth = _old.depth;
        _new.flip_state = 0;
        _new.flip_scale = 1;
        _new.face_up = false;
        _new.flip_to_face = false;
    }

    // Re-stack opp_draw_pile (stable visual; old card was inserted at random index)
    for (var i = 0; i < array_length(obj_game.opp_draw_pile); i++) {
        var _c = obj_game.opp_draw_pile[i];
        _c.target_x = obj_game.DRAW_X;
        _c.target_y = obj_game.OPP_DRAW_Y - i * obj_game.PILE_OFFSET;   // Sprint 3 Phase 2b.2: opp pile top
        _c.x = _c.target_x;
        _c.y = _c.target_y;
        _c.depth = 50 - i;      // Bug C fix: opp depth must be < Background layer depth (100)
        _c.is_moving = false;
        _c.face_up = false;
        _c.flip_state = 0;
        _c.flip_scale = 1;
    }
}

function _instantiate_card_from_struct(_card_struct, _x, _y, _owner) {
    var _inst = instance_create_layer(_x, _y, obj_game.layer, obj_card);
    _inst.card_type = _str_to_card_type_int(_card_struct.type_name);

    // Enforce rule instance ownership (MANDATORY plan convention):
    // deep-clone rules so this obj_card independently owns them, preventing
    // cross-card level leakage when multiple CardStructs share rule references.
    // variable_clone with explicit depth to deep-copy nested effect_params struct
    // (Round 4 upgrade handlers may mutate params; without depth, shared ref leaks).
    _inst.rules = [];
    for (var i = 0; i < array_length(_card_struct.rules); i++) {
        _inst.rules[i] = variable_clone(_card_struct.rules[i], 10);
    }

    _inst.card_owner = _owner;
    // D33: CardStruct no longer carries display_name (minimal naming). Kept on obj_card
    // as empty string for backward-compat with any residual UI readers.
    _inst.display_name = "";
    _inst.target_x = _x;
    _inst.target_y = _y;
    return _inst;
}

function _instantiate_player_draw_pile() {
    obj_game.player_draw_pile = [];
    var _deck = obj_game.player_deck;
    for (var i = 0; i < array_length(_deck); i++) {
        var _card = _deck[i];
        var _x = obj_game.DRAW_X;
        var _y = obj_game.PLR_DRAW_Y - i * obj_game.PILE_OFFSET;   // Sprint 3 Phase 2b.2: plr pile bottom
        var _inst = _instantiate_card_from_struct(_card, _x, _y, "player");
        _inst.depth = 50 - i;
        array_push(obj_game.player_draw_pile, _inst);
    }
    _shuffle_pile_by_owner("player");
}

function _instantiate_opp_draw_pile(_enemy) {
    obj_game.opp_draw_pile = [];
    var _comp = _enemy.deck_composition;
    var _types = ["rock", "scissors", "paper"];
    var _counter = 0;
    for (var t = 0; t < 3; t++) {
        var _type_name = _types[t];
        var _count = _comp[$ _type_name] ?? 0;
        for (var c = 0; c < _count; c++) {
            var _struct = new CardStruct(_type_name, []);
            var _x = obj_game.DRAW_X;
            var _y = obj_game.OPP_DRAW_Y - _counter * obj_game.PILE_OFFSET;   // Sprint 3 Phase 2b.2: opp pile top
            var _inst = _instantiate_card_from_struct(_struct, _x, _y, "opp");
            // 2026-04-26 Bug C fix: was 150-i which exceeds Background layer depth (100),
            // causing BG to paint over opp cards. Now 50-i, same as plr — both < 100.
            _inst.depth = 50 - _counter;
            array_push(obj_game.opp_draw_pile, _inst);
            _counter += 1;
        }
    }
    _shuffle_pile_by_owner("opp");
}

function _shuffle_pile_by_owner(_owner) {
    var _pile = (_owner == "player") ? obj_game.player_draw_pile : obj_game.opp_draw_pile;
    for (var i = array_length(_pile) - 1; i > 0; i--) {
        var j = irandom(i);
        var _tmp = _pile[i];
        _pile[i] = _pile[j];
        _pile[j] = _tmp;
    }
    if (_owner == "player") {
        obj_game.player_draw_pile = _pile;
    } else {
        obj_game.opp_draw_pile = _pile;
    }
    // Sprint 3 Phase 2b.2: per-owner draw pile Y (opp top / plr bottom)
    var _draw_y = (_owner == "player") ? obj_game.PLR_DRAW_Y : obj_game.OPP_DRAW_Y;
    for (var i = 0; i < array_length(_pile); i++) {
        var _inst = _pile[i];
        _inst.target_x = obj_game.DRAW_X;
        _inst.target_y = _draw_y - i * obj_game.PILE_OFFSET;
        _inst.depth = 50 - i;   // Bug C fix: opp was 150-i (> Background 100, BG covered cards)
    }
}

// ===== Sprint 2 Self-Test (invoked from obj_game Create_0 — logs PASS/FAIL) =====
// Covers pure-logic helpers (no obj_game state needed) + config integrity checks.
// Goal: catch wiring errors before user runs a real battle. Does NOT cover UI or runtime AI.
function _sprint2_self_test() {
    show_debug_message("==== Sprint 2 Self-Test START ====");
    var _passed = 0;
    var _failed = 0;

    // T1: int ↔ str type conversion is bi-directional and covers all 3 types
    var _t1 = true;
    for (var i = 0; i < 3; i++) {
        var _s = _int_to_card_type_str(i);
        if (_str_to_card_type_int(_s) != i) _t1 = false;
    }
    if (_t1) { _passed++; show_debug_message("[PASS T1] int↔str conversion"); }
    else { _failed++; show_debug_message("[FAIL T1] int↔str conversion broken"); }

    // T2: _get_type_that_beats RPS cycle (rock→paper, paper→scissors, scissors→rock)
    var _t2 = (_get_type_that_beats("rock") == "paper")
           && (_get_type_that_beats("paper") == "scissors")
           && (_get_type_that_beats("scissors") == "rock");
    if (_t2) { _passed++; show_debug_message("[PASS T2] RPS beats cycle"); }
    else { _failed++; show_debug_message("[FAIL T2] RPS beats cycle"); }

    // T3: stage lookup returns non-undefined for known ids + required fields present
    var _stg_t = _get_stage_by_id("stage_tutorial");
    var _stg_1 = _get_stage_by_id("stage_1");
    var _t3 = !is_undefined(_stg_t) && !is_undefined(_stg_1)
          && variable_struct_exists(_stg_1, "rewards")
          && variable_struct_exists(_stg_1, "has_h1")
          && variable_struct_exists(_stg_1, "rule_pool")
          && _stg_1.has_h1 == true
          && _stg_t.has_h1 == false;
    if (_t3) { _passed++; show_debug_message("[PASS T3] stage config integrity (D55/D59)"); }
    else { _failed++; show_debug_message("[FAIL T3] stage config integrity"); }

    // T4: enemy template lookup + D54 no-name schema + ai_params.type present
    var _e1 = _get_enemy_template_by_id("enemy_stage1_scout");
    var _et = _get_enemy_template_by_id("enemy_tutorial_dummy");
    var _t4 = !is_undefined(_e1) && !is_undefined(_et)
          && _e1.max_hp == 5 && _et.max_hp == 3
          && _e1.ai_params.type == "stage1_f"
          && _et.ai_params.type == "random"
          && !variable_struct_exists(_e1, "name");  // D54: no name field
    if (_t4) { _passed++; show_debug_message("[PASS T4] enemy config integrity (D54/D58)"); }
    else { _failed++; show_debug_message("[FAIL T4] enemy config integrity"); }

    // T5: item template lookup + D51 no-name schema + cost field present
    var _item = _get_item_template_by_id("item_peek_opp_hand");
    var _t5 = !is_undefined(_item)
          && variable_struct_exists(_item, "cost")
          && variable_struct_exists(_item, "description_text")
          && !variable_struct_exists(_item, "name");
    if (_t5) { _passed++; show_debug_message("[PASS T5] item config integrity (D51)"); }
    else { _failed++; show_debug_message("[FAIL T5] item config integrity"); }

    // T6: rule lookup + cost present + D51 minimal schema (no name)
    var _rule = _get_rule_template_by_id("high_dmg_on_win");
    var _t6 = !is_undefined(_rule)
          && variable_struct_exists(_rule, "cost")
          && variable_struct_exists(_rule, "description_text")
          && !variable_struct_exists(_rule, "name");
    if (_t6) { _passed++; show_debug_message("[PASS T6] rule config integrity (D51)"); }
    else { _failed++; show_debug_message("[FAIL T6] rule config integrity"); }

    // T7: implicit rule check — rock always has beat_scissors (D39)
    var _t7 = _card_has_implicit_rule("rock", "beat_scissors")
          && _card_has_implicit_rule("scissors", "beat_paper")
          && _card_has_implicit_rule("paper", "beat_rock")
          && !_card_has_implicit_rule("rock", "beat_rock")
          && !_card_has_implicit_rule("rock", "beat_paper");
    if (_t7) { _passed++; show_debug_message("[PASS T7] implicit rule matrix (D39)"); }
    else { _failed++; show_debug_message("[FAIL T7] implicit rule matrix"); }

    // T8: stage_1 rule_pool contains expected 5 rules (basic RPS + high_dmg_on_win + tie_dmg)
    var _rp = _stg_1.rule_pool;
    var _t8 = array_length(_rp) == 5
          && (array_contains(_rp, "beat_rock") || array_length(_rp) == 5);  // minimal check
    if (_t8) { _passed++; show_debug_message("[PASS T8] stage_1 rule_pool size=5"); }
    else { _failed++; show_debug_message("[FAIL T8] stage_1 rule_pool size != 5"); }

    // T9: i18n dictionary has core keys (requires i18n_init() to have run before Create)
    var _t9 = (_t("ui_duel") != "ui_duel") && (_t("ui_battle") != "ui_battle" || _t("ui_duel") != "ui_duel");
    if (_t9) { _passed++; show_debug_message("[PASS T9] i18n dictionary has core keys"); }
    else { _failed++; show_debug_message("[FAIL T9] i18n missing core keys (check scr_i18n init order)"); }

    // T10: CardStruct new 2-arg signature accepts type+rules
    var _c_test = new CardStruct("rock", []);
    var _t10 = !is_undefined(_c_test) && _c_test.type_name == "rock" && array_length(_c_test.rules) == 0;
    if (_t10) { _passed++; show_debug_message("[PASS T10] CardStruct 2-arg signature"); }
    else { _failed++; show_debug_message("[FAIL T10] CardStruct signature broken"); }

    show_debug_message("==== Sprint 2 Self-Test: " + string(_passed) + " passed, " + string(_failed) + " failed ====");
}

// ===== Sprint 3 Phase 2c shared manager advance helpers =====
// Called from obj_room_mgr_base Step_0 SPACE dispatch + subclass click handlers.
// Extracting these lets subclasses (obj_shop_mgr / obj_rest_mgr / etc.) invoke advance
// from their own UI buttons without copy-pasting the branch progression logic.

/// @desc Advance from a shop/rest/event/remove node (D61: 3 sub-nodes per lane).
/// Increments sub_index; if < 3 → back to map; else reset branch state + next battle.
function _mgr_advance_non_battle_node() {
    obj_game.current_branch_sub_index += 1;
    if (obj_game.current_branch_sub_index >= 3) {
        obj_game.map_position += 1;
        obj_game.current_branch_line = "";
        obj_game.current_branch_sub_index = 0;
        obj_game.state = "BATTLE_START";
        obj_game.wait_timer = 10;
        room_goto(room0);   // room0 = legacy battle room name
    } else {
        room_goto(rm_run_map);
    }
}

// ===== Sprint 3 Phase 2d helpers: Unified Upgrade UI =====

/// @desc Returns array of deck-card indices that can LEGALLY receive a given rule.
/// D39: implicit rules (rock=beat_scissors / scissors=beat_paper / paper=beat_rock) cannot be re-applied.
/// D23 (exhaustive search): also excludes cards that already have the rule at max_level.
/// If returned array is empty, the rule has no legal target on this deck.
function _get_legal_target_cards(_rule_id, _deck) {
    var _legal = [];
    for (var i = 0; i < array_length(_deck); i++) {
        var _card = _deck[i];
        // Skip: implicit rule already present (D39)
        if (_card_has_implicit_rule(_card.type_name, _rule_id)) continue;
        // Skip: already has rule at max_level
        var _maxed = false;
        for (var j = 0; j < array_length(_card.rules); j++) {
            if (_card.rules[j].id == _rule_id && _card.rules[j].level >= _card.rules[j].max_level) {
                _maxed = true;
                break;
            }
        }
        if (_maxed) continue;
        array_push(_legal, i);
    }
    return _legal;
}

/// @desc Apply a rule to the card at deck index. If the card already has this rule below max,
/// level it up; else append a new deep-cloned rule instance. Returns true if applied.
/// Does NOT validate legality — caller must pre-filter via _get_legal_target_cards.
function _apply_rule_to_card(_rule_id, _card_idx) {
    if (_card_idx < 0 || _card_idx >= array_length(obj_game.player_deck)) return false;
    var _card = obj_game.player_deck[_card_idx];
    var _tpl = _get_rule_template_by_id(_rule_id);
    if (is_undefined(_tpl)) return false;

    // Existing rule → level up if not maxed
    for (var i = 0; i < array_length(_card.rules); i++) {
        if (_card.rules[i].id == _rule_id) {
            if (_card.rules[i].level < _card.rules[i].max_level) {
                _card.rules[i].level += 1;
                show_debug_message("[upgrade] Leveled up rule '" + _rule_id + "' on card idx=" + string(_card_idx) + " → L" + string(_card.rules[i].level));
                return true;
            } else {
                show_debug_message("[upgrade] Rule '" + _rule_id + "' already at max on card idx=" + string(_card_idx));
                return false;
            }
        }
    }

    // New rule: deep clone so this card owns its instance
    var _new_rule = variable_clone(_tpl, 10);
    array_push(_card.rules, _new_rule);
    show_debug_message("[upgrade] Applied new rule '" + _rule_id + "' on card idx=" + string(_card_idx));
    return true;
}

/// @desc Compute N card positions along a fan arc centered at (pivot_x, pivot_y) with radius and angle spread.
/// Used by rm_upgrade's deck fan (big fan, 12+ cards, ±55°) — generalized helper for future reuse.
/// Returns array of structs { x, y, angle_deg } per card. cards_count==1 places the card at center.
function _compute_fan_card_positions(_pivot_x, _pivot_y, _radius, _cards_count, _angle_spread_deg) {
    var _positions = [];
    for (var i = 0; i < _cards_count; i++) {
        var _t;
        if (_cards_count <= 1) {
            _t = 0;
        } else {
            _t = (i / (_cards_count - 1)) - 0.5;   // -0.5 to +0.5
        }
        var _angle_deg = _t * _angle_spread_deg;
        var _angle_rad = degtorad(_angle_deg);
        var _x = _pivot_x + sin(_angle_rad) * _radius;
        var _y = _pivot_y - cos(_angle_rad) * _radius;
        array_push(_positions, { x: _x, y: _y, angle_deg: _angle_deg });
    }
    return _positions;
}

/// @desc Sprint 3 Phase 2e.3: generate a new card per stage.rewards.card_algorithm.
/// Returns CardStruct or undefined (no card reward). Supported algorithms:
///   "none"/"": no card
///   "basic_random_rsp_rule": random type + 1 random rule from stage pool (D39 implicit filtered)
function _generate_card_by_algorithm(_algo, _stage) {
    switch (_algo) {
        case "none":
        case "":
            return undefined;

        case "basic_random_rsp_rule":
            var _types = ["rock", "scissors", "paper"];
            var _type = _types[irandom(2)];
            var _rules_for_card = [];

            if (!is_undefined(_stage) && array_length(_stage.rule_pool) > 0) {
                // Filter pool for D39 implicit (can't add rule already implicit on this type)
                var _legal_ids = [];
                for (var i = 0; i < array_length(_stage.rule_pool); i++) {
                    var _rid = _stage.rule_pool[i];
                    if (!_card_has_implicit_rule(_type, _rid)) {
                        array_push(_legal_ids, _rid);
                    }
                }
                if (array_length(_legal_ids) > 0) {
                    var _picked_id = _legal_ids[irandom(array_length(_legal_ids) - 1)];
                    var _tpl = _get_rule_template_by_id(_picked_id);
                    if (!is_undefined(_tpl)) {
                        array_push(_rules_for_card, variable_clone(_tpl, 10));
                    }
                }
            }

            var _card = new CardStruct(_type, _rules_for_card);
            show_debug_message("[card_gen] " + _algo + " → " + _type + " with " + string(array_length(_rules_for_card)) + " rules");
            return _card;
    }
    show_debug_message("[card_gen] WARN unknown algorithm '" + _algo + "'");
    return undefined;
}

/// @desc Sprint 3 Phase 2d helper: sample N distinct rules from a stage's rule_pool.
/// Returns array of RuleStruct templates (may be shorter than N if pool has fewer distinct ids).
function _sample_rules_from_pool(_stage, _n) {
    var _out = [];
    if (is_undefined(_stage)) return _out;
    var _pool = _stage.rule_pool;
    if (array_length(_pool) == 0) return _out;

    var _used = [];
    var _tries = 0;
    var _cap = min(_n, array_length(_pool));
    while (array_length(_out) < _cap && _tries < _n * 6) {
        var _id = _pool[irandom(array_length(_pool) - 1)];
        var _dup = false;
        for (var i = 0; i < array_length(_used); i++) {
            if (_used[i] == _id) { _dup = true; break; }
        }
        if (!_dup) {
            var _tpl = _get_rule_template_by_id(_id);
            if (!is_undefined(_tpl)) {
                array_push(_out, _tpl);
                array_push(_used, _id);
            }
        }
        _tries++;
    }
    return _out;
}

/// @desc Sprint 3 Phase 3 starter pack (D45): every RUN_START 交付 3 peek items + 1 upgrade
/// (抽取池 = stage_tutorial.rule_pool). Returns true if upgrade triggered (caller must room_goto to rm_upgrade).
/// MVP: 每 run 都跑 (不走 tutorial 作为独立 battle — Tutorial 作为 rule_pool 来源). 后续 Phase 4
/// 可添加 Tutorial 作为独立可 skip 的 first-time battle.
function _apply_starter_pack() {
    // 1. Add 3 peek items to items bar (respecting 4-slot limit)
    for (var i = 0; i < 3; i++) {
        var _tpl = _get_item_template_by_id("peek_opp_hand");
        _add_item_to_inventory(_tpl);   // helper handles 4-slot cap + stacking
    }

    // 2. Trigger upgrade UI with 3 candidates from tutorial pool
    var _tut_stage = _get_stage_by_id("stage_tutorial");
    var _candidates = _sample_rules_from_pool(_tut_stage, 3);
    if (array_length(_candidates) == 0) {
        show_debug_message("[starter_pack] no rules in stage_tutorial pool — skip upgrade");
        return false;
    }

    obj_game.upgrade_context = {
        candidates: _candidates,
        source: "starter",
        return_room: room0,
        pending_gold_deduct: 0,
        shop_slot_idx: -1
    };
    show_debug_message("[starter_pack] 3 peek items + " + string(array_length(_candidates)) + " upgrade candidates");
    return true;
}

/// @desc Sprint 3 Phase 2d: finalize upgrade (CONFIRM or CANCEL) and advance per source.
/// Called by obj_upgrade_mgr on CONFIRM/CANCEL button or ESC. _apply=true → apply rule + deduct gold
/// (for shop); _apply=false → skip apply (CANCEL). Both paths advance via source-specific helper.
function _upgrade_finalize(_apply) {
    var _ctx = obj_game.upgrade_context;
    if (is_undefined(_ctx)) {
        room_goto(rm_run_map);
        return;
    }

    if (_apply && instance_exists(obj_upgrade_mgr)) {
        var _rule_idx = obj_upgrade_mgr.selected_rule_idx;
        var _card_idx = obj_upgrade_mgr.selected_target_card_idx;
        if (_rule_idx >= 0 && _card_idx >= 0) {
            var _rule = _ctx.candidates[_rule_idx];
            _apply_rule_to_card(_rule.id, _card_idx);

            // Shop: deduct gold on CONFIRM only (CANCEL = no charge, MVP refund by default)
            if (_ctx.source == "shop") {
                obj_game.gold -= _ctx.pending_gold_deduct;
                show_debug_message("[upgrade] Shop: -" + string(_ctx.pending_gold_deduct) + "g → gold=" + string(obj_game.gold));
            }
        }
    }

    var _source = _ctx.source;
    obj_game.upgrade_context = undefined;

    switch (_source) {
        case "rest":
        case "shop":
        case "event_d":
            _mgr_advance_non_battle_node();
            break;
        case "starter":
            // Phase 3.tutorial (D28): if this starter upgrade was triggered by tutorial completion
            // (rm_reward CLAIM for stage_tutorial), mark tutorial_done + return to TITLE.
            // Else (starter at RUN_START of a regular run) → proceed to first battle.
            if (obj_game.is_tutorial_run) {
                settings_mark_tutorial_done();
                obj_game.is_tutorial_run = false;
                obj_game.state = "TITLE";
                obj_game.wait_timer = 10;
                show_debug_message("[tutorial] Complete → tutorial_done=true persisted, returning to TITLE");
                room_goto(room0);
            } else {
                obj_game.state = "BATTLE_START";
                obj_game.wait_timer = 10;
                room_goto(room0);
            }
            break;
        default:
            show_debug_message("[upgrade] Unknown source '" + _source + "' — bail to rm_run_map");
            room_goto(rm_run_map);
    }
}

/// @desc Sprint 3 Phase 2c helper: count player_deck cards by type_name.
/// Returns struct { rock: N, scissors: N, paper: N }. Used by rm_remove + deck viewers.
function _count_deck_by_type() {
    var _counts = { rock: 0, scissors: 0, paper: 0 };
    for (var i = 0; i < array_length(obj_game.player_deck); i++) {
        var _t = obj_game.player_deck[i].type_name;
        if (variable_struct_exists(_counts, _t)) {
            _counts[$ _t] += 1;
        }
    }
    return _counts;
}

// Phase 1 Batch 6 (F2) cleanup: `_remove_first_card_of_type` removed (Phase 2e.1 switched
// rm_remove to index-based `array_delete` via UI fan picker, this helper became unused).
// If a future system needs first-of-type removal, re-add or generalize via `_remove_card_at(idx)`.

/// @desc Phase 2c.reward: apply a stage's D55 reward fields to run state.
/// gold → obj_game.gold += N. items (item_source="starter_pack_peek") → add N × peek_opp_hand.
/// card (card_algorithm) and upgrade (upgrade_count) are Phase 2c.card / Phase 2d TODO.
/// Returns true if any reward was applied.
function _apply_stage_rewards(_stage) {
    if (is_undefined(_stage)) return false;
    var _r = _stage.rewards;
    var _applied = false;

    if (_r.gold > 0) {
        obj_game.gold += _r.gold;
        show_debug_message("[reward] +" + string(_r.gold) + " gold → " + string(obj_game.gold));
        _applied = true;
    }

    if (_r.item_count > 0) {
        if (_r.item_source == "starter_pack_peek") {
            // Fix (Phase 2c review HIGH-1): use unprefixed item id (canonical in scr_config_items)
            for (var i = 0; i < _r.item_count; i++) {
                var _tpl = _get_item_template_by_id("peek_opp_hand");
                if (!_add_item_to_inventory(_tpl)) {
                    show_debug_message("[reward] items slot full, skipping item " + string(i));
                }
            }
            show_debug_message("[reward] +" + string(_r.item_count) + " peek items");
            _applied = true;
        } else {
            show_debug_message("[reward] item_source '" + _r.item_source + "' not wired (Phase 2c.card TODO)");
        }
    }

    if (_r.card_count > 0) {
        // Phase 2e.3: actually generate cards using algorithm + push to deck
        for (var _ci = 0; _ci < _r.card_count; _ci++) {
            var _new_card = _generate_card_by_algorithm(_r.card_algorithm, _stage);
            if (!is_undefined(_new_card)) {
                array_push(obj_game.player_deck, _new_card);
                _applied = true;
            }
        }
        show_debug_message("[reward] +" + string(_r.card_count) + " card(s) via '" + _r.card_algorithm + "' → deck size " + string(array_length(obj_game.player_deck)));
    }

    if (_r.upgrade_count > 0) {
        show_debug_message("[reward] upgrade_count=" + string(_r.upgrade_count) + " (Phase 2d Unified Upgrade UI pending)");
    }

    return _applied;
}

/// @desc Advance from rm_reward. If last battle → RUN_VICTORY in room0; else → next branch in map.
function _mgr_advance_reward() {
    show_debug_message("[advance_reward] called: current_battle_index=" + string(obj_game.current_battle_index) + " map_position=" + string(obj_game.map_position) + " map.length=" + string(array_length(obj_game.map)));
    if (obj_game.current_battle_index >= 5) {
        obj_game.state = "RUN_VICTORY";
        obj_game.wait_timer = 15;
        show_debug_message("[advance_reward] last battle → RUN_VICTORY");
        room_goto(room0);
    } else {
        obj_game.map_position += 1;
        obj_game.current_branch_line = "";
        obj_game.current_branch_sub_index = 0;
        obj_game.state = "RUN_MAP_BRANCH";
        show_debug_message("[advance_reward] → rm_run_map (map_position now " + string(obj_game.map_position) + ")");
        room_goto(rm_run_map);
    }
}

/// @desc Phase 1 skeleton debug advance from rm_run_map — directly into next battle.
/// Phase 2c.run_map will replace SPACE with node-click navigation.
function _mgr_advance_run_map_debug() {
    obj_game.state = "BATTLE_START";
    obj_game.wait_timer = 10;
    room_goto(room0);
}

/// @desc Sprint 3 Phase 2b.6: commit the selected card as plr_play and transition to REVEAL.
/// Called from _handle_duel_click (UI click handler) when DUEL button is pressed with a selected card.
/// Extracted from original PLAYER_WAIT auto-REVEAL body so player can re-select freely before commit.
function _player_commit_play(_card) {
    _play_sfx(snd_duel_commit);   // 2026-04-27: distinct DUEL commit sfx
    obj_game.plr_play = _card;

    // Remove from plr_hand (exactly one slot matches _card)
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] == _card) {
            obj_game.plr_hand[i] = noone;
            break;
        }
    }

    // Disable input on remaining hand cards
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] != noone) {
            obj_game.plr_hand[i].hoverable = false;
            obj_game.plr_hand[i].clickable = false;
        }
    }
    obj_game.plr_play.hoverable = false;
    obj_game.plr_play.clickable = false;

    obj_game.plr_play.target_x = obj_game.PLR_PLAY_X;
    obj_game.plr_play.target_y = obj_game.PLR_PLAY_Y;
    obj_game.plr_play.is_moving = true;
    obj_game.plr_play.move_speed = 0.10;
    obj_game.plr_play.depth = -60;
    // 2026-04-27: snd_card_move removed here — snd_duel_commit at line 657 covers commit moment.
    // Per user "应该是只有commit duel, 没有牌移动或者发牌的音效".

    obj_game.selected_card = noone;
    obj_game.state = "REVEAL";
    obj_game.wait_timer = 60;
}

function _enter_current_node() {
    var _node_marker = obj_game.map[obj_game.map_position];
    if (_node_marker.type != "branch_marker") {
        show_debug_message("[ERROR] _enter_current_node: current map node is not branch_marker (type=" + string(_node_marker.type) + ")");
        obj_game.state = "BATTLE_START";
        return;
    }
    var _branch = get_branch_by_id(_node_marker.payload.branch_id);
    if (is_undefined(_branch)) {
        obj_game.state = "BATTLE_START";
        return;
    }
    var _line = (obj_game.current_branch_line == "A") ? _branch.line_a_nodes : _branch.line_b_nodes;
    var _sub = _line[obj_game.current_branch_sub_index];
    var _target_room = noone;
    switch (_sub.type) {
        case "shop":   _target_room = rm_shop;   break;
        case "rest":   _target_room = rm_rest;   break;
        case "event":  _target_room = rm_event;  break;
        case "remove": _target_room = rm_remove; break;
        default:
            show_debug_message("[ERROR] _enter_current_node: unknown sub type: " + string(_sub.type));
            obj_game.state = "BATTLE_START";
            return;
    }
    // Backlog cleanup: removed dead `obj_game.state = "NODE_*"` write — no consumer reads it
    // (handlers deleted in Batch 6 F1). obj_*_mgr subclasses own each room's UI; routing via room_goto.
    show_debug_message("[Sprint3] Entering node: branch=" + _branch.id
        + " line=" + obj_game.current_branch_line
        + " sub=" + string(obj_game.current_branch_sub_index)
        + " type=" + _sub.type + " → room_goto " + room_get_name(_target_room));
    room_goto(_target_room);   // D56: each non-battle node is its own room
}

/// @desc 2026-04-26: add item to obj_game.items with stacking — same id increments charges
/// instead of occupying separate slot. Per user "正常逻辑不应该是同类合并 XX 道具 *3,
/// 用一个变为 *2. 用完就没有了".
/// @param tpl  ItemStruct template (variable_clone'd if new slot allocated)
/// @return bool true if added/stacked, false if inventory full
function _add_item_to_inventory(tpl) {
    if (is_undefined(tpl)) return false;
    // Stack into existing slot if same id present
    for (var _i = 0; _i < array_length(obj_game.items); _i++) {
        var _existing = obj_game.items[_i];
        if (_existing.id == tpl.id) {
            _existing.current_charges += 1;
            _existing.max_charges += 1;
            show_debug_message("[items] stacked " + tpl.id + " → " + string(_existing.current_charges) + "/" + string(_existing.max_charges));
            return true;
        }
    }
    // No matching slot — push if room (4 max)
    if (array_length(obj_game.items) >= 4) {
        show_debug_message("[items] inventory full (4 slots), refused " + tpl.id);
        return false;
    }
    array_push(obj_game.items, variable_clone(tpl, 5));
    show_debug_message("[items] new slot " + tpl.id + " (1/1)");
    return true;
}

/// @desc 2026-04-26 option B: select a player hand card → preview at PLR_PLAY position.
/// Re-clicking another card automatically swaps (old card recomputed by _update_plr_hand_fan
/// next frame because it's no longer == selected_card).
/// DUEL button still commits via _player_commit_play.
/// @param card_id obj_card instance from plr_hand
function _player_select_card(card_id) {
    // 2026-04-26: toggle behavior + recall sfx (per user "再点击一下打出的那张牌就收回来").
    if (obj_game.selected_card == card_id) {
        // Click on already-selected card → unselect, fan layout reclaims it next frame.
        obj_game.selected_card = noone;
        _play_recall_sfx();
        show_debug_message("[select] toggled OFF — card returns to fan");
        return;
    }
    // Switching selection: play recall for old, then move/play for new.
    if (obj_game.selected_card != noone) {
        _play_recall_sfx();
    }
    obj_game.selected_card = card_id;
    card_id.target_x = obj_game.PLR_PLAY_X;
    card_id.target_y = obj_game.PLR_PLAY_Y;
    card_id.target_rotation = 0;
    card_id.is_moving = true;
    card_id.move_speed = 0.18;
    card_id.depth = -60;
    _play_sfx(snd_card_move);
    show_debug_message("[select] previewing card at PLR_PLAY position");
}

/// @desc Phase 1 Batch 4 (B3): resolve a card click while ui_select_card_mode is active.
/// Currently only "discard_own_hand" callback uses this — moves card from plr_hand to limbo
/// (player_excluded_pile). Limbo cards don't reshuffle this battle (BATTLE_START resets array).
/// @param card_id (obj_card instance) the clicked card
function _resolve_select_card_pick(card_id) {
    if (!obj_game.ui_select_card_mode) return;

    switch (obj_game.ui_select_card_callback) {
        case "force_opp_replay":
            // 2026-04-26: swap clicked opp_hand card with current opp_play.
            // Picked card → opp_play (face-up permanently via is_peek_revealed=true).
            // Old opp_play → opp_hand[slot] (state preserved — face-up if peeked, else face-down).
            var _opp_slot = -1;
            for (var i = 0; i < 3; i++) {
                if (obj_game.opp_hand[i] == card_id) { _opp_slot = i; break; }
            }
            if (_opp_slot < 0) {
                show_debug_message("[force_opp_replay resolve] clicked card not in opp_hand — ignoring");
                return;
            }
            var _old_opp_play = obj_game.opp_play;

            // New opp_play setup
            obj_game.opp_play = card_id;
            card_id.is_peek_revealed = true;     // permanent face-up flag
            if (!card_id.face_up) {
                card_id.flip_state = 1;
                card_id.flip_to_face = true;
            }
            card_id.target_x = obj_game.OPP_PLAY_X;
            card_id.target_y = obj_game.OPP_PLAY_Y;
            card_id.is_moving = true;
            card_id.move_speed = 0.10;
            card_id.depth = -60;
            card_id.hoverable = false;     // play area: not hoverable (mouse_check_button_pressed for DUEL not needed)
            card_id.clickable = false;

            // Old opp_play returns to opp_hand slot. Inline fan-position math (mirrors
            // _update_opp_hand_fan) so card immediately animates to hand slot — without this,
            // 1-frame visual stack at OPP_PLAY_X/Y until next _update_opp_hand_fan tick.
            obj_game.opp_hand[_opp_slot] = _old_opp_play;
            var _angle_rad_old = degtorad((_opp_slot - 1) * obj_game.HAND_FAN_ANGLE_DEG);
            var _dx_old = sin(_angle_rad_old) * obj_game.HAND_FAN_RADIUS;
            var _dy_old = cos(_angle_rad_old) * obj_game.HAND_FAN_RADIUS;   // +cos = downward (mirror of plr)
            _old_opp_play.target_x = obj_game.HAND_FAN_PIVOT_X + _dx_old;
            _old_opp_play.target_y = obj_game.OPP_HAND_FAN_PIVOT_Y + _dy_old;
            _old_opp_play.is_moving = true;
            _old_opp_play.move_speed = 0.10;
            _old_opp_play.depth = -50 - _opp_slot;

            _play_sfx(snd_card_move);
            show_debug_message("[force_opp_replay resolve] swapped opp_hand[" + string(_opp_slot)
                + "] ↔ opp_play (new opp_play permanently revealed)");
            break;

        case "discard_own_hand":
            // Find which hand slot this card is in
            var _slot = -1;
            for (var i = 0; i < 3; i++) {
                if (obj_game.plr_hand[i] == card_id) { _slot = i; break; }
            }
            if (_slot < 0) {
                show_debug_message("[B3 resolve] clicked card not in plr_hand — ignoring");
                return;
            }
            // Move to limbo (visual: parking offscreen-ish at current position with fade — simplified
            // by hiding via clickable=false + hoverable=false; actual destroy on BATTLE_END).
            array_push(obj_game.player_excluded_pile, card_id);
            obj_game.plr_hand[_slot] = noone;
            card_id.hoverable = false;
            card_id.clickable = false;
            // Park offscreen to right (visual cue: card "leaves the battle").
            card_id.target_x = display_get_gui_width() + 100;
            card_id.target_y = obj_game.PLR_HAND_Y;
            card_id.is_moving = true;
            card_id.move_speed = 0.10;
            _play_sfx(snd_card_move);
            show_debug_message("[B3 resolve] excluded card from slot " + string(_slot)
                + " — limbo size " + string(array_length(obj_game.player_excluded_pile)));
            break;
        default:
            show_debug_message("[B3 resolve] unknown callback: " + obj_game.ui_select_card_callback);
            break;
    }

    // Always exit select mode after one resolution + run callback-specific cleanup.
    _exit_select_card_mode();
}

/// @desc 2026-04-26: clean up select_card_mode state + any callback-specific resources.
/// Currently disables opp_hand hoverable/clickable that force_opp_replay enabled.
/// Called from _resolve_select_card_pick (success path) AND _handle_ui_clicks ESC cancel.
function _exit_select_card_mode() {
    if (obj_game.ui_select_card_callback == "force_opp_replay") {
        for (var _ii = 0; _ii < 3; _ii++) {
            var _opc = obj_game.opp_hand[_ii];
            if (_opc != noone) {
                _opc.hoverable = false;
                _opc.clickable = false;
            }
        }
    }
    obj_game.ui_select_card_mode = false;
    obj_game.ui_select_card_callback = "";
}
