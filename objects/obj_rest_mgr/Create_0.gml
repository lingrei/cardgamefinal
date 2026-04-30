// Sprint 3 Phase 2c.rest — Create override.
// event_inherited() first: lets base obj_room_mgr_base.Create run (sets _current_room_name, log).
// Then rest-specific state: tracks whether the player has already picked HEAL/UPGRADE/LEAVE this visit.

event_inherited();

rest_choice_made = false;   // true once HEAL or UPGRADE clicked → blocks further clicks this visit
