// Sprint 3 Phase 2e.1 — rm_remove fan deck picker override.
// Replaces the Phase 2c 3-type-button MVP with a fan-layout deck browser (click any specific card → confirm → remove).

event_inherited();

remove_choice_made = false;   // lock after a remove action (CONFIRM)
selected_card_idx = -1;       // which deck card is currently selected for removal (-1 = none)
hovered_card_idx = -1;

// Fan layout (reuses rm_upgrade's big-fan params)
fan_pivot_x = 640;
fan_pivot_y = 680;
fan_radius  = 260;
fan_spread_deg = 110;
fan_card_w = 90;
fan_card_h = 126;
fan_hover_pop = 30;

fan_positions = _compute_fan_card_positions(
    fan_pivot_x, fan_pivot_y, fan_radius,
    array_length(obj_game.player_deck), fan_spread_deg);
