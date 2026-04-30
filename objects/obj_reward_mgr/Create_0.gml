// Sprint 3 Phase 2c.reward — Create override.
// Caches the current stage's rewards struct for Draw_64 + flags whether the player has CLAIM/SKIP'd.

event_inherited();

reward_stage = _get_stage_by_id(obj_game.current_stage_id);
reward_claimed = false;   // true once CLAIM or SKIP clicked (prevents double-advance)
