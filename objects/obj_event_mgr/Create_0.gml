event_inherited();

var _types = ["gold_cache", "random_card", "choose_upgrade", "auto_upgrade"];
encounter_type = _types[irandom(array_length(_types) - 1)];
event_payload = {};
event_label = "";

switch (encounter_type) {
    case "gold_cache":
        event_payload.gold = irandom_range(1, 3);
        event_label = "+ " + string(event_payload.gold) + " Gold";
        break;
    case "random_card":
        event_payload.card_count = 1;
        event_label = "+ 1 Random Card";
        break;
    case "choose_upgrade":
        event_payload.upgrade_count = 1;
        event_label = "Choose 1 Upgrade";
        break;
    case "auto_upgrade":
        event_payload.upgrade_count = 2;
        var _stage = _get_stage_by_id(obj_game.current_stage_id);
        event_payload.sampled_rules = _sample_rules_from_pool(_stage, 2);
        event_label = "Auto-apply 2 Upgrades";
        break;
}

event_claimed = false;
show_debug_message("[rm_event] Rolled type=" + encounter_type + " payload=" + event_label);
