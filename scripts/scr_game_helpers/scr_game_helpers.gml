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

function _card_type_name_from_instance(_card) {
    if (_card == noone || !instance_exists(_card)) return "";
    return _int_to_card_type_str(_card.card_type);
}

function _card_has_rule_id(_card, _rule_id) {
    if (_card == noone || !instance_exists(_card)) return false;
    for (var i = 0; i < array_length(_card.rules); i++) {
        if (_card.rules[i].id == _rule_id) return true;
    }
    return false;
}

function _card_beats_type(_card, _target_type_name) {
    if (_card == noone || !instance_exists(_card)) return false;
    var _own = _card_type_name_from_instance(_card);
    if (_own == "" || _target_type_name == "") return false;
    if (_get_type_that_beats(_target_type_name) == _own) return true;
    if (_card_has_rule_id(_card, "beat_" + _target_type_name)) return true;
    return false;
}

function _enemy_rules_for_type(_enemy, _type_name) {
    var _rules = [];
    if (is_undefined(_enemy)) return _rules;
    var _comp = _enemy.deck_composition;
    if (!variable_struct_exists(_comp, "rules_by_type")) return _rules;

    var _rules_by_type = _comp.rules_by_type;
    if (!variable_struct_exists(_rules_by_type, _type_name)) return _rules;

    var _ids = _rules_by_type[$ _type_name];
    for (var i = 0; i < array_length(_ids); i++) {
        var _tpl = _get_rule_template_by_id(_ids[i]);
        if (!is_undefined(_tpl)) array_push(_rules, _tpl);
    }
    return _rules;
}

function _enemy_deck_card_structs(_enemy) {
    var _cards = [];
    if (is_undefined(_enemy)) return _cards;

    var _comp = _enemy.deck_composition;
    var _types = ["rock", "scissors", "paper"];
    for (var t = 0; t < 3; t++) {
        var _type_name = _types[t];
        var _count = _comp[$ _type_name] ?? 0;
        for (var c = 0; c < _count; c++) {
            array_push(_cards, new CardStruct(_type_name, _enemy_rules_for_type(_enemy, _type_name)));
        }
    }
    return _cards;
}

function _owner_hand_limit(_owner) {
    var _base = (_owner == "player") ? obj_game.player_hand_limit : obj_game.opp_hand_limit;
    var _bonus = 0;
    for (var i = 0; i < obj_game.MAX_HAND_SLOTS; i++) {
        var _card = (_owner == "player") ? obj_game.plr_hand[i] : obj_game.opp_hand[i];
        if (_card == noone || !instance_exists(_card)) continue;
        for (var r = 0; r < array_length(_card.rules); r++) {
            var _rule = _card.rules[r];
            if (_rule.effect_type == "hand_limit_bonus") {
                _bonus += (_rule.effect_params[$ "amount"] ?? 1) * _rule.level;
            }
        }
    }
    return clamp(_base + _bonus, 1, obj_game.MAX_HAND_SLOTS);
}

function _get_hand_card(_owner, _slot) {
    return (_owner == "player") ? obj_game.plr_hand[_slot] : obj_game.opp_hand[_slot];
}

function _set_hand_card(_owner, _slot, _card) {
    if (_owner == "player") obj_game.plr_hand[_slot] = _card;
    else obj_game.opp_hand[_slot] = _card;
}

function _clear_all_hand_slots() {
    for (var i = 0; i < obj_game.MAX_HAND_SLOTS; i++) {
        obj_game.opp_hand[i] = noone;
        obj_game.plr_hand[i] = noone;
    }
}

function _clear_hand_slot_for_card(_card) {
    for (var i = 0; i < obj_game.MAX_HAND_SLOTS; i++) {
        if (obj_game.opp_hand[i] == _card) obj_game.opp_hand[i] = noone;
        if (obj_game.plr_hand[i] == _card) obj_game.plr_hand[i] = noone;
    }
}

function _hand_missing_count(_owner) {
    var _limit = _owner_hand_limit(_owner);
    var _missing = 0;
    for (var i = 0; i < _limit; i++) {
        if (_get_hand_card(_owner, i) == noone) _missing++;
    }
    return _missing;
}

function _find_first_hand_card_slot(_owner) {
    var _limit = _owner_hand_limit(_owner);
    for (var i = 0; i < _limit; i++) {
        if (_get_hand_card(_owner, i) != noone) return i;
    }
    return -1;
}

function _find_first_empty_player_slot() {
    for (var i = 0; i < obj_game.player_hand_limit; i++) {
        if (obj_game.plr_hand[i] == noone) return i;
    }
    return -1;
}

function _player_hand_card_count() {
    var _count = 0;
    for (var i = 0; i < obj_game.player_hand_limit; i++) {
        if (obj_game.plr_hand[i] != noone) _count++;
    }
    return _count;
}

function _prepare_turn_start_hands() {
    if (obj_game.turn_start_prepared) return;
    obj_game.turn_start_prepared = true;
    _relic_reset_turn_runtime();

    obj_game.ui_active_discard_mode = false;
    obj_game.selected_card = noone;
    obj_game.ui_drag_card = noone;
    obj_game.ui_drag_drop_target = "";

    var _owners = ["opp", "player"];
    for (var o = 0; o < 2; o++) {
        var _owner = _owners[o];
        var _limit = _owner_hand_limit(_owner);
        for (var i = 0; i < obj_game.MAX_HAND_SLOTS; i++) {
            var _card = _get_hand_card(_owner, i);
            if (_card == noone) continue;
            _card.marked_for_discard = false;
            _card.active_discarded_this_turn = false;
            _card.is_dragging = false;
            if (i < _limit) {
                _card.retained_from_previous_turn = true;
                _card.drawn_this_turn = false;
                _card.held_turns += 1;
                _card.hoverable = false;
                _card.clickable = false;
            } else {
                _set_hand_card(_owner, i, noone);
            }
        }
    }

    for (var o2 = 0; o2 < 2; o2++) {
        var _owner2 = _owners[o2];
        var _limit2 = _owner_hand_limit(_owner2);
        for (var j = 0; j < _limit2; j++) {
            var _held = _get_hand_card(_owner2, j);
            if (_held == noone || !instance_exists(_held)) continue;
            if (_held.held_turns <= 0) continue;
            var _ctx = {
                owner: _owner2,
                source_card: _held,
                trigger_reason: "while_held_turn_start",
                rule_depth: 0
            };
            rule_apply_all(_held, "while_held_turn_start", _ctx);
        }
    }
    _relic_on_turn_start_after_held();
}

function _apply_stage_mechanics(_stage) {
    obj_game.player_hand_limit = obj_game.BASE_HAND_LIMIT;
    obj_game.opp_hand_limit = obj_game.BASE_HAND_LIMIT;

    if (!is_undefined(_stage) && variable_struct_exists(_stage, "mechanics")) {
        var _m = _stage.mechanics;
        if (variable_struct_exists(_m, "hand_limit_delta_both")) {
            var _delta = _m.hand_limit_delta_both;
            obj_game.player_hand_limit = clamp(obj_game.player_hand_limit + _delta, 1, obj_game.MAX_HAND_SLOTS);
            obj_game.opp_hand_limit = clamp(obj_game.opp_hand_limit + _delta, 1, obj_game.MAX_HAND_SLOTS);
        }
    }
}

function _build_deal_queue() {
    var _queue = [];
    var _opp_available = array_length(obj_game.opp_draw_pile);
    for (var i = 0; i < obj_game.opp_hand_limit; i++) {
        if (obj_game.opp_hand[i] == noone && _opp_available > 0) {
            array_push(_queue, { owner: "opp", slot: i });
            _opp_available--;
        }
    }

    var _plr_available = array_length(obj_game.player_draw_pile);
    for (var j = 0; j < obj_game.player_hand_limit; j++) {
        if (obj_game.plr_hand[j] == noone && _plr_available > 0) {
            array_push(_queue, { owner: "player", slot: j });
            _plr_available--;
        }
    }
    return _queue;
}

function _deal_one_card_to_slot(_owner, _slot, _depth_step) {
    if (_get_hand_card(_owner, _slot) != noone) return false;
    var _pile = (_owner == "player") ? obj_game.player_draw_pile : obj_game.opp_draw_pile;
    if (array_length(_pile) == 0) return false;

    var _last = array_length(_pile) - 1;
    var _card = _pile[_last];
    array_delete(_pile, _last, 1);
    if (_owner == "player") obj_game.player_draw_pile = _pile;
    else obj_game.opp_draw_pile = _pile;

    _set_hand_card(_owner, _slot, _card);
    _card.target_x = obj_game.HAND_X[_slot];
    _card.target_y = (_owner == "player") ? obj_game.PLR_HAND_Y : obj_game.OPP_HAND_Y;
    _card.target_rotation = 0;
    _card.is_moving = true;
    _card.move_speed = 0.15;
    _card.depth = -50 - _depth_step;
    _card.drawn_this_turn = true;
    _card.retained_from_previous_turn = false;
    _card.held_turns = 0;
    _card.marked_for_discard = false;
    _card.active_discarded_this_turn = false;
    _card.hoverable = false;
    _card.clickable = false;
    var _ctx = {
        owner: _owner,
        source_card: _card,
        trigger_reason: "on_draw",
        rule_depth: 0
    };
    rule_apply_all(_card, "on_draw", _ctx);
    return true;
}

function _draw_one_to_hand(_owner) {
    var _slot = -1;
    var _limit = _owner_hand_limit(_owner);
    for (var i = 0; i < _limit; i++) {
        if (_get_hand_card(_owner, i) == noone) {
            _slot = i;
            break;
        }
    }
    if (_slot < 0) return false;

    var _pile = (_owner == "player") ? obj_game.player_draw_pile : obj_game.opp_draw_pile;
    var _discard = (_owner == "player") ? obj_game.player_discard_pile : obj_game.opp_discard_pile;
    if (array_length(_pile) == 0 && array_length(_discard) > 0) {
        while (array_length(_discard) > 0) {
            var _last_d = array_length(_discard) - 1;
            var _dc = _discard[_last_d];
            array_delete(_discard, _last_d, 1);
            array_push(_pile, _dc);
        }
        if (_owner == "player") {
            obj_game.player_draw_pile = _pile;
            obj_game.player_discard_pile = _discard;
        } else {
            obj_game.opp_draw_pile = _pile;
            obj_game.opp_discard_pile = _discard;
        }
        _shuffle_pile_by_owner(_owner);
    }
    if (array_length((_owner == "player") ? obj_game.player_draw_pile : obj_game.opp_draw_pile) == 0) return false;
    var _ok = _deal_one_card_to_slot(_owner, _slot, 20 + _slot);
    if (_ok && _owner == "player" && obj_game.state == "PLAYER_WAIT") {
        var _drawn = _get_hand_card("player", _slot);
        if (_drawn != noone && instance_exists(_drawn)) {
            if (!_drawn.face_up) {
                _drawn.flip_state = 1;
                _drawn.flip_to_face = true;
                _play_battle_sfx("card_flip");
            }
            _drawn.hoverable = true;
            _drawn.clickable = true;
        }
    }
    return _ok;
}

function _move_card_to_draw_pile_top(_card, _public_reveal) {
    if (_card == noone || !instance_exists(_card)) return;
    if (_public_reveal && !_card.face_up) {
        _card.flip_state = 1;
        _card.flip_to_face = true;
    }
    _clear_hand_slot_for_card(_card);
    if (_card == obj_game.opp_play) obj_game.opp_play = noone;
    if (_card == obj_game.plr_play) obj_game.plr_play = noone;

    var _owner = _card.card_owner;
    var _pile = (_owner == "player") ? obj_game.player_draw_pile : obj_game.opp_draw_pile;
    var _pile_idx = array_length(_pile);
    array_push(_pile, _card); // draw top is the array end.
    if (_owner == "player") obj_game.player_draw_pile = _pile;
    else obj_game.opp_draw_pile = _pile;

    var _draw_y = (_owner == "player") ? obj_game.PLR_DRAW_Y : obj_game.OPP_DRAW_Y;
    _card.target_x = obj_game.DRAW_X;
    _card.target_y = _draw_y - _pile_idx * obj_game.PILE_OFFSET;
    _card.target_rotation = 0;
    _card.is_moving = true;
    _card.move_speed = 0.18;
    _card.depth = 50 - _pile_idx;
    _card.hoverable = false;
    _card.clickable = false;
    if (_card.face_up && !_card.is_peek_revealed) {
        _card.flip_state = 1;
        _card.flip_to_face = false;
    }
    _play_battle_sfx("shuffle");
}

function _move_card_to_draw_pile_random(_card, _public_reveal) {
    if (_card == noone || !instance_exists(_card)) return;
    _clear_hand_slot_for_card(_card);
    if (_card == obj_game.opp_play) obj_game.opp_play = noone;
    if (_card == obj_game.plr_play) obj_game.plr_play = noone;

    var _owner = _card.card_owner;
    var _pile = (_owner == "player") ? obj_game.player_draw_pile : obj_game.opp_draw_pile;
    var _insert = irandom(array_length(_pile));
    if (_insert >= array_length(_pile)) array_push(_pile, _card);
    else array_insert(_pile, _insert, _card);
    if (_owner == "player") obj_game.player_draw_pile = _pile;
    else obj_game.opp_draw_pile = _pile;

    var _draw_y = (_owner == "player") ? obj_game.PLR_DRAW_Y : obj_game.OPP_DRAW_Y;
    for (var i = 0; i < array_length(_pile); i++) {
        var _c = _pile[i];
        if (!instance_exists(_c)) continue;
        _c.target_x = obj_game.DRAW_X;
        _c.target_y = _draw_y - i * obj_game.PILE_OFFSET;
        _c.target_rotation = 0;
        _c.depth = 50 - i;
        _c.is_moving = true;
        _c.move_speed = 0.18;
        _c.hoverable = false;
        _c.clickable = false;
        if (_c.face_up && !_c.is_peek_revealed) {
            _c.flip_state = 1;
            _c.flip_to_face = false;
        }
    }
    _play_battle_sfx("shuffle");
}

function _peek_enemy_hand(_owner) {
    var _target_owner = (_owner == "player") ? "opp" : "player";
    var _limit = _owner_hand_limit(_target_owner);
    var _candidates = [];
    for (var i = 0; i < _limit; i++) {
        var _c = _get_hand_card(_target_owner, i);
        if (_c != noone && instance_exists(_c) && !_c.face_up && !_c.is_peek_revealed) {
            array_push(_candidates, _c);
        }
    }
    if (_target_owner == "opp" && obj_game.opp_play != noone && !obj_game.opp_play.face_up && !obj_game.opp_play.is_peek_revealed) {
        array_push(_candidates, obj_game.opp_play);
    }
    if (_target_owner == "player" && obj_game.plr_play != noone && !obj_game.plr_play.face_up && !obj_game.plr_play.is_peek_revealed) {
        array_push(_candidates, obj_game.plr_play);
    }
    if (array_length(_candidates) == 0) return false;
    var _target = _candidates[irandom(array_length(_candidates) - 1)];
    _target.is_peek_revealed = true;
    _target.flip_state = 1;
    _target.flip_to_face = true;
    _target.ui_pulse_timer = 26;
    if (_owner == "player") _relic_on_peek_enemy();
    _play_sfx(snd_peek);
    return true;
}

function _add_random_trait_to_instance(_card) {
    if (_card == noone || !instance_exists(_card)) return false;
    var _pool = _get_random_trait_pool();
    var _legal = [];
    for (var i = 0; i < array_length(_pool); i++) {
        var _tpl = _get_rule_template_by_id(_pool[i]);
        if (!is_undefined(_tpl) && _is_legal_target(_tpl, _card)) array_push(_legal, _tpl);
    }
    if (array_length(_legal) == 0) return false;
    var _picked = variable_clone(_legal[irandom(array_length(_legal) - 1)], 10);
    array_push(_card.rules, _picked);
    show_debug_message("[trait] random gained " + _picked.id);
    return true;
}

function _apply_active_discard_effects(_card) {
    if (_card == noone || !instance_exists(_card)) return;
    var _owner = _card.card_owner;
    var _ctx_self = {
        owner: _owner,
        source_card: _card,
        discarded_card: _card,
        trigger_reason: "on_active_discard",
        rule_depth: 0
    };
    rule_apply_all(_card, "on_active_discard", _ctx_self);

    var _limit = _owner_hand_limit(_owner);
    for (var i = 0; i < _limit; i++) {
        var _held = _get_hand_card(_owner, i);
        if (_held == noone || !instance_exists(_held) || _held == _card) continue;
        var _ctx_held = {
            owner: _owner,
            source_card: _held,
            discarded_card: _card,
            trigger_reason: "held_on_owner_active_discard",
            rule_depth: 0
        };
        rule_apply_all(_held, "held_on_owner_active_discard", _ctx_held);
    }

    var _owners = ["player", "opp"];
    for (var o = 0; o < 2; o++) {
        var _obs_owner = _owners[o];
        var _obs_limit = _owner_hand_limit(_obs_owner);
        for (var j = 0; j < _obs_limit; j++) {
            var _obs = _get_hand_card(_obs_owner, j);
            if (_obs == noone || !instance_exists(_obs) || _obs == _card) continue;
            var _ctx_any = {
                owner: _obs_owner,
                source_card: _obs,
                discarded_card: _card,
                trigger_reason: "on_any_active_discard",
                rule_depth: 0
            };
            rule_apply_all(_obs, "on_any_active_discard", _ctx_any);
        }
    }

    _relic_on_active_discard(_card, _owner);
}

function _move_card_to_discard_pile(_card, _public_reveal) {
    if (_card == noone || !instance_exists(_card)) return;

    if (obj_game.ui_drag_card == _card) {
        obj_game.ui_drag_card = noone;
        obj_game.ui_drag_drop_target = "";
    }
    _card.is_dragging = false;

    if (_public_reveal && !_card.face_up) {
        _card.flip_state = 1;
        _card.flip_to_face = true;
    }
    _card.is_peek_revealed = false;
    _card.marked_for_discard = false;
    _card.active_discarded_this_turn = true;
    _card.discard_route_override = "";

    if (_card == obj_game.opp_play) obj_game.opp_play = noone;
    if (_card == obj_game.plr_play) obj_game.plr_play = noone;
    _clear_hand_slot_for_card(_card);

    _apply_active_discard_effects(_card);

    if (_card.discard_route_override == "draw_top") {
        _move_card_to_draw_pile_top(_card, _public_reveal);
        return;
    }

    var _pile_idx = 0;
    if (_card.card_owner == "player") {
        _pile_idx = array_length(obj_game.player_discard_pile);
        array_push(obj_game.player_discard_pile, _card);
    } else {
        _pile_idx = array_length(obj_game.opp_discard_pile);
        array_push(obj_game.opp_discard_pile, _card);
    }

    var _disc_y = (_card.card_owner == "player") ? obj_game.PLR_DISCARD_Y : obj_game.OPP_DISCARD_Y;
    _card.target_x = obj_game.DISCARD_X + irandom_range(-18, 18);
    _card.target_y = _disc_y - _pile_idx * obj_game.PILE_OFFSET + irandom_range(-10, 10);
    _card.target_rotation = irandom_range(-12, 12);
    _card.is_moving = true;
    _card.move_speed = 0.15;
    _card.depth = 50 - _pile_idx;
    _card.hoverable = false;
    _card.clickable = false;
    _play_battle_sfx("card_drop_discard");
}

function _player_play_drop_rect() {
    return {
        x: obj_game.PLR_PLAY_X - 18,
        y: obj_game.PLR_PLAY_Y - 18,
        w: 136,
        h: 176
    };
}

function _player_discard_drop_rect() {
    return {
        x: obj_game.DISCARD_X - 12,
        y: obj_game.PLR_DISCARD_Y - 12,
        w: 124,
        h: 164
    };
}

function _point_in_rect_struct(_r, _px, _py) {
    return point_in_rectangle(_px, _py, _r.x, _r.y, _r.x + _r.w, _r.y + _r.h);
}

function _player_drag_drop_target() {
    var _play_r = _player_play_drop_rect();
    if (_point_in_rect_struct(_play_r, mouse_x, mouse_y)) return "play";

    var _discard_r = _player_discard_drop_rect();
    if (_point_in_rect_struct(_discard_r, mouse_x, mouse_y)) {
        return (_player_hand_card_count() > 1) ? "discard" : "discard_blocked";
    }
    return "";
}

function _begin_player_card_drag(_card) {
    if (_card == noone || !instance_exists(_card)) return;
    if (obj_game.state != "PLAYER_WAIT") return;
    if (obj_game.ui_select_card_mode) return;
    if (!_is_player_hand_card(_card)) return;

    obj_game.selected_card = noone;
    obj_game.ui_active_discard_mode = false;
    obj_game.ui_drag_card = _card;
    obj_game.ui_drag_drop_target = "";

    _card.is_dragging = true;
    _card.drag_offset_x = mouse_x - _card.x;
    _card.drag_offset_y = mouse_y - _card.y;
    _card.drag_return_x = _card.x;
    _card.drag_return_y = _card.y;
    _card.drag_return_rotation = _card.target_rotation;
    _card.is_moving = false;
    _card.target_rotation = 0;
    _card.depth = -200;
    _card.hoverable = false;
    _play_battle_sfx("card_drag_start");
}

function _update_player_card_drag(_card) {
    if (_card == noone || !instance_exists(_card)) return;
    _card.x = mouse_x - _card.drag_offset_x;
    _card.y = mouse_y - _card.drag_offset_y;
    _card.target_x = _card.x;
    _card.target_y = _card.y;
    _card.target_rotation = 0;
    _card.current_rotation = lerp(_card.current_rotation, 0, 0.35);
    _card.hover_offset = 0;
    _card.depth = -200;
    obj_game.ui_drag_drop_target = _player_drag_drop_target();
}

function _return_dragged_card_to_hand(_card) {
    if (_card == noone || !instance_exists(_card)) return;
    _card.target_x = _card.drag_return_x;
    _card.target_y = _card.drag_return_y;
    _card.target_rotation = _card.drag_return_rotation;
    _card.is_moving = true;
    _card.move_speed = 0.22;
    _card.hoverable = true;
    _card.clickable = true;
    _play_battle_sfx("card_drop_return");
}

function _finish_player_card_drag(_card) {
    if (_card == noone || !instance_exists(_card)) return;
    var _target = obj_game.ui_drag_drop_target;
    if (_target == "") _target = _player_drag_drop_target();

    obj_game.ui_drag_card = noone;
    obj_game.ui_drag_drop_target = "";
    _card.is_dragging = false;

    switch (_target) {
        case "play":
            show_debug_message("[drag] player card dropped to PLAY");
            _player_commit_play(_card);
            return;
        case "discard":
            show_debug_message("[drag] player card dropped to DISCARD");
            _move_card_to_discard_pile(_card, true);
            return;
        case "discard_blocked":
            show_debug_message("[drag] discard refused: player must keep one card to play");
            _return_dragged_card_to_hand(_card);
            return;
    }

    _return_dragged_card_to_hand(_card);
}

function _disable_hand_input(_owner) {
    var _limit = _owner_hand_limit(_owner);
    for (var i = 0; i < _limit; i++) {
        var _card = _get_hand_card(_owner, i);
        if (_card != noone) {
            _card.hoverable = false;
            _card.clickable = false;
        }
    }
}

function _apply_card_on_play(_card, _owner, _opponent_card) {
    if (_card == noone) return;
    var _ctx = {
        owner: _owner,
        source_card: _card,
        opponent_card: _opponent_card,
        trigger_reason: "on_play",
        rule_depth: 0
    };
    rule_apply_all(_card, "on_play", _ctx);
}

function _get_card_win_damage(_card) {
    if (_card == noone) return 1;
    return 1 + max(0, _card.win_damage_bonus);
}

function _run_battle_total() {
    var _total = 0;
    for (var i = 0; i < array_length(obj_game.map); i++) {
        if (obj_game.map[i].type == "battle") _total++;
    }
    return max(1, _total);
}

function _opp_commit_play_slot(_slot) {
    if (_slot < 0 || _slot >= obj_game.opp_hand_limit) return false;
    var _card = obj_game.opp_hand[_slot];
    if (_card == noone) return false;

    show_debug_message("[qa] opp_commit stage=" + obj_game.current_stage_id
        + " slot=" + string(_slot)
        + " type=" + _int_to_card_type_str(_card.card_type)
        + " dmg=" + string(_get_card_win_damage(_card)));

    obj_game.opp_play = _card;
    obj_game.opp_hand[_slot] = noone;
    _card.target_x = obj_game.OPP_PLAY_X;
    _card.target_y = obj_game.OPP_PLAY_Y;
    _card.target_rotation = 0;
    _card.is_moving = true;
    _card.move_speed = 0.10;
    _card.depth = -60;
    _card.hoverable = false;
    _card.clickable = false;
    _play_battle_sfx("card_land_play");
    _apply_card_on_play(_card, "opp", obj_game.plr_play);
    return true;
}

function _opp_commit_plan(_play_slot, _discard_slots) {
    for (var i = 0; i < array_length(_discard_slots); i++) {
        var _slot = _discard_slots[i];
        if (_slot == _play_slot) continue;
        if (_slot >= 0 && _slot < obj_game.opp_hand_limit && obj_game.opp_hand[_slot] != noone) {
            _move_card_to_discard_pile(obj_game.opp_hand[_slot], true);
        }
    }
    return _opp_commit_play_slot(_play_slot);
}

function _ai_first_slot_of_type(_type_int) {
    for (var i = 0; i < obj_game.opp_hand_limit; i++) {
        if (obj_game.opp_hand[i] != noone && obj_game.opp_hand[i].card_type == _type_int) return i;
    }
    return -1;
}

function _ai_highest_damage_slot_from_slots(_slots) {
    var _best = -1;
    var _best_bonus = -100000;
    for (var i = 0; i < array_length(_slots); i++) {
        var _slot = _slots[i];
        var _card = obj_game.opp_hand[_slot];
        if (_card == noone) continue;
        var _bonus = _card.win_damage_bonus;
        if (_best < 0 || _bonus > _best_bonus || (_bonus == _best_bonus && _slot < _best)) {
            _best = _slot;
            _best_bonus = _bonus;
        }
    }
    return _best;
}

function _ai_stage3_pick_slot() {
    var _rock = _ai_first_slot_of_type(0);
    if (_rock >= 0) return _rock;
    return _find_first_hand_card_slot("opp");
}

function _ai_stage4_pick_slot_and_discards() {
    var _paper_slots = [];
    var _non_paper_slots = [];
    for (var i = 0; i < obj_game.opp_hand_limit; i++) {
        var _card = obj_game.opp_hand[i];
        if (_card == noone) continue;
        if (_card.card_type == 2) array_push(_paper_slots, i);
        else array_push(_non_paper_slots, i);
    }

    var _play_slot = -1;
    if (array_length(_paper_slots) >= 3) {
        _play_slot = _ai_highest_damage_slot_from_slots(_paper_slots);
    } else if (array_length(_non_paper_slots) > 0) {
        _play_slot = _non_paper_slots[0];
    } else {
        _play_slot = _ai_highest_damage_slot_from_slots(_paper_slots);
    }

    var _discard_slots = [];
    for (var j = 0; j < array_length(_non_paper_slots); j++) {
        var _slot = _non_paper_slots[j];
        if (_slot != _play_slot) array_push(_discard_slots, _slot);
    }
    return { play_slot: _play_slot, discard_slots: _discard_slots };
}

/// @desc D48/D58 AI rule F: "after losing, play the type that beats player's last play".
/// Returns opp_hand slot index (0-2) to play, or -1 if no match (caller should fallback random).
/// @param _last_type String — player's last play type ("rock"|"scissors"|"paper"|"")
/// @param _player_won_last Bool — whether player won the last round (enemy was beaten)
function _ai_stage1_f_pick(_last_type, _player_won_last) {
    if (!_player_won_last || _last_type == "") return -1;
    var _target_int = _str_to_card_type_int(_get_type_that_beats(_last_type));
    var _matches = [];
    for (var i = 0; i < obj_game.opp_hand_limit; i++) {
        if (obj_game.opp_hand[i] != noone && obj_game.opp_hand[i].card_type == _target_int) {
            array_push(_matches, i);
        }
    }
    if (array_length(_matches) == 0) return -1;
    return _matches[0];
}

/// @desc D48/D59 H1 hidden draw algorithm: swap opp hand cards with draw pile to guarantee
/// at least one of each RPS type in hand. Only runs if current_stage_has_h1 = true.
/// Players don't see this — it happens while enemy cards are still face-down.
function _ai_h1_check_and_fix() {
    if (!obj_game.current_stage_has_h1) return;

    var _counts = { rock: 0, scissors: 0, paper: 0 };
    var _limit = obj_game.opp_hand_limit;
    for (var i = 0; i < _limit; i++) {
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
        for (var i = 0; i < _limit; i++) {
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
        array_insert(obj_game.opp_draw_pile, 0, _old);
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
            var _rules = [];
            if (variable_struct_exists(_comp, "rules_by_type")) {
                var _rules_by_type = _comp.rules_by_type;
                if (variable_struct_exists(_rules_by_type, _type_name)) {
                    var _ids = _rules_by_type[$ _type_name];
                    for (var r = 0; r < array_length(_ids); r++) {
                        var _tpl = _get_rule_template_by_id(_ids[r]);
                        if (!is_undefined(_tpl)) array_push(_rules, _tpl);
                    }
                }
            }
            var _struct = new CardStruct(_type_name, _rules);
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
    var _stg_1 = _get_stage_by_id("stage_1");
    var _stg_7 = _get_stage_by_id("level_b07_final");
    var _t3 = !is_undefined(_stg_1) && !is_undefined(_stg_7)
          && variable_struct_exists(_stg_1, "rewards")
          && variable_struct_exists(_stg_1, "has_h1")
          && variable_struct_exists(_stg_1, "rule_pool")
          && _stg_1.has_h1 == false
          && _stg_7.has_h1 == true;
    if (_t3) { _passed++; show_debug_message("[PASS T3] stage config integrity (D55/D59)"); }
    else { _failed++; show_debug_message("[FAIL T3] stage config integrity"); }

    // T4: enemy template lookup + D54 no-name schema + ai_params.type present
    var _e1 = _get_enemy_template_by_id("enemy_b01_intro_dummy");
    var _e7 = _get_enemy_template_by_id("enemy_stage7_final");
    var _t4 = !is_undefined(_e1) && !is_undefined(_e7)
          && _e1.max_hp == 3 && _e7.max_hp == 10
          && _e1.ai_params.type == "fixed_first"
          && _e7.ai_params.type == "stage1_f"
          && !variable_struct_exists(_e1, "name");  // D54: no name field
    if (_t4) { _passed++; show_debug_message("[PASS T4] enemy config integrity (D54/D58)"); }
    else { _failed++; show_debug_message("[FAIL T4] enemy config integrity"); }

    // T5: relic template lookup
    var _relic = _get_relic_template_by_id("shuffle_funnel");
    var _t5 = !is_undefined(_relic)
          && variable_struct_exists(_relic, "cost")
          && variable_struct_exists(_relic, "description_text");
    if (_t5) { _passed++; show_debug_message("[PASS T5] relic config"); }
    else { _failed++; show_debug_message("[FAIL T5] relic config"); }

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

    // T8: stage_1 rule_pool contains the basic RPS teaching rules.
    var _rp = _stg_1.rule_pool;
    var _t8 = array_length(_rp) == 3
          && array_contains(_rp, "beat_rock")
          && array_contains(_rp, "beat_paper")
          && array_contains(_rp, "beat_scissors");
    if (_t8) { _passed++; show_debug_message("[PASS T8] stage_1 basic rule_pool"); }
    else { _failed++; show_debug_message("[FAIL T8] stage_1 basic rule_pool broken"); }

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
        obj_game.state = "RUN_MAP";
        obj_game.wait_timer = 0;
        room_goto(rm_run_map);
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
        case "reward":
            _mgr_advance_reward();
            break;
        case "starter_unused":
            // Else (starter at RUN_START of a regular run) → proceed to first battle.
            obj_game.state = "BATTLE_START";
            obj_game.wait_timer = 10;
            room_goto(room0);
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
    if (obj_game.current_battle_index >= 3) {
        _clear_all_card_instances();
        _clear_all_hand_slots();
        obj_game.opp_play = noone;
        obj_game.plr_play = noone;
        obj_game.player_draw_pile = [];
        obj_game.player_discard_pile = [];
        obj_game.opp_draw_pile = [];
        obj_game.opp_discard_pile = [];
        obj_game.discard_queue = [];
        obj_game.deal_queue = [];
        obj_game.selected_card = noone;
        obj_game.ui_drag_card = noone;
        obj_game.ui_drag_drop_target = "";
        obj_game.ui_active_discard_mode = false;
        obj_game.ui_overlay_open = OV_NONE;
        obj_game.state = "RUN_CONTENT_WIP";
        obj_game.wait_timer = 15;
        show_debug_message("[advance_reward] stage 4 complete -> RUN_CONTENT_WIP");
        room_goto(room0);
        return;
    }
    var _next_pos = obj_game.map_position + 1;
    if (_next_pos >= array_length(obj_game.map)) {
        obj_game.state = "RUN_VICTORY";
        obj_game.wait_timer = 15;
        show_debug_message("[advance_reward] last battle → RUN_VICTORY");
        room_goto(room0);
    } else {
        obj_game.map_position = _next_pos;
        obj_game.current_branch_line = "";
        obj_game.current_branch_sub_index = 0;
        var _next_node = obj_game.map[obj_game.map_position];
        if (_next_node.type == "branch_marker") {
            obj_game.state = "RUN_MAP_BRANCH";
            room_goto(rm_run_map);
            return;
        } else {
            obj_game.state = "RUN_MAP";
            obj_game.wait_timer = 0;
            room_goto(rm_run_map);
            return;
        }
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
    _play_battle_sfx("card_commit");
    if (obj_game.ui_drag_card == _card) {
        obj_game.ui_drag_card = noone;
        obj_game.ui_drag_drop_target = "";
    }
    _card.is_dragging = false;

    show_debug_message("[qa] player_commit stage=" + obj_game.current_stage_id
        + " type=" + _int_to_card_type_str(_card.card_type)
        + " dmg=" + string(_get_card_win_damage(_card)));

    // Active discards resolve before the played card commits.
    for (var d = 0; d < obj_game.player_hand_limit; d++) {
        var _dc = obj_game.plr_hand[d];
        if (_dc != noone && _dc != _card && _dc.marked_for_discard) {
            _move_card_to_discard_pile(_dc, true);
        }
    }

    _relic_on_player_commit_play_pre(_card);

    obj_game.plr_play = _card;
    _card.marked_for_discard = false;

    // Remove from plr_hand (exactly one slot matches _card)
    for (var i = 0; i < obj_game.player_hand_limit; i++) {
        if (obj_game.plr_hand[i] == _card) {
            obj_game.plr_hand[i] = noone;
            break;
        }
    }

    // Disable input on remaining hand cards
    _disable_hand_input("player");
    obj_game.plr_play.hoverable = false;
    obj_game.plr_play.clickable = false;

    obj_game.plr_play.target_x = obj_game.PLR_PLAY_X;
    obj_game.plr_play.target_y = obj_game.PLR_PLAY_Y;
    obj_game.plr_play.is_moving = true;
    obj_game.plr_play.move_speed = 0.10;
    obj_game.plr_play.depth = -60;
    _play_battle_sfx("card_land_play");
    // 2026-04-27: snd_card_move removed here — snd_duel_commit at line 657 covers commit moment.
    // Per user "应该是只有commit duel, 没有牌移动或者发牌的音效".

    _apply_card_on_play(obj_game.plr_play, "player", obj_game.opp_play);
    obj_game.selected_card = noone;
    obj_game.ui_active_discard_mode = false;
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

/// instead of occupying separate slot. Per user "正常逻辑不应该是同类合并 XX 道具 *3,
/// 用一个变为 *2. 用完就没有了".

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
        _play_battle_sfx("card_drop_return");
        show_debug_message("[select] toggled OFF — card returns to fan");
        return;
    }
    // Switching selection: play recall for old, then move/play for new.
    if (obj_game.selected_card != noone) {
        _play_battle_sfx("card_drop_return");
    }
    obj_game.selected_card = card_id;
    card_id.target_x = obj_game.PLR_PLAY_X;
    card_id.target_y = obj_game.PLR_PLAY_Y;
    card_id.target_rotation = 0;
    card_id.is_moving = true;
    card_id.move_speed = 0.18;
    card_id.depth = -60;
    _play_battle_sfx("card_land_play");
    show_debug_message("[select] previewing card at PLR_PLAY position");
}

function _is_player_hand_card(card_id) {
    for (var i = 0; i < obj_game.player_hand_limit; i++) {
        if (obj_game.plr_hand[i] == card_id) return true;
    }
    return false;
}

function _toggle_player_discard_mark(card_id) {
    if (!_is_player_hand_card(card_id)) return;
    if (obj_game.selected_card == card_id) {
        obj_game.selected_card = noone;
    }
    card_id.marked_for_discard = !card_id.marked_for_discard;
    _play_battle_sfx("card_drop_discard");
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
            for (var i = 0; i < obj_game.opp_hand_limit; i++) {
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
            var _angle_rad_old = degtorad((_opp_slot - (obj_game.opp_hand_limit - 1) / 2) * obj_game.HAND_FAN_ANGLE_DEG);
            var _dx_old = sin(_angle_rad_old) * obj_game.HAND_FAN_RADIUS;
            var _dy_old = cos(_angle_rad_old) * obj_game.HAND_FAN_RADIUS;   // +cos = downward (mirror of plr)
            _old_opp_play.target_x = obj_game.HAND_FAN_PIVOT_X + _dx_old;
            _old_opp_play.target_y = obj_game.OPP_HAND_FAN_PIVOT_Y + _dy_old;
            _old_opp_play.is_moving = true;
            _old_opp_play.move_speed = 0.10;
            _old_opp_play.depth = -50 - _opp_slot;

            _play_battle_sfx("card_land_play");
            show_debug_message("[force_opp_replay resolve] swapped opp_hand[" + string(_opp_slot)
                + "] ↔ opp_play (new opp_play permanently revealed)");
            break;

        case "discard_own_hand":
            // Find which hand slot this card is in
            var _slot = -1;
            for (var i = 0; i < obj_game.player_hand_limit; i++) {
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
            _play_battle_sfx("card_drop_discard");
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
        for (var _ii = 0; _ii < obj_game.opp_hand_limit; _ii++) {
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
