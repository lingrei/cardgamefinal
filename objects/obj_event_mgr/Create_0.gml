// Sprint 3 Phase 2c.event — Create override.
// Randomize subtype (A-E) + generate payload per D49 §O.6 event spec.
// A: 1-3 gold / B: 1 random card / C: 1-3 random items / D: 1 upgrade choice / E: 2 random upgrades.

event_inherited();

event_subtype = choose("A", "B", "C", "D", "E");
event_payload = {};
event_label = "";

switch (event_subtype) {
    case "A":
        event_payload.gold = irandom_range(1, 3);
        event_label = "+ " + string(event_payload.gold) + " Gold";
        break;
    case "B":
        event_payload.card_count = 1;
        event_label = "+ 1 Random Card  (random type + rule)";
        break;
    case "C":
        event_payload.item_count = irandom_range(1, 3);
        event_label = "+ " + string(event_payload.item_count) + " Random Item(s)";
        break;
    case "D":
        event_payload.upgrade_count = 1;
        event_label = "Choose 1 Upgrade  (apply to any card)";
        break;
    case "E":
        event_payload.upgrade_count = 2;
        // Phase 2d.e polish: pre-sample 2 rules at Create so player can preview label,
        // Step_0 apply uses this cached list (consistent with display).
        var _e_stage = _get_stage_by_id(obj_game.current_stage_id);
        event_payload.sampled_rules = _sample_rules_from_pool(_e_stage, 2);
        var _names_list = "";
        for (var _i = 0; _i < array_length(event_payload.sampled_rules); _i++) {
            _names_list += (_i > 0 ? " + " : "") + event_payload.sampled_rules[_i].id;
        }
        event_label = (array_length(event_payload.sampled_rules) > 0)
            ? ("Auto-apply: " + _names_list)
            : "2 Random Upgrades (pool empty — skip)";
        break;
}

event_claimed = false;
show_debug_message("[rm_event] Rolled subtype=" + event_subtype + " payload=" + event_label);
