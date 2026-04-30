// scr_config_items.gml — Item template registry.
// Round 4 MVP 3 items (peek_opp_hand / draw_extra / immune_this_round).
// Phase 1 Batch 4 added 6 more (mulligan / reveal_opp_hand_types / discard_own_hand /
//   scry_top_3 / steal_from_opp_discard / recover_from_own_discard) — full library 9/10.
// Excluded: force_opp_replay (borderline design, needs UI for "play AI's turn").

function item_peek_opp_hand() {
    // D43: random reveal 1 face-down enemy card (opp_hand + unrevealed opp_play); is_peek_revealed dedupe
    return new ItemStruct(
        "peek_opp_hand",
        "peek_opp_hand",     // effect_type (handler dispatch)
        {},                   // effect_params
        1,                    // cost
        1,                    // max_charges
        "",                   // icon_sprite (Round 7 polish)
        "item_peek_opp_hand_desc"  // i18n key (D51)
    );
}

function item_draw_extra() {
    return new ItemStruct(
        "draw_extra",
        "draw_extra",
        {},
        1,
        1,
        "",
        "item_draw_extra_desc"
    );
}

function item_immune_this_round() {
    return new ItemStruct(
        "immune_this_round",
        "immune_this_round",
        {},
        2,
        1,
        "",
        "item_immune_this_round_desc"
    );
}

// ===== Phase 1 Batch 4 — 6 new handlers per plan §O.2 =====

function item_mulligan() {
    // Discard entire plr_hand → draw 3 fresh. No new UI; immediate effect.
    return new ItemStruct(
        "mulligan",
        "mulligan",
        {},
        1,
        1,
        "",
        "item_mulligan_desc"
    );
}

function item_reveal_opp_hand_types() {
    // Reveal all 3 opp_hand cards (sets is_peek_revealed + flips face-up). Stronger than peek.
    return new ItemStruct(
        "reveal_opp_hand_types",
        "reveal_opp_hand_types",
        {},
        2,
        1,
        "",
        "item_reveal_opp_hand_desc"
    );
}

function item_discard_own_hand() {
    // Enter "select card from hand" mode → click hand card → moves to limbo this battle.
    return new ItemStruct(
        "discard_own_hand",
        "discard_own_hand",
        {},
        1,
        1,
        "",
        "item_discard_own_hand_desc"
    );
}

function item_scry_top_3() {
    // Open OV_SCRY_TOP_3 → show top 3 of player_draw_pile face-up → click pick 1 to hand,
    // remaining 2 reshuffle randomly back into draw pile.
    return new ItemStruct(
        "scry_top_3",
        "scry_top_3",
        {},
        2,
        1,
        "",
        "item_scry_top_3_desc"
    );
}

function item_steal_from_opp_discard() {
    // Open OV_PILE_PICKER (target=opp_discard) → click 1 card → moves to plr_hand.
    return new ItemStruct(
        "steal_from_opp_discard",
        "steal_from_opp_discard",
        {},
        2,
        1,
        "",
        "item_steal_desc"
    );
}

function item_recover_from_own_discard() {
    // Open OV_PILE_PICKER (target=player_discard) → click 1 card → moves to plr_hand.
    return new ItemStruct(
        "recover_from_own_discard",
        "recover_from_own_discard",
        {},
        1,
        1,
        "",
        "item_recover_desc"
    );
}

function item_force_opp_replay() {
    // 2026-04-26 implemented: opp hand becomes hover/click target. Click swaps chosen opp_hand
    // card with current opp_play (revealed permanently face-up via is_peek_revealed flag).
    // Requires opp_play set (PLAYER_WAIT after OPP_CHOOSE) + at least 1 opp_hand card.
    return new ItemStruct(
        "force_opp_replay",
        "force_opp_replay",
        {},
        2,
        1,
        "",
        "item_force_opp_replay_desc"
    );
}

/// @desc Lookup item template by id. Returns undefined if not found.
function _get_item_template_by_id(item_id) {
    switch (item_id) {
        case "peek_opp_hand":             return item_peek_opp_hand();
        case "draw_extra":                return item_draw_extra();
        case "immune_this_round":         return item_immune_this_round();
        // Phase 1 Batch 4
        case "mulligan":                  return item_mulligan();
        case "reveal_opp_hand_types":     return item_reveal_opp_hand_types();
        case "discard_own_hand":          return item_discard_own_hand();
        case "scry_top_3":                return item_scry_top_3();
        case "steal_from_opp_discard":    return item_steal_from_opp_discard();
        case "recover_from_own_discard":  return item_recover_from_own_discard();
        case "force_opp_replay":          return item_force_opp_replay();
    }
    return undefined;
}

/// @desc Item pool used by shop random pick + event C subtype.
/// 2026-04-26: full 10-item library (force_opp_replay UI implemented).
function _get_mvp_item_pool() {
    return [
        "peek_opp_hand",
        "draw_extra",
        "immune_this_round",
        "mulligan",
        "reveal_opp_hand_types",
        "discard_own_hand",
        "scry_top_3",
        "steal_from_opp_discard",
        "recover_from_own_discard",
        "force_opp_replay"
    ];
}
