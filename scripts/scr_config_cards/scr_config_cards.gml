// Sample card configs (kept for backward compat; real card library in scr_config_rules.gml + scr_config_stages.gml)
// D51: CardStruct no display_name; RuleStruct no name, description_text = i18n key

function sample_card_plain_rock() {
    return new CardStruct("rock", []);
}

function sample_card_plain_paper() {
    return new CardStruct("paper", []);
}

function sample_card_plain_scissors() {
    return new CardStruct("scissors", []);
}
