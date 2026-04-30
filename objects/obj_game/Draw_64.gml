// Sprint 3 Phase 2b.1 Draw GUI — 1280×720 Battle Scene v2 HUD (simplified, anchor-oriented).
// obj_game only draws battle UI in room0 (D56 room guard); non-battle rooms use obj_room_mgr_base
// and its 6 subclasses. State-specific overlays for RUN_MAP_BRANCH / POST_BATTLE_REWARD / NODE_*
// are deleted here — those states route to their own rooms in Phase 1.

if (room != room0) exit;

var _win_w = display_get_gui_width();
var _win_h = display_get_gui_height();
var _cx = _win_w / 2;

var _is_full_overlay = (state == "TITLE" || state == "RUN_VICTORY" || state == "RUN_DEFEAT");

draw_set_font(fnt_score);

// ===== In-game HUD (hidden on TITLE / RUN_END full overlays) =====
// 2026-04-26 strip: removed [⚙] placeholder, midline divider, gold text, "no items" placeholder,
// "Battle X/6" counter, 4 deck-query buttons. Pure-meta info (gold, item slots) kept for now in
// item bar only; G shown on map/shop/etc rooms instead. Player HP + Opp HP + DUEL kept.
if (!_is_full_overlay) {
    // Opp HP (top-left) + Plr HP (bottom-left). Pass real HP int for text accuracy (lerp display
    // for bar fill animation, real value for "X/Y" text).
    _draw_hp_bar(20, 20, 240, 24, ui_opp_hp_display, opp_max_hp, UI_COLOR_OPP,
        (ui_hp_flash_timer > 0 && ui_hp_flash_owner == "opp"), opp_hp);
    _draw_hp_bar(20, _win_h - 40, 240, 24, ui_player_hp_display, player_max_hp, UI_COLOR_PLAYER,
        (ui_hp_flash_timer > 0 && ui_hp_flash_owner == "player"), player_hp);

    // ===== DUEL button — round icon, right side (v3.3 — hover/disabled/enabled 3 states) =====
    if (!ui_select_card_mode) {
        var _duel_enabled = (selected_card != noone);
        var _dr = _duel_btn_rect();
        var _ccx = _dr.x + _dr.w / 2;
        var _ccy = _dr.y + _dr.h / 2;
        var _base_radius = _dr.w / 2;   // 50
        // Hover detection (only meaningful when enabled).
        var _duel_hover = _duel_enabled && point_in_rectangle(mouse_x, mouse_y, _dr.x, _dr.y, _dr.x + _dr.w, _dr.y + _dr.h);
        // Hover: ~6% radius pulse + brighter rings + larger text.
        var _pulse = _duel_hover ? (3 + 2 * sin(current_time / 120)) : 0;
        var _radius = _base_radius + _pulse;
        draw_set_alpha(1);
        draw_set_colour(UI_COLOR_BG_MID);
        draw_circle(_ccx, _ccy, _radius, false);
        // Ring(s): disabled = thin DIM; enabled = HIGHLIGHT 2 rings; hover = HIGHLIGHT 3 rings + outer glow.
        draw_set_colour(_duel_enabled ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
        draw_circle(_ccx, _ccy, _radius, true);
        draw_circle(_ccx, _ccy, _radius - 1, true);
        if (_duel_enabled) {
            draw_circle(_ccx, _ccy, _radius - 2, true);
            if (_duel_hover) {
                draw_circle(_ccx, _ccy, _radius - 3, true);
                // Outer glow ring (faded)
                draw_set_alpha(0.4);
                draw_circle(_ccx, _ccy, _radius + 4, true);
                draw_circle(_ccx, _ccy, _radius + 5, true);
                draw_set_alpha(1);
            }
        }
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        // Hover: text scale +0.05 for subtle "press me" lift
        var _txt_scale = _duel_hover ? 0.45 : 0.4;
        draw_text_transformed(_ccx, _ccy, "DUEL", _txt_scale, _txt_scale, 0);
    }

    // Items bar (4 fixed slots, only visible if items exist — empty slots draw nothing).
    _draw_item_bar(400, _win_h - 55);

    // ===== 2026-04-26: 4 pile-region borders + always-visible label with count =====
    // Label format: "OPP DECK [12]". Hover highlights border + label brighter.
    var _pile_w = 110, _pile_h = 150;
    var _regions_x = [DRAW_X - 5, DISCARD_X - 5, DRAW_X - 5, DISCARD_X - 5];
    var _regions_y = [OPP_DRAW_Y - 5, OPP_DISCARD_Y - 5, PLR_DRAW_Y - 5, PLR_DISCARD_Y - 5];
    var _regions_label = ["OPP DECK", "OPP DISCARD", "MY DECK", "MY DISCARD"];
    var _regions_count = [
        array_length(opp_draw_pile),
        array_length(opp_discard_pile),
        array_length(player_draw_pile),
        array_length(player_discard_pile)
    ];
    for (var _ri = 0; _ri < 4; _ri++) {
        var _rx = _regions_x[_ri];
        var _ry = _regions_y[_ri];
        var _hov = (state == "PLAYER_WAIT")
            && point_in_rectangle(mouse_x, mouse_y, _rx, _ry, _rx + _pile_w, _ry + _pile_h);
        draw_set_alpha(_hov ? 0.55 : 0.18);
        draw_set_colour(_hov ? UI_COLOR_HIGHLIGHT : UI_COLOR_NEUTRAL);
        draw_rectangle(_rx, _ry, _rx + _pile_w, _ry + _pile_h, true);
        // Always-visible label (region top) + count. Scale 0.18 fits any region with margin.
        draw_set_alpha(_hov ? 0.95 : 0.55);
        draw_set_colour(_hov ? UI_COLOR_HIGHLIGHT : UI_COLOR_NEUTRAL);
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_text_transformed(_rx + _pile_w / 2, _ry - 4, _regions_label[_ri] + " [" + string(_regions_count[_ri]) + "]", 0.18, 0.18, 0);
        draw_set_alpha(1);
    }

    // ===== Phase 1 Batch 2 (C2): Tier A hit flash vignette on loser side =====
    // Half-screen alpha rect, RPS-typed color (rock 暗红 / scissors 青 / paper 白),
    // alpha decays from 0.5 → 0 over 25 ticks. Loser side: opp = top half, player = bottom.
    if (ui_hit_flash_timer > 0) {
        var _hf_alpha = (ui_hit_flash_timer / 25) * 0.5;
        draw_set_alpha(_hf_alpha);
        draw_set_colour(ui_hit_flash_color);
        if (ui_hit_flash_owner == "opp") {
            draw_rectangle(0, 0, _win_w, _win_h / 2, false);
        } else if (ui_hit_flash_owner == "player") {
            draw_rectangle(0, _win_h / 2, _win_w, _win_h, false);
        }
        draw_set_alpha(1);
    }

    // ===== Phase 1 Batch 2 (C3): KO ritual — desaturate vignette + "K.O." pulsing text =====
    // Active during JUDGE_ANIMATE → JUDGE_WAIT → DISCARD → BATTLE_END_CHECK (until reset).
    // Slow-mo is handled via wait_timer ×3 in Step_0; visuals here add the ceremony layer.
    if (ui_ko_active) {
        // Dark overlay for desaturate feel
        draw_set_alpha(0.35);
        draw_set_colour(UI_COLOR_BG);
        draw_rectangle(0, 0, _win_w, _win_h, false);
        draw_set_alpha(1);

        // K.O. 大字 — center, pulsing scale (4.0 ± 0.3 sin)
        var _ko_pulse = 4.0 + 0.3 * sin(current_time / 80);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(UI_COLOR_OPP);
        draw_text_transformed(_cx, _win_h / 2, "K.O.", _ko_pulse, _ko_pulse, 0);
        draw_set_colour(c_white);
    }
}

// ===== TITLE screen — 2026-04-26 simplified: 3 buttons (PLAY / SETTINGS / EXIT), no SPACE prompt. =====
if (state == "TITLE") {
    draw_set_alpha(0.92);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(0, 0, _win_w, _win_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour(UI_COLOR_OPP);
    draw_text_transformed(_cx, _win_h / 2 - 140, "ROCK PAPER", 1.0, 1.0, 0);
    draw_text_transformed(_cx, _win_h / 2 - 80,  "SCISSORS",   1.0, 1.0, 0);

    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, _win_h / 2 - 10, "- ROGUELIKE -", 0.5, 0.5, 0);

    if (ui_overlay_open != OV_SETTINGS && ui_overlay_open != OV_PAUSE && ui_overlay_open != OV_NEW_GAME_CONFIRM) {
        var _btn_w = 220, _btn_h = 50, _btn_gap = 16;
        var _btn_y0 = _win_h / 2 + 60;
        _draw_button(_cx - _btn_w / 2, _btn_y0,                              _btn_w, _btn_h, "NEW GAME", 0.45);
        _draw_button(_cx - _btn_w / 2, _btn_y0 + (_btn_h + _btn_gap),        _btn_w, _btn_h, "SETTINGS", 0.45);
        _draw_button(_cx - _btn_w / 2, _btn_y0 + (_btn_h + _btn_gap) * 2,    _btn_w, _btn_h, "EXIT",     0.45);
    }
}

// ===== Run end overlays (room0-only; other end states handled in their rooms) =====
if (state == "RUN_VICTORY" || state == "RUN_DEFEAT") _draw_run_end_overlay();

// ===== Deck query overlays (can open on top of battle) =====
if (ui_overlay_open == OV_DECK_PD
    || ui_overlay_open == OV_DECK_PDC
    || ui_overlay_open == OV_DECK_OD
    || ui_overlay_open == OV_DECK_ODC) {
    _draw_deck_overlay();
}

// ===== Phase 1 Batch 4 (B4/B5): item-driven overlays =====
if (ui_overlay_open == OV_SCRY_TOP_3) _draw_scry_overlay();
if (ui_overlay_open == OV_PILE_PICKER) _draw_pile_picker_overlay();

// ===== Phase 1 Batch 5 (D1/D3): system overlays =====
if (ui_overlay_open == OV_SETTINGS) _draw_settings_overlay();
if (ui_overlay_open == OV_PAUSE) _draw_pause_overlay();
if (ui_overlay_open == OV_NEW_GAME_CONFIRM) _draw_new_game_confirm_overlay();

// ===== Card-select mode hint banner (B3 + 2026-04-26 force_opp_replay) =====
if (ui_select_card_mode) {
    var _bw = display_get_gui_width();
    var _banner_text = "Click a card to confirm";
    switch (ui_select_card_callback) {
        case "discard_own_hand":  _banner_text = "Click a hand card to discard (excluded this battle)"; break;
        case "force_opp_replay":  _banner_text = "Click an opp hand card to swap with their played card (permanent reveal)"; break;
    }
    draw_set_alpha(0.85);
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_rectangle(0, 380, _bw, 410, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(UI_COLOR_BG);
    draw_text_transformed(_bw / 2, 395, _banner_text, 0.4, 0.4, 0);
    draw_set_colour(c_white);
}

// ===== Card tooltip (top layer) =====
if (ui_tooltip_target != noone && ui_overlay_open == OV_NONE) {
    _draw_card_tooltip(ui_tooltip_target);
}

// ===== Reset draw state =====
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);
