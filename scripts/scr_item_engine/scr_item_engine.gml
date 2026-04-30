// scr_item_engine.gml — Item effect dispatcher (Sprint 2 will implement handlers; Sprint 1 stubs).
// Round 4 MVP handlers: peek_opp_hand (D43) / draw_extra / immune_this_round.
// New obj_card field `is_peek_revealed` (D43 dedupe) — set here when peek handler reveals a card.

/// @desc Use an item by id. Dispatches to handler based on effect_type. Returns true if used.
/// @param item_id String
/// @return Bool true if use succeeded
function item_use(item_id) {
    var _tpl = _get_item_template_by_id(item_id);
    if (is_undefined(_tpl)) {
        show_debug_message("[item_engine] Unknown item: " + string(item_id));
        return false;
    }

    switch (_tpl.effect_type) {
        case "peek_opp_hand":             return _item_handler_peek_opp_hand(_tpl);
        case "draw_extra":                return _item_handler_draw_extra(_tpl);
        case "immune_this_round":         return _item_handler_immune_this_round(_tpl);
        // Phase 1 Batch 4: 6 new handlers (mulligan / reveal_opp / discard_own / scry / steal / recover)
        case "mulligan":                  return _item_handler_mulligan(_tpl);
        case "reveal_opp_hand_types":     return _item_handler_reveal_opp_hand_types(_tpl);
        case "discard_own_hand":          return _item_handler_discard_own_hand(_tpl);
        case "scry_top_3":                return _item_handler_scry_top_3(_tpl);
        case "steal_from_opp_discard":    return _item_handler_steal_from_opp_discard(_tpl);
        case "recover_from_own_discard":  return _item_handler_recover_from_own_discard(_tpl);
        case "force_opp_replay":          return _item_handler_force_opp_replay(_tpl);
    }

    show_debug_message("[item_engine] Unhandled effect: " + string(_tpl.effect_type));
    return false;
}

// ===== Handlers (Sprint 2 full impl; Sprint 1 stubs return false) =====

function _item_handler_peek_opp_hand(tpl) {
    // D43: Random reveal 1 face-down enemy card from {opp_hand ∪ unrevealed opp_play}.
    // Dedupe via obj_card.is_peek_revealed flag → K peeks cover min(N_unrevealed, K) cards.
    var _candidates = [];
    for (var i = 0; i < 3; i++) {
        var _c = obj_game.opp_hand[i];
        if (_c != noone && !_c.is_peek_revealed && !_c.face_up) {
            array_push(_candidates, _c);
        }
    }
    // opp_play is a candidate only between OPP_CHOOSE (placed) and REVEAL (flipped)
    if (obj_game.opp_play != noone && !obj_game.opp_play.face_up && !obj_game.opp_play.is_peek_revealed) {
        array_push(_candidates, obj_game.opp_play);
    }
    if (array_length(_candidates) == 0) {
        show_debug_message("[item peek_opp_hand] No unrevealed candidate (all already peeked or face-up)");
        return false;
    }
    var _target = _candidates[irandom(array_length(_candidates) - 1)];
    _target.is_peek_revealed = true;
    _target.flip_state = 1;
    _target.flip_to_face = true;
    _play_sfx(snd_peek);
    show_debug_message("[item peek_opp_hand] Revealed card card_type=" + string(_target.card_type));
    return true;
}

function _item_handler_draw_extra(tpl) {
    // Draw top of player_draw_pile into first empty plr_hand slot.
    // Sprint 2 scope: reject if hand full or draw pile empty (Sprint 3 can add auto-shuffle).
    var _slot = -1;
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] == noone) {
            _slot = i;
            break;
        }
    }
    if (_slot < 0) {
        show_debug_message("[item draw_extra] Hand full — cannot draw");
        return false;
    }
    if (array_length(obj_game.player_draw_pile) == 0) {
        show_debug_message("[item draw_extra] Player draw pile empty — cannot draw (Sprint 3: auto-shuffle discard)");
        return false;
    }
    var _top = array_length(obj_game.player_draw_pile) - 1;
    var _card = obj_game.player_draw_pile[_top];
    array_delete(obj_game.player_draw_pile, _top, 1);
    obj_game.plr_hand[_slot] = _card;
    _card.target_x = obj_game.HAND_X[_slot];
    _card.target_y = obj_game.PLR_HAND_Y;
    _card.is_moving = true;
    _card.move_speed = 0.15;
    _card.depth = -50 - _slot;
    _card.hoverable = true;
    _card.clickable = true;
    if (!_card.face_up) {
        _card.flip_state = 1;
        _card.flip_to_face = true;
    }
    _play_sfx(snd_card_move);
    show_debug_message("[item draw_extra] Drew 1 card into slot " + string(_slot));
    return true;
}

function _item_handler_immune_this_round(tpl) {
    // D48: set flag. JUDGE loser branch checks flag and skips default -1 HP.
    obj_game.player_immune_this_round = true;
    _play_sfx(snd_immune);   // 2026-04-27: shield activation sfx on item use
    show_debug_message("[item immune_this_round] Player immune activated for this round");
    return true;
}

// ===== Phase 1 Batch 4 (B1-B5) handlers — D49 spec items =====

function _item_handler_mulligan(tpl) {
    // B1: Discard entire plr_hand → draw 3 fresh from player_draw_pile.
    // Backlog cleanup: inline reshuffle on draw_pile empty — push discard back into draw_pile +
    // Fisher-Yates shuffle, then draw. Logical reshuffle (no animation); cards lerp from discard
    // position straight to hand which reads as "take cards from discard back" — intuitive for mulligan.
    var _hand_count = 0;
    for (var i = 0; i < 3; i++) if (obj_game.plr_hand[i] != noone) _hand_count++;
    if (_hand_count == 0) {
        show_debug_message("[item mulligan] hand empty — refused");
        return false;
    }

    // Push hand to discard with 凌乱感 layout (matches obj_game DISCARD case logic)
    for (var i = 0; i < 3; i++) {
        var _c = obj_game.plr_hand[i];
        if (_c == noone) continue;
        var _idx = array_length(obj_game.player_discard_pile);
        array_push(obj_game.player_discard_pile, _c);
        _c.target_x = obj_game.DISCARD_X + irandom_range(-18, 18);
        _c.target_y = obj_game.PLR_DISCARD_Y - _idx * obj_game.PILE_OFFSET + irandom_range(-10, 10);
        _c.target_rotation = irandom_range(-12, 12);
        _c.is_moving = true;
        _c.move_speed = 0.15;
        _c.depth = 50 - _idx;
        _c.hoverable = false;
        _c.clickable = false;
        obj_game.plr_hand[i] = noone;
    }

    // Inline reshuffle if draw_pile too small for 3 cards (backlog cleanup).
    if (array_length(obj_game.player_draw_pile) < 3 && array_length(obj_game.player_discard_pile) > 0) {
        var _moved = 0;
        while (array_length(obj_game.player_discard_pile) > 0) {
            var _top_d = array_length(obj_game.player_discard_pile) - 1;
            var _dc = obj_game.player_discard_pile[_top_d];
            array_delete(obj_game.player_discard_pile, _top_d, 1);
            array_push(obj_game.player_draw_pile, _dc);
            _moved++;
        }
        // Fisher-Yates shuffle the merged pile
        var _len = array_length(obj_game.player_draw_pile);
        for (var k = _len - 1; k > 0; k--) {
            var _j = irandom(k);
            var _tmp = obj_game.player_draw_pile[k];
            obj_game.player_draw_pile[k] = obj_game.player_draw_pile[_j];
            obj_game.player_draw_pile[_j] = _tmp;
        }
        show_debug_message("[item mulligan] reshuffled " + string(_moved) + " discard cards into draw pile");
    }

    // Draw 3 (or until pile empty — should never happen now if deck has >=3 total cards)
    var _drawn = 0;
    for (var i = 0; i < 3; i++) {
        if (array_length(obj_game.player_draw_pile) == 0) break;
        var _top = array_length(obj_game.player_draw_pile) - 1;
        var _card = obj_game.player_draw_pile[_top];
        array_delete(obj_game.player_draw_pile, _top, 1);
        obj_game.plr_hand[i] = _card;
        _card.target_x = obj_game.HAND_X[i];
        _card.target_y = obj_game.PLR_HAND_Y;
        _card.is_moving = true;
        _card.move_speed = 0.15;
        _card.depth = -50 - i;
        _card.hoverable = true;
        _card.clickable = true;
        _card.target_rotation = 0;
        if (!_card.face_up) {
            _card.flip_state = 1;
            _card.flip_to_face = true;
        }
        _drawn++;
    }
    _play_sfx(snd_card_move);
    show_debug_message("[item mulligan] discarded " + string(_hand_count) + ", drew " + string(_drawn));
    return true;
}

function _item_handler_reveal_opp_hand_types(tpl) {
    // B2: Reveal ALL face-down opp_hand cards (set is_peek_revealed + flip face-up).
    // Stronger version of peek_opp_hand (covers full hand at once).
    var _revealed = 0;
    for (var i = 0; i < 3; i++) {
        var _c = obj_game.opp_hand[i];
        if (_c == noone) continue;
        if (_c.is_peek_revealed) continue;   // dedupe (D43)
        _c.is_peek_revealed = true;
        _c.flip_state = 1;
        _c.flip_to_face = true;
        _revealed++;
    }
    if (_revealed == 0) {
        show_debug_message("[item reveal_opp_hand_types] all already revealed — refused");
        return false;
    }
    _play_sfx(snd_peek);
    show_debug_message("[item reveal_opp_hand_types] revealed " + string(_revealed) + " opp cards");
    return true;
}

function _item_handler_discard_own_hand(tpl) {
    // B3: Enter card-select mode. Resolution happens in obj_card Step_0 click handler:
    //   if (ui_select_card_mode) → _resolve_select_card_pick(self) → moves card to limbo.
    var _has_card = false;
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] != noone) { _has_card = true; break; }
    }
    if (!_has_card) {
        show_debug_message("[item discard_own_hand] hand empty — refused");
        return false;
    }
    obj_game.ui_select_card_mode = true;
    obj_game.ui_select_card_callback = "discard_own_hand";
    show_debug_message("[item discard_own_hand] click a hand card to exclude this battle");
    return true;
}

function _item_handler_scry_top_3(tpl) {
    // B4: Open OV_SCRY_TOP_3 — snapshot top 3 of player_draw_pile face-up.
    // Resolution: pick 1 → hand, others reshuffle into random positions of draw_pile.
    if (array_length(obj_game.player_draw_pile) == 0) {
        show_debug_message("[item scry_top_3] draw pile empty — refused");
        return false;
    }
    var _slot_open = -1;
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] == noone) { _slot_open = i; break; }
    }
    if (_slot_open < 0) {
        show_debug_message("[item scry_top_3] hand full — refused");
        return false;
    }
    var _scry = [];
    var _top = array_length(obj_game.player_draw_pile) - 1;
    var _take = min(3, array_length(obj_game.player_draw_pile));
    for (var i = 0; i < _take; i++) {
        var _c = obj_game.player_draw_pile[_top - i];
        // 2026-04-26: permanent face-up rule — scry'd cards stay revealed (mark + flip).
        // SHUFFLE_COLLECT respects is_peek_revealed and keeps them face-up.
        _c.is_peek_revealed = true;
        if (!_c.face_up) {
            _c.flip_state = 1;
            _c.flip_to_face = true;
        }
        array_push(_scry, _c);
    }
    obj_game.ui_scry_cards = _scry;
    obj_game.ui_overlay_open = OV_SCRY_TOP_3;
    show_debug_message("[item scry_top_3] showing top " + string(_take) + " for player pick");
    return true;
}

function _item_handler_steal_from_opp_discard(tpl) {
    // B5a: Open OV_PILE_PICKER targeting opp_discard. Click → moves card to plr_hand.
    if (array_length(obj_game.opp_discard_pile) == 0) {
        show_debug_message("[item steal] opp discard empty — refused");
        return false;
    }
    var _slot_open = -1;
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] == noone) { _slot_open = i; break; }
    }
    if (_slot_open < 0) {
        show_debug_message("[item steal] hand full — refused");
        return false;
    }
    obj_game.ui_pile_picker_target = "opp_discard";
    obj_game.ui_overlay_open = OV_PILE_PICKER;
    show_debug_message("[item steal] click an opp discard card to steal");
    return true;
}

function _item_handler_recover_from_own_discard(tpl) {
    // B5b: Open OV_PILE_PICKER targeting player_discard. Click → moves card to plr_hand.
    if (array_length(obj_game.player_discard_pile) == 0) {
        show_debug_message("[item recover] player discard empty — refused");
        return false;
    }
    var _slot_open = -1;
    for (var i = 0; i < 3; i++) {
        if (obj_game.plr_hand[i] == noone) { _slot_open = i; break; }
    }
    if (_slot_open < 0) {
        show_debug_message("[item recover] hand full — refused");
        return false;
    }
    obj_game.ui_pile_picker_target = "player_discard";
    obj_game.ui_overlay_open = OV_PILE_PICKER;
    show_debug_message("[item recover] click a player discard card to take back");
    return true;
}

function _item_handler_force_opp_replay(tpl) {
    // 2026-04-26: enter "select opp hand card" mode. Player picks an opp hand card to swap with
    // current opp_play. Picked card is permanently revealed (is_peek_revealed=true → face-up
    // forever, including across SHUFFLE_COLLECT). Old opp_play returns to that opp_hand slot.
    // Requires: opp_play already set (must be PLAYER_WAIT after OPP_CHOOSE) + ≥1 opp_hand card.
    if (obj_game.opp_play == noone) {
        show_debug_message("[force_opp_replay] opp hasn't played yet — refused (use during PLAYER_WAIT)");
        return false;
    }
    var _has_card = false;
    for (var i = 0; i < 3; i++) {
        if (obj_game.opp_hand[i] != noone) { _has_card = true; break; }
    }
    if (!_has_card) {
        show_debug_message("[force_opp_replay] opp hand empty — refused");
        return false;
    }
    // Enable opp hand cards for hover/click during the picker. obj_card hover_offset is
    // owner-aware (opp pops downward, +18) so cards visually "lift toward play area" on hover,
    // matching the user's "card pulled out before play" feel from the opp side.
    for (var i = 0; i < 3; i++) {
        var _c = obj_game.opp_hand[i];
        if (_c != noone) {
            _c.hoverable = true;
            _c.clickable = true;
        }
    }
    obj_game.ui_select_card_mode = true;
    obj_game.ui_select_card_callback = "force_opp_replay";
    show_debug_message("[force_opp_replay] click an opp hand card to swap with opp_play (revealed permanently)");
    return true;
}
