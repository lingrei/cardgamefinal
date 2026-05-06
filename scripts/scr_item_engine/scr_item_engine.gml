
function _relic_index(_relic_id) {
    for (var i = 0; i < array_length(obj_game.relics); i++) {
        if (obj_game.relics[i].id == _relic_id) return i;
    }
    return -1;
}

function _add_relic_to_run(_relic_id) {
    var _tpl = _get_relic_template_by_id(_relic_id);
    if (is_undefined(_tpl)) return false;
    if (_relic_index(_relic_id) >= 0) return false;
    array_push(obj_game.relics, variable_clone(_tpl, 5));
    show_debug_message("[relic] gained " + _relic_id + " (count=" + string(array_length(obj_game.relics)) + ")");
    return true;
}

function _pulse_relic(_relic_id) {
    var _idx = _relic_index(_relic_id);
    if (_idx >= 0) obj_game.relics[_idx].pulse_timer = 32;
}

function _boost_card_win_damage(_card, _amount, _reason) {
    if (_card == noone || !instance_exists(_card)) return false;
    _card.win_damage_bonus += _amount;
    _card.ui_pulse_timer = 24;
    show_debug_message("[boost] " + string(_reason) + " card=" + string(_card.card_type) + " +" + string(_amount) + " => " + string(_card.win_damage_bonus));
    return true;
}

function _get_hand_cards_array(_owner) {
    var _cards = [];
    var _limit = _owner_hand_limit(_owner);
    for (var i = 0; i < _limit; i++) {
        var _c = _get_hand_card(_owner, i);
        if (_c != noone && instance_exists(_c)) array_push(_cards, _c);
    }
    return _cards;
}

function _boost_random_hand_card(_owner, _amount, _reason) {
    var _cards = _get_hand_cards_array(_owner);
    if (array_length(_cards) == 0) return false;
    var _target = _cards[irandom(array_length(_cards) - 1)];
    return _boost_card_win_damage(_target, _amount, _reason);
}

function _relic_reset_battle_runtime() {
    obj_game.relic_protective_knot_spent = false;
    obj_game.relic_cold_box_seen = [];
}

function _relic_reset_turn_runtime() {
    obj_game.relic_player_discarded_this_turn = false;
    obj_game.relic_first_player_discard_done = false;
    obj_game.relic_ember_type = "";
    obj_game.relic_ember_ready = false;
    obj_game.relic_ballast_card = noone;
}

function _relic_tick_ui() {
    for (var i = 0; i < array_length(obj_game.relics); i++) {
        if (obj_game.relics[i].pulse_timer > 0) obj_game.relics[i].pulse_timer--;
    }
}

function _relic_on_battle_start() {
    _relic_reset_battle_runtime();

    var _counts = _count_deck_by_type();
    var _major = "rock";
    if (_counts.scissors > _counts[$ _major]) _major = "scissors";
    if (_counts.paper > _counts[$ _major]) _major = "paper";

    var _minor = "rock";
    if (_counts.scissors < _counts[$ _minor]) _minor = "scissors";
    if (_counts.paper < _counts[$ _minor]) _minor = "paper";

    if (_has_relic_id("zealot_mask")) {
        _boost_player_battle_type(_major, 1, "zealot_mask");
        _pulse_relic("zealot_mask");
    }
    if (_has_relic_id("balance_scales")) {
        _boost_player_battle_type(_minor, 2, "balance_scales");
        _pulse_relic("balance_scales");
    }
}

function _boost_player_battle_type(_type_name, _amount, _reason) {
    var _type_int = _str_to_card_type_int(_type_name);
    for (var i = 0; i < array_length(obj_game.player_draw_pile); i++) {
        var _c = obj_game.player_draw_pile[i];
        if (instance_exists(_c) && _c.card_type == _type_int) {
            _boost_card_win_damage(_c, _amount, _reason);
        }
    }
}

function _relic_on_turn_start_after_held() {
    if (_has_relic_id("ballast_stone")) {
        var _best = noone;
        var _best_turns = -1;
        var _cards = _get_hand_cards_array("player");
        for (var i = 0; i < array_length(_cards); i++) {
            var _c = _cards[i];
            if (_c.held_turns > _best_turns) {
                _best = _c;
                _best_turns = _c.held_turns;
            }
        }
        if (_best != noone && _best_turns > 0) {
            _boost_card_win_damage(_best, 1, "ballast_stone");
            obj_game.relic_ballast_card = _best;
            _pulse_relic("ballast_stone");
        }
    }

    if (_has_relic_id("cold_box")) {
        var _cards2 = _get_hand_cards_array("player");
        for (var j = 0; j < array_length(_cards2); j++) {
            var _card = _cards2[j];
            if (_card.held_turns >= 2 && !_card.cold_box_granted) {
                if (_add_random_trait_to_instance(_card)) {
                    _card.cold_box_granted = true;
                    _card.ui_pulse_timer = 28;
                    _pulse_relic("cold_box");
                }
            }
        }
    }
}

function _relic_on_peek_enemy() {
    if (_has_relic_id("observation_mirror")) {
        if (_boost_random_hand_card("player", 1, "observation_mirror")) {
            _pulse_relic("observation_mirror");
        }
    }
}

function _relic_on_player_commit_play_pre(_card) {
    if (_card == noone) return;

    if (_has_relic_id("copy_seal")) {
        var _same = 0;
        for (var i = 0; i < obj_game.player_hand_limit; i++) {
            var _hc = obj_game.plr_hand[i];
            if (_hc != noone && _hc != _card && _hc.card_type == _card.card_type) _same++;
        }
        if (_same > 0) {
            _boost_card_win_damage(_card, _same, "copy_seal");
            _pulse_relic("copy_seal");
        }
    }

    if (_has_relic_id("tri_compass")) {
        var _seen = [false, false, false];
        _seen[_card.card_type] = true;
        for (var j = 0; j < obj_game.player_hand_limit; j++) {
            var _h = obj_game.plr_hand[j];
            if (_h != noone) _seen[_h.card_type] = true;
        }
        if (_seen[0] && _seen[1] && _seen[2]) {
            _boost_card_win_damage(_card, 1, "tri_compass");
            _pulse_relic("tri_compass");
        }
    }

    if (_has_relic_id("lone_blade")) {
        var _same_count = 0;
        for (var k = 0; k < obj_game.player_hand_limit; k++) {
            var _lh = obj_game.plr_hand[k];
            if (_lh != noone && _lh.card_type == _card.card_type) _same_count++;
        }
        if (_same_count == 1) {
            _boost_card_win_damage(_card, 2, "lone_blade");
            _pulse_relic("lone_blade");
        }
    }

    if (_has_relic_id("ember_furnace") && obj_game.relic_ember_ready) {
        if (_card_beats_type(_card, obj_game.relic_ember_type)) {
            _boost_card_win_damage(_card, 2, "ember_furnace");
            obj_game.relic_ember_ready = false;
            _pulse_relic("ember_furnace");
        }
    }
}

function _relic_on_active_discard(_discarded_card, _owner) {
    if (_discarded_card == noone) return;
    if (_owner == "player") obj_game.relic_player_discarded_this_turn = true;

    if (_owner == "player" && !obj_game.relic_first_player_discard_done) {
        obj_game.relic_first_player_discard_done = true;

        if (_has_relic_id("shuffle_funnel")) {
            if (_draw_one_to_hand("player")) _pulse_relic("shuffle_funnel");
        }
        if (_has_relic_id("card_spark")) {
            if (_boost_random_hand_card("player", 1, "card_spark")) _pulse_relic("card_spark");
        }
        if (_has_relic_id("ember_furnace")) {
            obj_game.relic_ember_type = _int_to_card_type_str(_discarded_card.card_type);
            obj_game.relic_ember_ready = true;
            _pulse_relic("ember_furnace");
        }
    }

    if (_owner == "player" && _has_relic_id("predator_totem")) {
        var _cards = _get_hand_cards_array("player");
        var _discarded_type = _int_to_card_type_str(_discarded_card.card_type);
        var _boosted = 0;
        for (var i = 0; i < array_length(_cards); i++) {
            if (_card_beats_type(_cards[i], _discarded_type)) {
                if (_boost_card_win_damage(_cards[i], 1, "predator_totem")) _boosted++;
            }
        }
        if (_boosted > 0) _pulse_relic("predator_totem");
    }
}

function _relic_on_end_of_turn_before_next_deal() {
    if (_has_relic_id("lag_clock") && !obj_game.relic_player_discarded_this_turn) {
        var _cards = _get_hand_cards_array("player");
        var _boosted = 0;
        for (var i = 0; i < array_length(_cards); i++) {
            if (_boost_card_win_damage(_cards[i], 1, "lag_clock")) _boosted++;
        }
        if (_boosted > 0) _pulse_relic("lag_clock");
    }
}
