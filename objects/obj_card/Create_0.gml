card_type = 0;
face_up = false;

target_x = x;
target_y = y;
move_speed = 0.12;
is_moving = false;


flip_state = 0;
flip_scale = 1;
flip_to_face = false;

// Sprint 3 Phase 2b.5: per-card rotation (degrees). Non-zero only when in discard pile (凌乱感).
// SHUFFLE_COLLECT resets to 0. Fan hand uses fan-angle rotation (Phase 1 Batch 3 E1).
// Backlog cleanup: target_rotation lerps current_rotation toward it for smooth transitions
// (esp. fan-collapse → 0 snap that previously was instant while position lerped).
current_rotation = 0;
target_rotation = 0;

hoverable = false;
clickable = false;
// D60: peekable state-driven flag removed (PEEK_PHASE deleted in Sprint 2).
// is_peek_revealed: true once a peek item has revealed this card (D43 dedupe).
is_peek_revealed = false;
hover_offset = 0;

// Round 1: rules array per instance (0-N rules, structure per scr_struct_constructors.RuleStruct)
rules = [];

// Round 2: card owner tag ("player" | "opp") — used for DISCARD routing to correct pile
card_owner = "";

// Round 3: display_name (from CardStruct; flows via _instantiate_card_from_struct)
display_name = "";

// D69 runtime modifiers/state. These reset when the card instance is recreated for a battle.
win_damage_bonus = 0;
drawn_this_turn = false;
retained_from_previous_turn = false;
marked_for_discard = false;
active_discarded_this_turn = false;
held_turns = 0;
was_held_last_turn = false;
cold_box_granted = false;
discard_route_override = "";
played_route_override = "";
ui_pulse_timer = 0;
ui_outline_color = c_white;
is_dragging = false;
drag_offset_x = 0;
drag_offset_y = 0;
drag_return_x = x;
drag_return_y = y;
drag_return_rotation = 0;
