// Generates the fixed 7-battle run map. Randomness comes from branch contents
// between battles, not from changing total battle count.

function generate_default_run_map() {
    var _map = [];
    var _stage_sequence = [
        "level_b01_intro",
        "level_b02_default",
        "level_b03_rock_trainer",
        "level_b04_paper_hoarder",
        "level_b05_default",
        "level_b06_default",
        "level_b07_final"
    ];
    generate_run_branches();
    var _branches = get_all_branches();

    for (var i = 0; i < array_length(_stage_sequence); i++) {
        array_push(_map, new NodeStruct("battle", { stage_id: _stage_sequence[i], battle_index: i }));
        if (i < array_length(_stage_sequence) - 1) {
            var _b = _branches[i];
            array_push(_map, new NodeStruct("branch_marker", { branch_id: _b.id }));
        }
    }
    return _map;
}
