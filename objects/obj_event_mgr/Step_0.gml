event_inherited();

if (event_claimed) exit;
if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;

if (point_in_rectangle(mouse_x, mouse_y, _cx - 100, 560, _cx + 100, 610)) {
    switch (encounter_type) {
        case "gold_cache":
            obj_game.gold += event_payload.gold;
            break;
        case "random_card":
            var _stage_card = _get_stage_by_id(obj_game.current_stage_id);
            var _new_card = _generate_card_by_algorithm("basic_random_rsp_rule", _stage_card);
            if (!is_undefined(_new_card)) array_push(obj_game.player_deck, _new_card);
            break;
        case "choose_upgrade":
            var _stage = _get_stage_by_id(obj_game.current_stage_id);
            var _candidates = _sample_rules_from_pool(_stage, 3);
            if (array_length(_candidates) > 0) {
                obj_game.upgrade_context = {
                    candidates: _candidates,
                    source: "event_d",
                    return_room: rm_event,
                    pending_gold_deduct: 0,
                    shop_slot_idx: -1
                };
                event_claimed = true;
                room_goto(rm_upgrade);
                exit;
            }
            break;
        case "auto_upgrade":
            var _rules = event_payload.sampled_rules;
            for (var i = 0; i < array_length(_rules); i++) {
                var _legal = _get_legal_target_cards(_rules[i].id, obj_game.player_deck);
                if (array_length(_legal) > 0) {
                    _apply_rule_to_card(_rules[i].id, _legal[irandom(array_length(_legal) - 1)]);
                }
            }
            break;
    }
    event_claimed = true;
    _mgr_advance_non_battle_node();
    exit;
}
