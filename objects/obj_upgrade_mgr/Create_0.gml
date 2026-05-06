// Sprint 3 Phase 2d — Unified Upgrade UI Manager (D50 pattern).
// Does NOT inherit obj_room_mgr_base: standalone flow, own CANCEL/CONFIRM, ESC=CANCEL (not to rm_run_map).
// Reads obj_game.upgrade_context set by source room (rest / shop rule / event_d / starter pack reward).
//
// upgrade_context schema:
//   candidates: array of RuleStruct templates (1 or 3 entries)
//   source:     "rest" | "shop" | "event_d" | "starter"  — advance path on CONFIRM/CANCEL
//   return_room: rm_rest / rm_shop / rm_event / rm_reward (unused in current simplified "always advance" flow)
//   pending_gold_deduct: N — for "shop", deducted only on CONFIRM (CANCEL = no charge)
//   shop_slot_idx: 0-2 — for "shop", which rule slot was previewed (informational)

upgrade_ctx = obj_game.upgrade_context;
selected_rule_idx = -1;
selected_target_card_idx = -1;
hovered_deck_idx = -1;

// Fan layout for deck display (D63: radius 260, angle ±55°, pivot below screen)
fan_pivot_x = 640;
fan_pivot_y = 760;   // pivot below screen; keeps target deck away from rule text
fan_radius  = 280;
fan_spread_deg = 110;
fan_card_w = 72;
fan_card_h = 101;
fan_hover_pop = 22;

fan_positions = _compute_fan_card_positions(
    fan_pivot_x, fan_pivot_y, fan_radius,
    array_length(obj_game.player_deck), fan_spread_deg);

// Pre-compute legal targets per candidate rule (D23 exhaustive + D39 implicit filter)
legal_targets_per_candidate = [];
if (!is_undefined(upgrade_ctx)) {
    for (var i = 0; i < array_length(upgrade_ctx.candidates); i++) {
        var _r = upgrade_ctx.candidates[i];
        array_push(legal_targets_per_candidate, _get_legal_target_cards(_r.id, obj_game.player_deck));
    }
    show_debug_message("[rm_upgrade] source=" + upgrade_ctx.source + " candidates=" + string(array_length(upgrade_ctx.candidates)) + " deck_size=" + string(array_length(obj_game.player_deck)));
} else {
    show_debug_message("[rm_upgrade] WARN entered without upgrade_context — ESC to bail to rm_run_map");
}
