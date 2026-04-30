// Sprint 3 Phase 2c.shop — Step override.
// event_inherited() base dispatch; then per-slot click handlers.
// Phase 2d TODO: rule purchase triggers Unified Upgrade UI to apply rule to a deck card.

event_inherited();

if (!mouse_check_button_pressed(mb_left)) exit;

var _cx = display_get_gui_width() / 2;

// ===== Rules column (left, x=80-380) — Phase 2d: trigger upgrade preview; gold deducted on CONFIRM =====
for (var i = 0; i < array_length(shop_rules); i++) {
    if (rules_sold[i]) continue;
    var _r = shop_rules[i];
    var _y = 200 + i * 150;
    if (point_in_rectangle(mouse_x, mouse_y, 80, _y, 380, _y + 130)) {
        if (obj_game.gold >= _r.cost) {
            // Phase 2d review H2 fix: mark slot sold at click (defensive — shop rebuild on re-enter
            // resets anyway, but this prevents exploits if future flow preserves shop state).
            rules_sold[i] = true;
            obj_game.upgrade_context = {
                candidates: [_r],
                source: "shop",
                return_room: rm_shop,
                pending_gold_deduct: _r.cost,
                shop_slot_idx: i
            };
            show_debug_message("[rm_shop] Preview upgrade for rule '" + _r.id + "' (cost " + string(_r.cost) + "g, CONFIRM to pay)");
            room_goto(rm_upgrade);
        } else {
            show_debug_message("[rm_shop] Not enough gold (" + string(obj_game.gold) + "<" + string(_r.cost) + ") for '" + _r.id + "'");
        }
        exit;
    }
}

// ===== Items column (middle, x=450-720) =====
for (var i = 0; i < array_length(shop_items); i++) {
    var _it = shop_items[i];
    var _y = 250 + i * 180;
    if (point_in_rectangle(mouse_x, mouse_y, 450, _y, 720, _y + 160)) {
        if (obj_game.gold >= _it.cost) {
            // 2026-04-26: stack via helper (same id stacks charges, no duplicate slots).
            // Helper checks 4-slot cap; only deduct gold if added/stacked.
            var _was_added = _add_item_to_inventory(_it);
            if (_was_added) {
                obj_game.gold -= _it.cost;
                show_debug_message("[rm_shop] Bought item '" + _it.id + "' for " + string(_it.cost) + "g");
            } else {
                show_debug_message("[rm_shop] Items slot full (4/4), can't buy");
            }
        } else {
            show_debug_message("[rm_shop] Not enough gold for '" + _it.id + "'");
        }
        exit;
    }
}

// ===== Heal column (right, x=800-1000) — 1 gold = 1 HP =====
if (point_in_rectangle(mouse_x, mouse_y, 800, 280, 1000, 360)) {
    if (obj_game.gold >= 1 && obj_game.player_hp < obj_game.player_max_hp) {
        obj_game.gold -= 1;
        obj_game.player_hp += 1;
        show_debug_message("[rm_shop] Heal +1 HP for 1g. HP=" + string(obj_game.player_hp) + "/" + string(obj_game.player_max_hp));
    } else if (obj_game.player_hp >= obj_game.player_max_hp) {
        show_debug_message("[rm_shop] HP already at max");
    } else {
        show_debug_message("[rm_shop] Not enough gold to heal");
    }
    exit;
}

// ===== LEAVE SHOP =====
if (point_in_rectangle(mouse_x, mouse_y, _cx - 100, 640, _cx + 100, 680)) {
    show_debug_message("[rm_shop] LEAVE");
    _mgr_advance_non_battle_node();
    exit;
}
