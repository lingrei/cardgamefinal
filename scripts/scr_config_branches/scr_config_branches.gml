// D61 (2026-04-24): branches 运行时随机生成, 每 lane 3 随机节点.
// 推翻原 D16 "每线 2 预设节点" — 预设 5 sample_branch_* 函数已废弃.
//
// Architecture:
// - 每 battle 后 2 lane (A/B), 每 lane 从 {shop, rest, event, remove} 4 类型池随机抽 3 节点 (可重复).
// - Branches 在 run 开始时一次性随机化并缓存到 `global.current_run_branches` (run-scope).
// - 同一 run 多次 get_branch_by_id 返回相同 branch (一致性), 新 run 重新 reset + 随机生成.
// - 玩家选 lane 后不可跨 lane (D61 约束, 玩家选 line 后另一 lane 在 map scene DIM 锁死).

/// @desc Generate 3 random nodes for one lane (shop/rest/event/remove pool, repetition allowed).
function _generate_random_lane() {
    var _pool = ["shop", "rest", "event", "remove"];
    var _lane = [];
    for (var i = 0; i < 3; i++) {
        var _type = _pool[irandom(array_length(_pool) - 1)];
        array_push(_lane, new NodeStruct(_type, {}));
    }
    return _lane;
}

/// @desc Build one branch with 2 lanes of 3 random nodes each.
function _generate_branch(_id) {
    return new BranchStruct(_id,
        _generate_random_lane(),
        _generate_random_lane());
}

/// @desc Initialize/reset the 5-branch cache for the current run. Called from generate_default_run_map.
function generate_run_branches() {
    global.current_run_branches = {};
    for (var i = 1; i <= 5; i++) {
        var _id = "branch_" + string(i);
        global.current_run_branches[$ _id] = _generate_branch(_id);
    }
    show_debug_message("[D61] generate_run_branches: 5 branches randomized (2 lane × 3 node each)");
}

/// @desc Returns all 5 branches in order (must call generate_run_branches first).
function get_all_branches() {
    if (!variable_global_exists("current_run_branches")) {
        show_debug_message("[WARN] get_all_branches called before generate_run_branches — returning empty");
        return [];
    }
    var _out = [];
    for (var i = 1; i <= 5; i++) {
        var _id = "branch_" + string(i);
        if (variable_struct_exists(global.current_run_branches, _id)) {
            array_push(_out, global.current_run_branches[$ _id]);
        }
    }
    return _out;
}

/// @desc Lookup cached branch by id. Returns undefined if not initialized or id unknown.
function get_branch_by_id(_id) {
    if (!variable_global_exists("current_run_branches")) {
        show_debug_message("[WARN] get_branch_by_id called before generate_run_branches: " + string(_id));
        return undefined;
    }
    if (variable_struct_exists(global.current_run_branches, _id)) {
        return global.current_run_branches[$ _id];
    }
    show_debug_message("[WARN] get_branch_by_id: branch_id not found: " + string(_id));
    return undefined;
}
