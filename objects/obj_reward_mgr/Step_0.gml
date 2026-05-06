event_inherited();

if (reward_claimed) exit;
if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;

if (!is_undefined(reward_stage) && reward_stage.rewards.relic_choice_count > 0) {
    var _line_y = 200;
    if (reward_stage.rewards.gold > 0) _line_y += 44;
    if (reward_stage.rewards.card_count > 0) _line_y += 44;
    if (reward_stage.rewards.upgrade_count > 0) _line_y += 44;
    var _start_x = _cx - 465;
    for (var ri = 0; ri < array_length(relic_candidates); ri++) {
        var _rx = _start_x + ri * 330;
        if (point_in_rectangle(mouse_x, mouse_y, _rx, _line_y + 34, _rx + 300, _line_y + 162)) {
            selected_relic_idx = ri;
            exit;
        }
    }
}

if (point_in_rectangle(mouse_x, mouse_y, _cx - 100, 545, _cx + 100, 595)) {
    if (!is_undefined(reward_stage) && reward_stage.rewards.relic_choice_count > 0) {
        if (selected_relic_idx < 0) {
            show_debug_message("[rm_reward] relic choice pending");
            exit;
        }
        _add_relic_to_run(relic_candidates[selected_relic_idx].id);
    }

    _apply_stage_rewards(reward_stage);
    show_debug_message("[rm_reward] CLAIM rewards applied");

    if (!is_undefined(reward_stage) && reward_stage.rewards.upgrade_count > 0) {
        var _candidates = _sample_rules_from_pool(reward_stage, 3);
        if (array_length(_candidates) > 0) {
            obj_game.upgrade_context = {
                candidates: _candidates,
                source: "reward",
                return_room: rm_reward,
                pending_gold_deduct: 0,
                shop_slot_idx: -1
            };
            reward_claimed = true;
            room_goto(rm_upgrade);
            exit;
        }
    }

    reward_claimed = true;
    _mgr_advance_reward();
    exit;
}

if (point_in_rectangle(mouse_x, mouse_y, _cx - 75, 615, _cx + 75, 655)) {
    obj_game.gold += 1;
    reward_claimed = true;

    _mgr_advance_reward();
    exit;
}
