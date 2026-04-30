// Sprint 3 Phase 2c.event — Step override.
// event_inherited() base dispatch; then CLAIM click applies subtype payload + advance.

event_inherited();

if (event_claimed) exit;
if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;

// CLAIM button rect matches Draw_64
if (point_in_rectangle(mouse_x, mouse_y, _cx - 100, 560, _cx + 100, 610)) {
    switch (event_subtype) {
        case "A":
            obj_game.gold += event_payload.gold;
            show_debug_message("[rm_event A] +" + string(event_payload.gold) + " gold → total " + string(obj_game.gold));
            break;
        case "B":
            // Phase 2c.card TODO: random card generation (random type + random rule + random level)
            show_debug_message("[rm_event B] Card generation pending Phase 2c.card (no-op for now)");
            break;
        case "C":
            // Fix (Phase 2c review HIGH-1): use unprefixed item id "peek_opp_hand"
            // (scr_config_items._get_item_template_by_id switches on unprefixed ids)
            for (var i = 0; i < event_payload.item_count; i++) {
                var _tpl = _get_item_template_by_id("peek_opp_hand");
                _add_item_to_inventory(_tpl);   // helper handles 4-slot cap + stacking
            }
            show_debug_message("[rm_event C] +" + string(event_payload.item_count) + " items (peek placeholder)");
            break;
        case "D":
            // Phase 2d: trigger Unified Upgrade UI with 1 random rule from stage pool
            var _stage = _get_stage_by_id(obj_game.current_stage_id);
            var _candidates = _sample_rules_from_pool(_stage, 1);
            if (array_length(_candidates) > 0) {
                obj_game.upgrade_context = {
                    candidates: _candidates,
                    source: "event_d",
                    return_room: rm_event,
                    pending_gold_deduct: 0,
                    shop_slot_idx: -1
                };
                event_claimed = true;
                show_debug_message("[rm_event D] → rm_upgrade (1 random rule from pool)");
                room_goto(rm_upgrade);
                exit;   // skip the bottom advance — upgrade finalizer will advance
            }
            show_debug_message("[rm_event D] no rules in pool, skipping upgrade");
            break;
        case "E":
            // Phase 2d.e polish: use pre-sampled rules from Create (consistent with UI label).
            var _candidates_e = event_payload.sampled_rules;
            var _applied_e = 0;
            for (var i = 0; i < array_length(_candidates_e); i++) {
                var _r_e = _candidates_e[i];
                var _legal_e = _get_legal_target_cards(_r_e.id, obj_game.player_deck);
                if (array_length(_legal_e) > 0) {
                    var _target_e = _legal_e[irandom(array_length(_legal_e) - 1)];
                    if (_apply_rule_to_card(_r_e.id, _target_e)) _applied_e++;
                }
            }
            show_debug_message("[rm_event E] auto-applied " + string(_applied_e) + "/" + string(array_length(_candidates_e)) + " rules");
            break;
    }
    event_claimed = true;
    _mgr_advance_non_battle_node();
    exit;
}
