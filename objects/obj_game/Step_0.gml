// ===== Sprint 3 Phase 1: room guard — obj_game battle logic only runs in room0 (rm_battle) =====
// obj_game is persistent across rooms (for run state), but Step_0 battle state machine
// + UI clicks should only fire in battle room. Non-battle rooms are handled by obj_room_mgr_base
// and its 6 subclasses (obj_run_map_mgr / obj_shop_mgr / obj_rest_mgr / obj_event_mgr /
// obj_remove_mgr / obj_reward_mgr — Phase 2a father-child split).
if (room != room0) exit;

// ===== Round 3: UI per-frame update + input dispatch (before wait_timer guard) =====
// UI logic must run every frame, including during wait_timer countdown,
// so that HP bar animation + flash timer + mouse/keyboard UI input don't stall.
_ui_per_frame_update();
_handle_ui_clicks();

// ===== Global wait timer gate =====
if (wait_timer > 0) {
    wait_timer--;
    exit;
}

switch (state) {

// ──────────────────────────────────────
// TITLE (Midterm, retained)
// ──────────────────────────────────────
case "TITLE":
    // 2026-04-26: SPACE handler removed. TITLE → RUN_START via PLAY button (_handle_title_click).
    break;

// ──────────────────────────────────────
// RUN_START (Round 2 new): generate map + init player deck + reset run state
// ──────────────────────────────────────
case "RUN_START":
    // Clear any leftover card instances
    _clear_all_card_instances();

    // Init run state (deck, HP, resources, map)
    _init_player_deck();           // 12 white cards (4R + 4S + 4P)

    map = generate_default_run_map();
    map_position = 0;
    current_battle_index = 0;
    current_branch_line = "";
    current_branch_sub_index = 0;

    player_hp = 5;           // D49 (revised 2026-04-26): player starts at 5 HP (was 10)
    player_max_hp = 5;
    opp_hp = 0;
    opp_max_hp = 0;

    gold = 0;
    relics = [];
    relic_reward_candidates = [];
    relic_reward_selected = -1;
    shop_relic = undefined;
    _relic_reset_battle_runtime();
    _relic_reset_turn_runtime();
    last_player_play_type = "";
    last_player_won_last_turn = false;
    current_stage_has_h1 = false;
    current_enemy_id = "";
    player_hand_limit = BASE_HAND_LIMIT;
    opp_hand_limit = BASE_HAND_LIMIT;

    // Clear pile refs (instances are already destroyed)
    player_draw_pile = [];
    player_discard_pile = [];
    opp_draw_pile = [];
    opp_discard_pile = [];

    // Reset hands
    _clear_all_hand_slots();
    opp_play = noone;
    plr_play = noone;
    discard_queue = [];
    deal_queue = [];
    selected_card = noone;
    ui_drag_card = noone;
    ui_drag_drop_target = "";
    turn_start_prepared = false;
    // Backlog cleanup: defensive reset of all run-scoped UI overlay state at RUN_START.
    // Mirrors pause-quit reset block (Batch 5 D3 review fix) — ensures fresh run never inherits
    // stale flags from a previous interrupted run (game_restart paths, edge cases).
    ui_overlay_open = OV_NONE;
    ui_select_card_mode = false;
    ui_select_card_callback = "";
    ui_scry_cards = [];
    ui_pile_picker_target = "";
    ui_active_discard_mode = false;
    ui_hp_flash_timer = 0;
    ui_hp_flash_owner = "";
    ui_hp_flash_player_timer = 0;
    ui_hp_flash_opp_timer = 0;
    ui_hit_flash_timer = 0;
    ui_hit_flash_owner = "";
    ui_hit_flash_player_timer = 0;
    ui_hit_flash_opp_timer = 0;
    ui_hit_flash_player_delay = 0;
    ui_hit_flash_opp_delay = 0;
    ui_duel_result_text = "";
    ui_duel_result_timer = 0;
    ui_damage_events = [];
    ui_pending_player_hp = player_hp;
    ui_pending_opp_hp = opp_hp;
    ui_pending_player_damage = 0;
    ui_pending_opp_damage = 0;
    ui_pending_player_hit_color = c_white;
    ui_pending_opp_hit_color = c_white;

    show_debug_message("[Round2] RUN_START: map=" + string(array_length(map)) + " nodes, player_hp=" + string(player_hp) + "/" + string(player_max_hp));

    state = "RUN_MAP";
    wait_timer = 0;
    room_goto(rm_run_map);
    break;

// ──────────────────────────────────────
// BATTLE_START (Round 2 new): load current enemy + instantiate both decks
// ──────────────────────────────────────
case "BATTLE_START":
    // Clear all card instances from previous battle
    _clear_all_card_instances();

    var _node = map[map_position];
    if (_node.type != "battle") {
        show_debug_message("[ERROR] BATTLE_START: map[" + string(map_position) + "] is not a battle node (type=" + string(_node.type) + ")");
        state = "TITLE";
        break;
    }

    // D55: payload now carries stage_id. Stage abstracts enemy pick + rewards + rule_pool.
    var _stage = _get_stage_by_id(_node.payload.stage_id);
    current_stage_id = _stage.id;
    current_stage_has_h1 = _stage.has_h1;      // D59: mirror for DEAL_H1_CHECK state
    _apply_stage_mechanics(_stage);
    var _enemy_id = _pick_enemy_from_stage(_stage);
    current_enemy_id = _enemy_id;
    var _enemy = _get_enemy_template_by_id(_enemy_id);
    opp_hp = _enemy.max_hp;
    opp_max_hp = _enemy.max_hp;
    current_battle_index = _node.payload[$ "battle_index"] ?? 0;
    // Reset AI F memory for new battle (enemies have per-battle memory only)
    last_player_play_type = "";
    last_player_won_last_turn = false;

    // Instantiate player & opp decks (also shuffles both)
    _instantiate_player_draw_pile();
    _instantiate_opp_draw_pile(_enemy);
    _relic_on_battle_start();

    // Reset discard piles, hands, play slots
    player_discard_pile = [];
    opp_discard_pile = [];
    _clear_all_hand_slots();
    opp_play = noone;
    plr_play = noone;
    discard_queue = [];
    deal_queue = [];
    selected_card = noone;
    ui_drag_card = noone;
    ui_drag_drop_target = "";
    ui_active_discard_mode = false;
    ui_hp_flash_timer = 0;
    ui_hp_flash_owner = "";
    ui_hp_flash_player_timer = 0;
    ui_hp_flash_opp_timer = 0;
    ui_hit_flash_timer = 0;
    ui_hit_flash_owner = "";
    ui_hit_flash_player_timer = 0;
    ui_hit_flash_opp_timer = 0;
    ui_hit_flash_player_delay = 0;
    ui_hit_flash_opp_delay = 0;
    ui_duel_result_text = "";
    ui_duel_result_timer = 0;
    ui_damage_events = [];
    ui_pending_player_hp = player_hp;
    ui_pending_opp_hp = opp_hp;
    ui_pending_player_damage = 0;
    ui_pending_opp_damage = 0;
    ui_pending_player_hit_color = c_white;
    ui_pending_opp_hit_color = c_white;
    _relic_reset_turn_runtime();
    turn_start_prepared = false;
    // Phase 1 Batch 4 (B3): clear limbo for discard_own_hand item (cards already destroyed
    // by _clear_all_card_instances above; this just resets the array reference).
    player_excluded_pile = [];

    show_debug_message("[Round2] BATTLE_START: stage=" + current_stage_id + " enemy=" + _enemy.id + " hp=" + string(opp_hp) + " deck_size=" + string(array_length(opp_draw_pile)) + " battle_index=" + string(current_battle_index));

    state = "DEAL_GUARD";
    wait_timer = 20;
    break;

// ──────────────────────────────────────
// DEAL_GUARD (Round 2 new): ensure both piles have enough cards before dealing; trigger shuffle if needed
// ──────────────────────────────────────
case "DEAL_GUARD":
    _prepare_turn_start_hands();
    var _opp_needed = _hand_missing_count("opp");
    var _plr_needed = _hand_missing_count("player");
    if (array_length(opp_draw_pile) < _opp_needed && array_length(opp_discard_pile) > 0) {
        shuffling_owner = "opp";
        state = "SHUFFLE_COLLECT";
        wait_timer = 10;
    } else if (array_length(player_draw_pile) < _plr_needed && array_length(player_discard_pile) > 0) {
        shuffling_owner = "player";
        state = "SHUFFLE_COLLECT";
        wait_timer = 10;
    } else {
        shuffling_owner = "";
        deal_queue = _build_deal_queue();
        deal_step = 0;
        state = "DEAL";
        wait_timer = 10;
    }
    break;

// ──────────────────────────────────────
// DEAL (Midterm + independent piles): 3 to opp_hand, 3 to plr_hand
// ──────────────────────────────────────
case "DEAL":
    if (deal_step < array_length(deal_queue)) {
        var _deal = deal_queue[deal_step];
        _deal_one_card_to_slot(_deal.owner, _deal.slot, deal_step);
        _play_battle_sfx("card_deal");

        deal_step++;
        wait_timer = 28;
    } else {
        // D59: route through H1 check before flipping player hand
        state = "DEAL_H1_CHECK";
        wait_timer = 10;
    }
    break;

// ──────────────────────────────────────
// DEAL_H1_CHECK (Sprint 2 / D59): hidden RPS coverage fix for stages with has_h1=true
// ──────────────────────────────────────
case "DEAL_H1_CHECK":
    _ai_h1_check_and_fix();   // no-op unless current_stage_has_h1 = true
    state = "FLIP_PLAYER";
    wait_timer = 30;
    break;

// ──────────────────────────────────────
// FLIP_PLAYER (Midterm)
// ──────────────────────────────────────
case "FLIP_PLAYER":
    for (var i = 0; i < player_hand_limit; i++) {
        if (plr_hand[i] != noone && !plr_hand[i].face_up) {
            plr_hand[i].flip_state = 1;
            plr_hand[i].flip_to_face = true;
        }
    }
    _play_battle_sfx("card_flip");
    // Peeks are now revealed by traits and relics instead of a separate peek phase.
    state = "OPP_CHOOSE";
    wait_timer = 50;
    break;

// ──────────────────────────────────────
// OPP_CHOOSE (Sprint 2: ai_params.type dispatch — random / stage1_f D48/D58)
// ──────────────────────────────────────
case "OPP_CHOOSE":
    var _pick = -1;
    var _discard_slots = [];
    var _cur_enemy = _get_enemy_template_by_id(current_enemy_id);
    var _ai_type = (!is_undefined(_cur_enemy)) ? _cur_enemy.ai_params.type : "fixed_first";

    if (_ai_type == "stage1_f") {
        _pick = _ai_stage1_f_pick(last_player_play_type, last_player_won_last_turn);
    } else if (_ai_type == "stage3_rock") {
        _pick = _ai_stage3_pick_slot();
    } else if (_ai_type == "stage4_paper_hoarder") {
        var _stage4_plan = _ai_stage4_pick_slot_and_discards();
        _pick = _stage4_plan.play_slot;
        _discard_slots = _stage4_plan.discard_slots;
    }
    // Fallback: deterministic first available card.
    if (_pick < 0) {
        _pick = _find_first_hand_card_slot("opp");
    }
    if (_ai_type != "stage4_paper_hoarder") {
        _discard_slots = [];
        for (var _si = 0; _si < opp_hand_limit; _si++) {
            if (_si != _pick && opp_hand[_si] != noone) array_push(_discard_slots, _si);
        }
    }
    if (!_opp_commit_plan(_pick, _discard_slots)) {
        show_debug_message("[ERROR] OPP_CHOOSE: no legal card to play");
        state = "RUN_DEFEAT";
        break;
    }

    // on_play already fired at enemy commit time.
    state = "PLAYER_TURN";
    wait_timer = 40;
    break;

// ──────────────────────────────────────
// PLAYER_TURN (Midterm)
// ──────────────────────────────────────
case "PLAYER_TURN":
    ui_active_discard_mode = false;
    ui_drag_card = noone;
    ui_drag_drop_target = "";
    for (var i = 0; i < player_hand_limit; i++) {
        if (plr_hand[i] != noone) {
            plr_hand[i].hoverable = true;
            plr_hand[i].clickable = true;
        }
    }
    selected_card = noone;
    state = "PLAYER_WAIT";
    break;

// ──────────────────────────────────────
// PLAYER_WAIT (Sprint 3 Phase 2b.6: DUEL button gated — no auto-REVEAL on selected_card)
// ──────────────────────────────────────
// Player can freely re-select cards (obj_card Step_0 sets obj_game.selected_card on click).
// DUEL button click (scr_ui_helpers._handle_duel_click) → _player_commit_play → REVEAL.
// This case body is intentionally empty — all PLAYER_WAIT logic lives in click handlers.
case "PLAYER_WAIT":
    break;

// ──────────────────────────────────────
// REVEAL (Midterm + Sprint 2: on_play trigger D49 + HP ≤ 0 immediate end D57)
// ──────────────────────────────────────
case "REVEAL":
    opp_play_was_seen_before_reveal = (opp_play.face_up || opp_play.is_peek_revealed);
    if (!opp_play.face_up) {
        opp_play.flip_state = 1;
        opp_play.flip_to_face = true;
        _play_battle_sfx("card_flip");
    }

    // D69: on_play triggers fire at commit time, before reveal.

    // D57: if on_play handlers dropped HP to zero, skip JUDGE and route straight to DISCARD → BATTLE_END
    if (player_hp <= 0 || opp_hp <= 0) {
        ui_ko_active = true;
        var _winner_card_d57 = (opp_hp <= 0) ? plr_play : opp_play;
        ui_screen_shake_timer = 20;
        ui_hit_flash_owner = (opp_hp <= 0) ? "opp" : "player";
        ui_hit_flash_color = _get_rps_color(_winner_card_d57.card_type);
        ui_hit_flash_timer = 25;
        _play_battle_sfx("damage_hit");
        _play_battle_sfx("ko");
        show_debug_message("[Sprint2 D57] HP ≤ 0 after on_play → skip JUDGE. player=" + string(player_hp) + " opp=" + string(opp_hp));
        state = "JUDGE_ANIMATE";
        wait_timer = 120;
        break;
    }

    state = "JUDGE";
    wait_timer = 35;
    break;

// ──────────────────────────────────────
// JUDGE (Round 2): HP system + rule_apply_all
// HP model: default winner deals 1 damage to opponent; hp_mod rules stack delta on top.
// ──────────────────────────────────────
case "JUDGE":
    ui_ko_active = false;

    var _p = plr_play.card_type;
    var _o = opp_play.card_type;
    var _p_beats = _card_beats_type(plr_play, _int_to_card_type_str(_o));
    var _o_beats = _card_beats_type(opp_play, _int_to_card_type_str(_p));
    var _p_wins = (_p_beats && !_o_beats);
    var _tie = (_p_beats && _o_beats) || (!_p_beats && !_o_beats);
    var _tie_counts_as_player_win = false;
    var _hp_player_before = player_hp;
    var _hp_opp_before = opp_hp;

    if (!_tie && !_p_wins && _has_relic_id("protective_knot") && !relic_protective_knot_spent) {
        _tie = true;
        relic_protective_knot_spent = true;
        _pulse_relic("protective_knot");
        show_debug_message("[relic protective_knot] first loss becomes tie");
    }

    if (_tie) {
        // Tie: plr rules first, opp second
        var _ctx_plr_tie = { owner:"player", opponent_card: opp_play, trigger_reason:"on_tie", rule_depth:0 };
        var _ctx_opp_tie = { owner:"opp",    opponent_card: plr_play, trigger_reason:"on_tie", rule_depth:0 };
        rule_apply_all(plr_play, "on_tie", _ctx_plr_tie);
        rule_apply_all(opp_play, "on_tie", _ctx_opp_tie);
        if (_has_relic_id("ballast_stone") && relic_ballast_card == plr_play) {
            opp_hp -= 1;
            _pulse_relic("ballast_stone");
            show_debug_message("[relic ballast_stone] tie damage 1");
        }
        if (_has_relic_id("buffer_ring")) {
            _tie_counts_as_player_win = true;
            var _ctx_plr_buffer_win  = { owner:"player", opponent_card: opp_play, trigger_reason:"on_win",  rule_depth:0 };
            var _ctx_opp_buffer_lose = { owner:"opp",    opponent_card: plr_play, trigger_reason:"on_lose", rule_depth:0 };
            rule_apply_all(plr_play, "on_win",  _ctx_plr_buffer_win);
            rule_apply_all(opp_play, "on_lose", _ctx_opp_buffer_lose);
            _pulse_relic("buffer_ring");
        }
    } else if (_p_wins) {
        // Player wins: default damage plus any retained-hand win bonus.
        if (_has_relic_id("backlight_lamp") && opp_play_was_seen_before_reveal) {
            _boost_card_win_damage(plr_play, 2, "backlight_lamp");
            _pulse_relic("backlight_lamp");
        }
        if (_has_relic_id("blind_die") && !opp_play_was_seen_before_reveal) {
            _boost_card_win_damage(plr_play, 2, "blind_die");
            _pulse_relic("blind_die");
        }
        opp_hp -= _get_card_win_damage(plr_play);
        // Round 3: flash opp HP bar
        // Phase 1 Batch 2 (C2): Tier A hit FX — opp is loser (top half), color = winner's RPS type
        var _ctx_plr_win  = { owner:"player", opponent_card: opp_play, trigger_reason:"on_win",  rule_depth:0 };
        var _ctx_opp_lose = { owner:"opp",    opponent_card: plr_play, trigger_reason:"on_lose", rule_depth:0 };
        rule_apply_all(plr_play, "on_win",  _ctx_plr_win);
        rule_apply_all(opp_play, "on_lose", _ctx_opp_lose);
    } else {
        player_hp -= _get_card_win_damage(opp_play);
        var _ctx_opp_win  = { owner:"opp",    opponent_card: plr_play, trigger_reason:"on_win",  rule_depth:0 };
        var _ctx_plr_lose = { owner:"player", opponent_card: opp_play, trigger_reason:"on_lose", rule_depth:0 };
        rule_apply_all(opp_play, "on_win",  _ctx_opp_win);
        rule_apply_all(plr_play, "on_lose", _ctx_plr_lose);
    }

    var _hp_player_after = player_hp;
    var _hp_opp_after = opp_hp;
    var _player_damage = max(0, _hp_player_before - player_hp);
    var _opp_damage = max(0, _hp_opp_before - opp_hp);
    var _result_text = _tie ? (_tie_counts_as_player_win ? "WIN" : "TIE") : (_p_wins ? "WIN" : "LOSE");

    player_hp = _hp_player_before;
    opp_hp = _hp_opp_before;
    ui_pending_player_hp = _hp_player_after;
    ui_pending_opp_hp = _hp_opp_after;
    ui_pending_player_damage = _player_damage;
    ui_pending_opp_damage = _opp_damage;
    ui_pending_player_hit_color = _get_rps_color(opp_play.card_type);
    ui_pending_opp_hit_color = _get_rps_color(plr_play.card_type);

    _ui_set_duel_result(_result_text);
    if (_result_text == "WIN") _play_battle_sfx("match_win");
    else if (_result_text == "LOSE") _play_battle_sfx("match_lose");
    else _play_battle_sfx("match_tie");

    var _qa_result = _tie ? (_tie_counts_as_player_win ? "player_win_on_tie" : "tie") : (_p_wins ? "player_win" : "opp_win");
    show_debug_message("[qa] judge stage=" + current_stage_id
        + " player=" + _int_to_card_type_str(_p)
        + " opp=" + _int_to_card_type_str(_o)
        + " result=" + _qa_result
        + " pending_hp=" + string(_hp_player_after) + "/" + string(_hp_opp_after)
        + " visible_hp=" + string(player_hp) + "/" + string(opp_hp));

    // Sprint 2 D48/D58: record player's play + win flag for next-turn AI rule F memory
    last_player_play_type = _int_to_card_type_str(_p);
    last_player_won_last_turn = _p_wins || _tie_counts_as_player_win;

    state = "JUDGE_DAMAGE_APPLY";
    wait_timer = ui_damage_apply_delay;
    break;

case "JUDGE_DAMAGE_APPLY":
    ui_duel_result_text = "";
    ui_duel_result_timer = 0;
    player_hp = ui_pending_player_hp;
    opp_hp = ui_pending_opp_hp;

    var _any_damage = false;
    if (ui_pending_opp_damage > 0) {
        ui_hp_flash_owner = "opp";
        ui_hp_flash_timer = 10;
        ui_hp_flash_opp_timer = 30;
        _ui_add_damage_feedback("opp", ui_pending_opp_damage, 0);
        _queue_side_hit_feedback("opp", ui_pending_opp_hit_color, 0);
        _any_damage = true;
    }
    if (ui_pending_player_damage > 0) {
        ui_hp_flash_owner = "player";
        ui_hp_flash_timer = 10;
        ui_hp_flash_player_timer = 30;
        _ui_add_damage_feedback("player", ui_pending_player_damage, 0);
        _queue_side_hit_feedback("player", ui_pending_player_hit_color, 0);
        _any_damage = true;
    }
    if (_any_damage) _play_battle_sfx("damage_hit");

    show_debug_message("[qa] damage_apply stage=" + current_stage_id
        + " player_damage=" + string(ui_pending_player_damage)
        + " opp_damage=" + string(ui_pending_opp_damage)
        + " hp=" + string(player_hp) + "/" + string(opp_hp));

    if (opp_hp <= 0 || player_hp <= 0) {
        state = "JUDGE_KO_DELAY";
        wait_timer = 30;
    } else {
        state = "JUDGE_ANIMATE";
        wait_timer = 38;
    }
    break;

case "JUDGE_KO_DELAY":
    ui_ko_active = true;
    ui_screen_shake_timer = max(ui_screen_shake_timer, 20);
    _play_battle_sfx("ko");
    show_debug_message("[qa] ko_after_damage player_hp=" + string(player_hp) + " opp_hp=" + string(opp_hp));
    state = "JUDGE_ANIMATE";
    wait_timer = 90;
    break;

// ──────────────────────────────────────
// JUDGE_ANIMATE: FX hook. 2026-04-26: KO BYPASSES DISCARD entirely — cards stay revealed on
// table (face-up after REVEAL); BATTLE_END_CHECK fires next, opens reward room or RUN_DEFEAT.
// User intent: "牌翻开后就停止, 不要再进入弃牌堆了" — preserve final-blow tableau.
// Non-KO path: → JUDGE_WAIT → DISCARD pipeline as before.
// ──────────────────────────────────────
case "JUDGE_ANIMATE":
    if (ui_ko_active) {
        state = "BATTLE_END_CHECK";
        wait_timer = 30;
    } else {
        state = "JUDGE_WAIT";
        wait_timer = 15;
    }
    break;

// ──────────────────────────────────────
// JUDGE_WAIT (Midterm; build discard_queue)
// ──────────────────────────────────────
case "JUDGE_WAIT":
    discard_queue = [];
    if (opp_play != noone) array_push(discard_queue, opp_play);
    if (plr_play != noone) array_push(discard_queue, plr_play);

    discard_step = 0;
    state = "DISCARD";
    wait_timer = 5;
    break;

// ──────────────────────────────────────
// DISCARD (Round 2): route to player_discard_pile or opp_discard_pile by card_owner
// ──────────────────────────────────────
case "DISCARD":
    if (discard_step < array_length(discard_queue)) {
        var _card = discard_queue[discard_step];

        if (_card == noone || !instance_exists(_card)) {
            discard_step++;
            wait_timer = 1;
            break;
        }

        if (!_card.face_up) {
            _card.flip_state = 1;
            _card.flip_to_face = true;
        }

        // 2026-04-26: clear is_peek_revealed when card enters discard (per user "reveal 后,
        // 进入 discard 里面时, 清除一下状态"). Card returns to face-down via SHUFFLE_COLLECT
        // since the !is_peek_revealed condition there now passes.
        _card.is_peek_revealed = false;

        // 2026-04-26 fix: clear source ref (opp_hand[i]/plr_hand[i]/opp_play/plr_play) AS the
        // card is pushed to discard pile. Without this, _update_opp_hand_fan still sees the card
        // in opp_hand[i] and yanks it back to fan position every frame, overriding the discard
        // target_x/y set below. User saw "对手手牌在对局结束后依然停留在场上, 没有进弃牌堆".
        if (_card == opp_play) {
            opp_play = noone;
        } else if (_card == plr_play) {
            plr_play = noone;
        } else {
            for (var _di = 0; _di < MAX_HAND_SLOTS; _di++) {
                if (opp_hand[_di] == _card) { opp_hand[_di] = noone; break; }
                if (plr_hand[_di] == _card) { plr_hand[_di] = noone; break; }
            }
        }

        _card.played_route_override = "";
        var _played_owner = _card.card_owner;
        var _ctx_played = {
            owner: _played_owner,
            source_card: _card,
            trigger_reason: "on_played",
            rule_depth: 0
        };
        rule_apply_all(_card, "on_played", _ctx_played);
        if (_card.played_route_override == "draw_top") {
            _move_card_to_draw_pile_top(_card, true);
            discard_step++;
            wait_timer = 14;
            break;
        } else if (_card.played_route_override == "draw_random") {
            _move_card_to_draw_pile_random(_card, true);
            discard_step++;
            wait_timer = 14;
            break;
        }

        var _target_pile, _pile_idx;
        if (_card.card_owner == "player") {
            _pile_idx = array_length(player_discard_pile);
            array_push(player_discard_pile, _card);
        } else {
            _pile_idx = array_length(opp_discard_pile);
            array_push(opp_discard_pile, _card);
        }

        // Sprint 3 Phase 2b.2: per-owner discard pile Y (opp top / plr bottom)
        // Sprint 3 Phase 2b.5: per-card random offset + rotation for 凌乱感 (D63)
        var _disc_y = (_card.card_owner == "player") ? PLR_DISCARD_Y : OPP_DISCARD_Y;
        _card.target_x = DISCARD_X + irandom_range(-18, 18);
        _card.target_y = _disc_y - _pile_idx * PILE_OFFSET + irandom_range(-10, 10);
        _card.target_rotation = irandom_range(-12, 12);   // backlog: lerp via Step
        _card.is_moving = true;
        _card.move_speed = 0.15;
        _card.depth = 50 - _pile_idx;
        _play_battle_sfx("card_drop_discard");

        discard_step++;
        // KO slow-mo per-card discard wait. 2026-04-26 user playtest: ×2 still too long → ×1
        // (no per-card slow-mo, ceremony comes from KO overlay + halted DISCARD elsewhere).
        wait_timer = 14;
    } else {
        opp_play = noone;
        plr_play = noone;
        discard_queue = [];
        _relic_on_end_of_turn_before_next_deal();
        ui_active_discard_mode = false;
        ui_drag_card = noone;
        ui_drag_drop_target = "";
        turn_start_prepared = false;

        state = "BATTLE_END_CHECK";
        wait_timer = 15;
    }
    break;

// ──────────────────────────────────────
// BATTLE_END_CHECK (Round 2 new): check HP, route accordingly
// ──────────────────────────────────────
case "BATTLE_END_CHECK":
    // Phase 1 Batch 2: always reset KO flag before state transition (defensive)
    ui_ko_active = false;
    // Backlog cleanup: defensive reset of scry/pile_picker overlay state.
    // 2026-04-26: permanent face-up rule applied — scry cards stay revealed (no flip back).
    if (ui_overlay_open == OV_SCRY_TOP_3) {
        ui_scry_cards = [];
        ui_overlay_open = OV_NONE;
    } else if (ui_overlay_open == OV_PILE_PICKER) {
        ui_pile_picker_target = "";
        ui_overlay_open = OV_NONE;
    }

    if (player_hp <= 0) {
        show_debug_message("[Round2] BATTLE_END_CHECK: player_hp=" + string(player_hp) + " → RUN_DEFEAT");
        state = "RUN_DEFEAT";
        wait_timer = 30;
    } else if (opp_hp <= 0) {
        // Backlog cleanup: removed dead `state = "POST_BATTLE_REWARD"` write — no consumer reads it
        // (handler deleted in Batch 6 F1). Routing is via room_goto; rm_reward's obj_reward_mgr
        // owns reward UI + advance logic. obj_game.state is overwritten by next state transition.
        show_debug_message("[Sprint3] BATTLE_END_CHECK: opp_hp=" + string(opp_hp) + " → room_goto(rm_reward)");
        wait_timer = 30;
        room_goto(rm_reward);   // D56: reward node is own room
    } else {
        state = "DEAL_GUARD";
        wait_timer = 15;
    }
    break;

// ──────────────────────────────────────
// Phase 1 Batch 6 (F1) cleanup: POST_BATTLE_REWARD / RUN_MAP_BRANCH / NODE_* case bodies removed.
// These states are now driven by independent rooms (D56 architecture):
//   - POST_BATTLE_REWARD  → rm_reward     (BATTLE_END_CHECK → room_goto rm_reward)
//   - RUN_MAP_BRANCH       → rm_run_map    (obj_run_map_mgr handles A/B click)
//   - NODE_SHOP/REST/EVENT/REMOVE → rm_shop/rm_rest/rm_event/rm_remove (obj_*_mgr per room)
// Room guard at line 6 prevents non-room0 obj_game.Step from running, so case bodies were dead
// even if state was set. obj_*_mgr subclasses set obj_game.state when transitioning rooms.
// ──────────────────────────────────────

// ──────────────────────────────────────
// SHUFFLE_COLLECT (Round 2): parameterized by shuffling_owner
// ──────────────────────────────────────
case "SHUFFLE_COLLECT":
    var _discard = (shuffling_owner == "player") ? player_discard_pile : opp_discard_pile;
    var _draw    = (shuffling_owner == "player") ? player_draw_pile    : opp_draw_pile;

    if (array_length(_discard) > 0) {
        var _last = array_length(_discard) - 1;
        var _card = _discard[_last];
        array_delete(_discard, _last, 1);

        // 2026-04-26: permanent face-up rule — cards with is_peek_revealed=true (peeked, scry'd,
        // force_opp_replay'd) stay face-up across SHUFFLE_COLLECT. Information once revealed
        // is forever known to the player (D43 dedupe extends to "永久公开").
        if (_card.face_up && !_card.is_peek_revealed) {
            _card.flip_state = 1;
            _card.flip_to_face = false;
        }

        var _pile_idx = array_length(_draw);
        // Sprint 3 Phase 2b.2: per-owner draw pile Y for shuffle collect
        // Sprint 3 Phase 2b.5: reset card rotation (card returns to tidy draw pile)
        var _draw_y_collect = (shuffling_owner == "player") ? PLR_DRAW_Y : OPP_DRAW_Y;
        _card.target_x = DRAW_X;
        _card.target_y = _draw_y_collect - _pile_idx * PILE_OFFSET;
        _card.target_rotation = 0;   // backlog: lerp via Step (was instant snap)
        _card.is_moving = true;
        _card.move_speed = 0.25;
        _card.depth = 50 - _pile_idx;   // Bug C fix: was 150 for opp, exceeds BG depth 100 → covered
        _play_battle_sfx("shuffle");

        array_push(_draw, _card);

        // Write back (array reference safety)
        if (shuffling_owner == "player") {
            player_discard_pile = _discard;
            player_draw_pile = _draw;
        } else {
            opp_discard_pile = _discard;
            opp_draw_pile = _draw;
        }

        wait_timer = 3;
    } else {
        state = "SHUFFLE_ANIM";
        wait_timer = 0;
    }
    break;

case "SHUFFLE_ANIM":
    var _pile_ref = (shuffling_owner == "player") ? player_draw_pile : opp_draw_pile;
    // Sprint 3 Phase 2b.2: shuffle animation temporarily shifts pile toward center
    // (opp down / plr up by SHUFFLE_ANIM_OFFSET) so cards are visible during the mix.
    // Phase 1 Batch 6 (F5): extracted magic 80 → SHUFFLE_ANIM_OFFSET macro.
    var _shuffle_y = (shuffling_owner == "player") ? (PLR_DRAW_Y - SHUFFLE_ANIM_OFFSET) : (OPP_DRAW_Y + SHUFFLE_ANIM_OFFSET);
    for (var i = 0; i < array_length(_pile_ref); i++) {
        var _card = _pile_ref[i];
        _card.target_y = _shuffle_y - i * PILE_OFFSET;
        _card.target_x = DRAW_X;
        _card.is_moving = true;
        _card.move_speed = 0.12;
    }
    _play_battle_sfx("shuffle");
    state = "SHUFFLE_MIX";
    wait_timer = 30;
    break;

case "SHUFFLE_MIX":
    _shuffle_pile_by_owner(shuffling_owner);
    state = "SHUFFLE_RETURN";
    deal_step = 0;
    wait_timer = 5;
    break;

case "SHUFFLE_RETURN":
    var _pile_ref2 = (shuffling_owner == "player") ? player_draw_pile : opp_draw_pile;
    // Sprint 3 Phase 2b.2: per-owner draw pile Y (cards return to opp top / plr bottom)
    var _draw_y_ret = (shuffling_owner == "player") ? PLR_DRAW_Y : OPP_DRAW_Y;
    if (deal_step < array_length(_pile_ref2)) {
        var _card = _pile_ref2[deal_step];
        _card.target_x = DRAW_X;
        _card.target_y = _draw_y_ret - deal_step * PILE_OFFSET;
        _card.is_moving = true;
        _card.move_speed = 0.25;
        _card.depth = 50 - deal_step;   // Bug C fix: opp depth always 50-i now (< BG depth 100)

        if (deal_step % 2 == 0) _play_battle_sfx("shuffle");

        deal_step++;
        wait_timer = 2;
    } else {
        show_debug_message("[Round2] SHUFFLE_" + string_upper(shuffling_owner) + " complete: " + string(array_length(_pile_ref2)) + " cards → draw_pile");
        shuffling_owner = "";
        state = "DEAL_GUARD";   // Re-check: the other side may still need shuffling
        wait_timer = 30;
    }
    break;

// ──────────────────────────────────────
// RUN_VICTORY / RUN_DEFEAT (Round 2 new): R key → room_restart (re-enter TITLE)
// ──────────────────────────────────────
case "RUN_VICTORY":
case "RUN_DEFEAT":
    if (keyboard_check_pressed(ord("R"))) {
        // Sprint 3 H1 fix: obj_game.persistent=true + Create_0 dup guard means room_restart()
        // preserves the old instance — state never returns to TITLE. game_restart() reloads
        // the whole game fresh (destroys persistent obj_game, Create runs again, clean slate).
        show_debug_message("[Sprint3 H1] R pressed in " + state + " → game_restart");
        game_restart();
    }
    break;
}
