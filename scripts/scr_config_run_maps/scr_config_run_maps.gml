// Generates a full Run map (6 battle nodes + 5 branch_marker nodes interleaved).
// D55: payload now carries stage_id (not enemy_id — stage abstracts enemy + rewards).
// Round 4 MVP: stage_1 for all 6 battles (Stage 2-6 in Round 5-6).

/// @desc Sprint 3 Phase 3.tutorial (D28): Tutorial run map = single battle of stage_tutorial, no branches.
/// First-time players go through this; after CLAIM-ing reward + starter upgrade, tutorial_done=true is
/// persisted and future SPACE starts a regular 6-battle run.
function generate_tutorial_run_map() {
    return [new NodeStruct("battle", { stage_id: "stage_tutorial", battle_index: 0 })];
}

function generate_default_run_map() {
    var _map = [];
    // Round 4 MVP: stage_1 all 6 battles (placeholder until Stage 2-6 defined in Round 5-6)
    var _stage_sequence = ["stage_1", "stage_1", "stage_1", "stage_1", "stage_1", "stage_1"];
    // D61: branches are randomized per-run (2 lane × 3 node each from shop/rest/event/remove pool)
    generate_run_branches();
    var _branches = get_all_branches();

    for (var i = 0; i < 6; i++) {
        array_push(_map, new NodeStruct("battle", { stage_id: _stage_sequence[i], battle_index: i }));

        if (i < 5) {
            var _b = _branches[i];
            array_push(_map, new NodeStruct("branch_marker", { branch_id: _b.id }));
        }
    }
    return _map;   // length = 11 (6 battles + 5 branch markers)
}
