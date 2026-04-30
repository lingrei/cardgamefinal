// Sprint 3 Phase 2e.1 — rm_remove fan picker Step.
// event_inherited() for base ESC/SPACE; then fan click select + CONFIRM/CANCEL.
// Guards: deck must keep >=1 card (enforced inline in CONFIRM click handler).

event_inherited();

if (remove_choice_made) exit;

// Hover detection — iterate right-to-left for overlap priority (outermost card wins)
hovered_card_idx = -1;
var _half_w = fan_card_w / 2;
var _half_h = fan_card_h / 2;
for (var i = array_length(fan_positions) - 1; i >= 0; i--) {
    var _p = fan_positions[i];
    if (mouse_x > _p.x - _half_w && mouse_x < _p.x + _half_w &&
        mouse_y > _p.y - _half_h && mouse_y < _p.y + _half_h) {
        hovered_card_idx = i;
        break;
    }
}

if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;
var _deck_size = array_length(obj_game.player_deck);

// ===== Card click → select (must have deck > 1 to allow removal) =====
if (hovered_card_idx >= 0 && _deck_size > 1) {
    selected_card_idx = hovered_card_idx;
    exit;
}

// ===== CONFIRM button (right, delete selected card) =====
if (selected_card_idx >= 0 && _deck_size > 1) {
    if (point_in_rectangle(mouse_x, mouse_y, _cx + 50, 660, _cx + 250, 700)) {
        // Delete card at selected_idx (direct index, not by type — more precise than helper)
        var _card = obj_game.player_deck[selected_card_idx];
        array_delete(obj_game.player_deck, selected_card_idx, 1);
        show_debug_message("[rm_remove] Deleted card idx=" + string(selected_card_idx) + " type=" + _card.type_name + " → deck size " + string(array_length(obj_game.player_deck)));
        remove_choice_made = true;
        _mgr_advance_non_battle_node();
        exit;
    }
}

// ===== CANCEL / LEAVE button (left, skip without remove) =====
if (point_in_rectangle(mouse_x, mouse_y, _cx - 250, 660, _cx - 50, 700)) {
    show_debug_message("[rm_remove] LEAVE (no remove)");
    remove_choice_made = true;
    _mgr_advance_non_battle_node();
    exit;
}
