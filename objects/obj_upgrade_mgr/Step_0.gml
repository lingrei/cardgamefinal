// Sprint 3 Phase 2d — Unified Upgrade Step.
// Handles: candidate rule click → select; deck fan hover/click → select target; CONFIRM/CANCEL buttons.
// MVP flow: both CONFIRM and CANCEL advance per source (CANCEL skips apply + gold-deduct, CONFIRM does both).

if (is_undefined(upgrade_ctx)) {
    // Defensive: bail if somehow entered without context
    if (keyboard_check_pressed(vk_escape)) room_goto(rm_run_map);
    exit;
}

var _cx = display_get_gui_width() / 2;
var _n_candidates = array_length(upgrade_ctx.candidates);

// ===== Hover detection for deck fan cards (iterate right-to-left for overlap priority) =====
hovered_deck_idx = -1;
var _half_w = fan_card_w / 2;
var _half_h = fan_card_h / 2;
for (var i = array_length(fan_positions) - 1; i >= 0; i--) {
    var _p = fan_positions[i];
    if (mouse_x > _p.x - _half_w && mouse_x < _p.x + _half_w &&
        mouse_y > _p.y - _half_h && mouse_y < _p.y + _half_h) {
        hovered_deck_idx = i;
        break;
    }
}

// ===== ESC = CANCEL (advance without apply) =====
if (keyboard_check_pressed(vk_escape)) {
    _upgrade_finalize(false);
    exit;
}

if (!mouse_check_button_pressed(mb_left)) exit;

// ===== Candidate rule click =====
var _cand_y = 180;
var _cand_h = 180;
if (_n_candidates == 1) {
    // Single: center rect
    if (point_in_rectangle(mouse_x, mouse_y, _cx - 140, _cand_y, _cx + 140, _cand_y + _cand_h)) {
        selected_rule_idx = 0;
        selected_target_card_idx = -1;
        exit;
    }
} else {
    // Triple: 3 positions at x_centers 350/640/930, each 250w
    var _cand_xs = [350, 640, 930];
    for (var i = 0; i < _n_candidates; i++) {
        var _cx_i = _cand_xs[i];
        if (point_in_rectangle(mouse_x, mouse_y, _cx_i - 125, _cand_y, _cx_i + 125, _cand_y + _cand_h)) {
            selected_rule_idx = i;
            selected_target_card_idx = -1;
            exit;
        }
    }
}

// ===== Deck card click (only if rule selected + card in legal set) =====
if (selected_rule_idx >= 0 && hovered_deck_idx >= 0) {
    var _legal = legal_targets_per_candidate[selected_rule_idx];
    var _is_legal = false;
    for (var i = 0; i < array_length(_legal); i++) {
        if (_legal[i] == hovered_deck_idx) { _is_legal = true; break; }
    }
    if (_is_legal) {
        selected_target_card_idx = hovered_deck_idx;
        exit;
    }
}

// ===== CONFIRM button (right bottom) =====
if (point_in_rectangle(mouse_x, mouse_y, _cx + 50, 660, _cx + 250, 700)) {
    if (selected_rule_idx >= 0 && selected_target_card_idx >= 0) {
        _upgrade_finalize(true);
        exit;
    }
}

// ===== CANCEL button (left bottom) =====
if (point_in_rectangle(mouse_x, mouse_y, _cx - 250, 660, _cx - 50, 700)) {
    _upgrade_finalize(false);
    exit;
}
