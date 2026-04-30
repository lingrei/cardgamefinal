// Round 3 UI helpers. All draw/interaction functions for obj_game's expanded UI.
// Follows plan conventions: macro-based overlay state, helper-internal draw state management.

// ===== Overlay state macros (prevent string typo) =====
#macro OV_NONE           ""
#macro OV_DECK_PD        "deck_pd"
#macro OV_DECK_PDC       "deck_pdc"
#macro OV_DECK_OD        "deck_od"
#macro OV_DECK_ODC       "deck_odc"
// Phase 1 Batch 4 (B4/B5): item-driven overlays.
#macro OV_SCRY_TOP_3     "scry_top_3"
#macro OV_PILE_PICKER    "pile_picker"
// Phase 1 Batch 5 (D1/D3): system overlays.
#macro OV_SETTINGS       "settings"
#macro OV_PAUSE          "pause"
// 2026-04-26: NEW GAME tutorial-skip confirm.
#macro OV_NEW_GAME_CONFIRM "new_game_confirm"

// Phase 1 Batch 6 (F5): magic-number constants extracted from inline use sites.
// Card sprite half-dimensions for hand-fan hit-test (sprite is 90×126 logical).
#macro HAND_CARD_HALF_W  45
#macro HAND_CARD_HALF_H  63
// SHUFFLE_ANIM offset: how many pixels the draw pile temporarily shifts toward screen center
// during the visual mix step (so cards are on-screen during shuffle).
#macro SHUFFLE_ANIM_OFFSET 80
// Phase 2e.4 Deleted: OV_REST_UPGRADE / OV_REMOVE_CONFIRM / OV_EVENT_DIALOG — Round 3 overlay
// states replaced by independent rooms (D56 architecture).

// ===== Geometry / color constants (Sprint 3 expanded palette) =====
#macro UI_COLOR_BG          make_colour_rgb(13, 2, 33)       // BG_DARK — scene base
#macro UI_COLOR_BG_MID      make_colour_rgb(26, 26, 46)      // panel / card bg
#macro UI_COLOR_PLAYER      make_colour_rgb(0, 229, 255)     // player / peek tag
#macro UI_COLOR_OPP         make_colour_rgb(255, 64, 129)    // enemy / hp_mod tag
#macro UI_COLOR_HIGHLIGHT   make_colour_rgb(255, 235, 59)    // selected / gold / matchup tag / CTA
#macro UI_COLOR_DIM         make_colour_rgb(90, 90, 90)      // disabled
#macro UI_COLOR_NEUTRAL     make_colour_rgb(200, 200, 200)   // standard text
#macro UI_COLOR_SUCCESS     make_colour_rgb(0, 230, 118)     // heal / buff / victory / draw tag
#macro UI_COLOR_WARNING     make_colour_rgb(255, 152, 0)     // low HP / risk
#macro UI_COLOR_RULE_DECK   make_colour_rgb(156, 39, 176)    // deck-manipulating rules tag

// ===== Anchor-based layout helper (Sprint 3) =====
// Returns { x, y } given an anchor name + pixel offset. Decouples layout from
// hard-coded display dimensions — switching resolution means re-calling with same
// anchor names and the UI repositions automatically.
// Anchors: tl/tr/bl/br (corners), tc/bc (top/bottom center), cl/cr (center left/right), center.
function _ui_anchor(_anchor, _dx, _dy) {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    switch (_anchor) {
        case "tl":     return { x: _dx,             y: _dy };
        case "tr":     return { x: _w - _dx,        y: _dy };
        case "bl":     return { x: _dx,             y: _h - _dy };
        case "br":     return { x: _w - _dx,        y: _h - _dy };
        case "tc":     return { x: _w / 2 + _dx,    y: _dy };
        case "bc":     return { x: _w / 2 + _dx,    y: _h - _dy };
        case "cl":     return { x: _dx,             y: _h / 2 + _dy };
        case "cr":     return { x: _w - _dx,        y: _h / 2 + _dy };
        case "center": return { x: _w / 2 + _dx,    y: _h / 2 + _dy };
    }
    return { x: _dx, y: _dy };
}

// ===== Audio helpers (Backlog cleanup: SFX slider per-sound gain wiring) =====
// `audio_master_gain(global.master_volume)` is applied globally in `_apply_volume_settings`
// (called from settings_load + on slider change), so master affects everything automatically.
// SFX-tagged playback also multiplies by `global.sfx_volume` via `audio_sound_gain` on the
// instance. Music (Phase 4) will use `_play_music` analogously with `global.music_volume`.

/// @desc Play a sound effect with current SFX volume applied. Replaces direct audio_play_sound for SFX.
/// @param _snd  Sound asset id
/// @return AudioPlayInstance (so caller can override gain/pitch if needed)
function _play_sfx(_snd) {
    var _inst = audio_play_sound(_snd, 1, false);
    audio_sound_gain(_inst, global.sfx_volume, 0);
    return _inst;
}

/// @desc 2026-04-26: card recall sfx — uses snd_card_move per user "card_recall 用移动的音效更和谐".
function _play_recall_sfx() {
    var _inst = audio_play_sound(snd_card_move, 1, false);
    audio_sound_gain(_inst, global.sfx_volume, 0);
    return _inst;
}

/// @desc 2026-04-27: BGM playback with smooth swap (stop old, play new looped).
/// Tracks current BGM via global.current_bgm to prevent restart-on-same-track.
/// Music gain = master * music sliders.
/// @param _snd  Sound asset id (bgm_xxx)
function _play_bgm(_snd) {
    if (variable_global_exists("current_bgm") && global.current_bgm == _snd) return;   // already playing
    if (variable_global_exists("current_bgm_inst") && audio_is_playing(global.current_bgm_inst)) {
        audio_stop_sound(global.current_bgm_inst);
    }
    global.current_bgm = _snd;
    global.current_bgm_inst = audio_play_sound(_snd, 0, true);   // priority 0, loop true
    audio_sound_gain(global.current_bgm_inst, global.master_volume * global.music_volume, 0);
}

function _stop_bgm() {
    if (variable_global_exists("current_bgm_inst") && audio_is_playing(global.current_bgm_inst)) {
        audio_stop_sound(global.current_bgm_inst);
    }
    global.current_bgm = "";
}

// ===== Mouse/keyboard helpers =====

function _is_mouse_in_rect(_x, _y, _w, _h) {
    return point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h);
}

function _click_in_rect(_x, _y, _w, _h) {
    return _is_mouse_in_rect(_x, _y, _w, _h) && mouse_check_button_pressed(mb_left);
}

/// @desc 2026-04-27: click rect + auto button-click SFX. Use at button sites (not card/region clicks).
function _btn_click(_x, _y, _w, _h) {
    if (_click_in_rect(_x, _y, _w, _h)) {
        _play_sfx(snd_ui_click);
        return true;
    }
    return false;
}

// ===== Drawing primitives =====

/// @desc Phase 1 Batch 2 (C2): D27 Tier A — RPS-typed hit flash colors.
/// Used by JUDGE win/lose branches to set ui_hit_flash_color = winner's RPS type.
/// 0=rock 暗红 (#8B0000 钝器感) / 1=scissors 青 (#00FFFF 锐利刺击) / 2=paper 白 (#FFFFFF 扩散冲击).
function _get_rps_color(_card_type) {
    switch (_card_type) {
        case 0: return make_colour_rgb(0x8B, 0x00, 0x00);   // rock — dark red impact
        case 1: return make_colour_rgb(0x00, 0xFF, 0xFF);   // scissors — cyan slash
        case 2: return make_colour_rgb(0xFF, 0xFF, 0xFF);   // paper — white burst
    }
    return c_white;
}

function _draw_button(_x, _y, _w, _h, _text, _scale) {
    var _hovered = _is_mouse_in_rect(_x, _y, _w, _h);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(_hovered ? UI_COLOR_HIGHLIGHT : UI_COLOR_PLAYER);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    if (_hovered) draw_rectangle(_x + 1, _y + 1, _x + _w - 1, _y + _h - 1, true);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_text_transformed(_x + _w/2, _y + _h/2, _text, _scale, _scale, 0);
}

function _draw_hp_bar(_x, _y, _w, _h, _hp_display, _max_hp, _color_fill, _flash_on, _hp_real) {
    // 2026-04-26 fix: text uses _hp_real (true int player_hp) not lerped display value.
    // Old `ceil(_hp_display)` could read 5/5 when actual was 4 (lerp at 4.4 → ceil=5). Display
    // bar still uses _hp_display for smooth animation; text shows ground truth.
    if (is_undefined(_hp_real)) _hp_real = ceil(_hp_display);   // backward compat
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    var _ratio = clamp(_hp_display / max(_max_hp, 0.0001), 0, 1);
    var _fill_w = _ratio * _w;
    draw_set_colour(_flash_on ? make_colour_rgb(255, 200, 200) : _color_fill);
    draw_rectangle(_x, _y, _x + _fill_w, _y + _h, false);
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_text_transformed(_x + _w/2, _y + _h/2,
        "HP " + string(_hp_real) + "/" + string(_max_hp), 0.3, 0.3, 0);
}

// Phase 2e.4 Deleted: _draw_minimap (replaced by rm_run_map visual map scene).

function _draw_deck_buttons(_x, _y) {
    draw_set_alpha(1);
    var _btn_w = 30;
    var _btn_h = 30;
    var _spacing = 5;
    var _labels = ["PD", "PDC", "OD", "ODC"];
    for (var i = 0; i < 4; i++) {
        _draw_button(_x + i * (_btn_w + _spacing), _y, _btn_w, _btn_h, _labels[i], 0.3);
    }
}

function _get_item_color(_effect_type) {
    switch (_effect_type) {
        case "peek":          return make_colour_rgb(0, 229, 255);
        case "draw_extra":    return make_colour_rgb(100, 255, 100);
        case "force_replay":  return make_colour_rgb(255, 200, 100);
        default:              return make_colour_rgb(200, 200, 200);
    }
}

function _draw_item_bar(_x, _y) {
    draw_set_alpha(1);
    draw_set_font(fnt_score);
    var _items = obj_game.items;
    var _slot_count = 4;
    var _hovered_idx = -1;   // 2026-04-26: track hover for tooltip below
    for (var i = 0; i < _slot_count; i++) {
        var _ix = _x + i * 45;
        if (i < array_length(_items)) {
            var _item = _items[i];
            var _alpha = (_item.current_charges > 0) ? 1.0 : 0.3;
            draw_set_alpha(_alpha);
            draw_set_colour(_get_item_color(_item.effect_type));
            draw_rectangle(_ix, _y, _ix + 40, _y + 50, false);
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_text_transformed(_ix + 20, _y + 10, string_upper(string_char_at(_item.id, 1)), 0.5, 0.5, 0);
            draw_text_transformed(_ix + 20, _y + 38, string(_item.current_charges) + "/" + string(_item.max_charges), 0.2, 0.2, 0);
            draw_set_alpha(1);
            if (_is_mouse_in_rect(_ix, _y, 40, 50)) _hovered_idx = i;
        } else {
            draw_set_alpha(0.4);
            draw_set_colour(UI_COLOR_DIM);
            draw_rectangle(_ix, _y, _ix + 40, _y + 50, true);
            draw_set_alpha(1);
        }
    }

    // 2026-04-26: hover tooltip showing item description (per user "现在的道具看不到任何效果").
    // Force EN i18n — fnt_score sprite font doesn't support 中文 (Phase 4 audio batch will add TTF).
    if (_hovered_idx >= 0) {
        var _it = _items[_hovered_idx];
        var _desc = "[" + _it.id + "]";
        if (variable_struct_exists(global.i18n_dict, "en")) {
            var _en_dict = global.i18n_dict.en;
            if (variable_struct_exists(_en_dict, _it.description_text)) {
                _desc = _en_dict[$ _it.description_text];
            }
        }
        var _name = string_upper(_it.id);
        var _tt_w = 320;
        var _tt_h = 56;
        var _tt_x = _x + _hovered_idx * 45 + 20 - _tt_w / 2;
        // Position tooltip above the slot
        var _tt_y = _y - _tt_h - 8;
        if (_tt_x < 8) _tt_x = 8;
        if (_tt_x + _tt_w > display_get_gui_width() - 8) _tt_x = display_get_gui_width() - 8 - _tt_w;
        draw_set_alpha(0.95);
        draw_set_colour(UI_COLOR_BG_MID);
        draw_rectangle(_tt_x, _tt_y, _tt_x + _tt_w, _tt_y + _tt_h, false);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_rectangle(_tt_x, _tt_y, _tt_x + _tt_w, _tt_y + _tt_h, true);
        draw_set_alpha(1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_tt_x + 8, _tt_y + 6, _name + "  (" + string(_it.current_charges) + "/" + string(_it.max_charges) + ")", 0.28, 0.28, 0);
        draw_set_colour(c_white);
        draw_text_transformed(_tt_x + 8, _tt_y + 26, _desc, 0.22, 0.22, 0);
    }
}

function _get_rule_color(_rule) {
    var _tag = _rule[$ "tag"] ?? "";
    switch (_tag) {
        case "hp_mod":    return UI_COLOR_OPP;
        case "peek":      return UI_COLOR_PLAYER;
        case "matchup":   return UI_COLOR_HIGHLIGHT;
        default:          return c_white;
    }
}

// Returns enemy struct for "current or next" battle (for ENEMY DECK overlay).
// D55: payload carries stage_id; we pick one enemy from the stage's enemies pool.
// Stage 1-6 each has single-enemy pool so pick is stable; multi-enemy stages (Round 5+)
// will need cached current_enemy_id instead of re-rolling.
function _get_next_or_current_enemy() {
    var _map = obj_game.map;
    var _start = obj_game.map_position;
    for (var i = _start; i < array_length(_map); i++) {
        if (_map[i].type == "battle") {
            var _stage_id = _map[i].payload[$ "stage_id"] ?? "stage_1";
            var _stage = _get_stage_by_id(_stage_id);
            if (is_undefined(_stage)) continue;
            var _enemy_id = _pick_enemy_from_stage(_stage);
            return _get_enemy_template_by_id(_enemy_id);
        }
    }
    var _fallback = _get_stage_by_id("stage_1");
    return _get_enemy_template_by_id(_pick_enemy_from_stage(_fallback));
}

// ===== Click handlers dispatched from _handle_ui_clicks =====

/// @desc 2026-04-26: 4 pile-region click → opens corresponding deck viewer overlay.
/// Replaces 4 corner buttons + D/F/G/H keyboard shortcuts (per user UX feedback).
/// Regions match draw_pile/discard_pile spawn rects (DRAW_X/DISCARD_X × OPP/PLR_DRAW/DISCARD_Y).
function _handle_pile_click_regions() {
    var _w = 110, _h = 150;
    if (_click_in_rect(obj_game.DRAW_X - 5, obj_game.OPP_DRAW_Y - 5, _w, _h)) {
        obj_game.ui_overlay_open = OV_DECK_OD;       // enemy deck composition
    } else if (_click_in_rect(obj_game.DISCARD_X - 5, obj_game.OPP_DISCARD_Y - 5, _w, _h)) {
        obj_game.ui_overlay_open = OV_DECK_ODC;      // enemy discard
    } else if (_click_in_rect(obj_game.DRAW_X - 5, obj_game.PLR_DRAW_Y - 5, _w, _h)) {
        obj_game.ui_overlay_open = OV_DECK_PD;       // player deck
    } else if (_click_in_rect(obj_game.DISCARD_X - 5, obj_game.PLR_DISCARD_Y - 5, _w, _h)) {
        obj_game.ui_overlay_open = OV_DECK_PDC;      // player discard
    }
}

function _handle_deck_buttons() {
    // Sprint 3 Phase 2b.1: deck buttons moved to bottom-right corner (x=_win_w-155, y=_win_h-40)
    // to match Draw_64's new HUD layout. Must stay in sync with _draw_deck_buttons call site.
    var _x = display_get_gui_width() - 155;
    var _y = display_get_gui_height() - 40;
    var _btn_w = 30;
    var _spacing = 5;
    var _keys = [OV_DECK_PD, OV_DECK_PDC, OV_DECK_OD, OV_DECK_ODC];
    for (var i = 0; i < 4; i++) {
        if (_click_in_rect(_x + i * (_btn_w + _spacing), _y, _btn_w, _btn_h_or(30))) {
            obj_game.ui_overlay_open = _keys[i];
            return;
        }
    }
    // 2026-04-26 user removed D/F/G/H shortcuts — viewer triggered by clicking the 4 pile regions.
}

// Helper for button height constant used in click detection (avoids magic number)
function _btn_h_or(_h) { return _h; }

function _handle_overlay_interaction() {
    // Phase 1 Batch 4 (B4/B5) + Batch 5 (D1/D3): item-driven + system overlays have own click handlers.
    // Route them BEFORE the deck-overlay close-button logic (which would steal control button click).
    if (obj_game.ui_overlay_open == OV_SCRY_TOP_3) {
        _handle_scry_click();
        return;
    }
    if (obj_game.ui_overlay_open == OV_PILE_PICKER) {
        _handle_pile_picker_click();
        return;
    }
    if (obj_game.ui_overlay_open == OV_SETTINGS) {
        _handle_settings_click();
        return;
    }
    if (obj_game.ui_overlay_open == OV_PAUSE) {
        _handle_pause_click();
        return;
    }
    if (obj_game.ui_overlay_open == OV_NEW_GAME_CONFIRM) {
        _handle_new_game_confirm_click();
        return;
    }
    // Close button — rect matches _draw_deck_overlay: (_win_w-140, _win_h-70, 120, 40)
    var _close_x = display_get_gui_width() - 140;
    var _close_y = display_get_gui_height() - 70;
    if (_click_in_rect(_close_x, _close_y, 120, 40)) {
        obj_game.ui_overlay_open = OV_NONE;
        return;
    }
    // Click outside overlay content area → close
    var _overlay_margin = 80;
    var _overlay_w = display_get_gui_width() - _overlay_margin * 2;
    var _overlay_h = display_get_gui_height() - _overlay_margin * 2;
    if (mouse_check_button_pressed(mb_left) && !_is_mouse_in_rect(_overlay_margin, _overlay_margin, _overlay_w, _overlay_h)) {
        obj_game.ui_overlay_open = OV_NONE;
        return;
    }
}

// Phase 2e.4 Deleted: _handle_remove_confirm / _handle_branch_click / _handle_reward_click /
// _advance_from_reward / _handle_shop_click / _handle_rest_click / _handle_event_click /
// _handle_remove_click / _advance_from_node — all Round 3 overlay-based handlers replaced by
// D56 独立 rooms + obj_room_mgr_base subclasses + _mgr_advance_* helpers.

function _handle_run_end_click() {
    // Sprint 3 H1 fix: obj_game.persistent=true + dup guard means room_restart() keeps old state.
    // game_restart() is the correct path to fully reset (persistent obj destroyed, Create re-runs).
    if (keyboard_check_pressed(ord("R"))) {
        game_restart();
    }
    var _cx = display_get_gui_width()/2;
    if (_btn_click(_cx - 100, 600, 200, 50)) {
        game_restart();
    }
}

function _handle_item_bar_click() {
    var _items = obj_game.items;
    if (array_length(_items) == 0) return;
    // Sprint 3 Phase 2b.1: item bar moved to bottom HUD (x=400, y=_win_h-55)
    // to match Draw_64's new layout. Must stay in sync with _draw_item_bar call site.
    var _x = 400;
    var _y = display_get_gui_height() - 55;
    for (var i = 0; i < array_length(_items); i++) {
        var _ix = _x + i * 45;
        if (_click_in_rect(_ix, _y, 40, 50)) {
            var _item = _items[i];
            if (_item.current_charges > 0) {
                if (item_use(_item.id)) {
                    _item.current_charges -= 1;
                    show_debug_message("[items] used " + _item.id + ", charges now " + string(_item.current_charges) + "/" + string(_item.max_charges));
                    // 2026-04-26: when charges hit 0, remove slot (per user "用完就没有了, 槽位变空").
                    if (_item.current_charges <= 0) {
                        array_delete(obj_game.items, i, 1);
                        show_debug_message("[items] removed empty slot " + _item.id);
                    }
                } else {
                    show_debug_message("[items] item_use refused for " + _item.id + " (no charges deducted)");
                }
            }
            return;
        }
    }
}

// Master dispatcher
function _handle_ui_clicks() {
    if (obj_game.ui_overlay_open != OV_NONE) {
        if (keyboard_check_pressed(vk_escape)) {
            // Phase 1 Batch 4 (B4/B5): ESC closes scry/pile_picker overlays cleanly.
            // Mirrors the CANCEL button logic in each overlay's click handler so leftover
            // face-up cards / target strings don't leak across opens.
            if (obj_game.ui_overlay_open == OV_SCRY_TOP_3) {
                // 2026-04-26: permanent face-up rule — don't flip back face-down on ESC.
                // is_peek_revealed=true was set in handler, cards stay visible in draw_pile.
                obj_game.ui_scry_cards = [];
            } else if (obj_game.ui_overlay_open == OV_PILE_PICKER) {
                obj_game.ui_pile_picker_target = "";
            }
            // Backlog cleanup: respect back-stack (e.g. pause → settings → ESC = back to pause).
            var _back = obj_game.ui_overlay_prev;
            obj_game.ui_overlay_prev = "";
            obj_game.ui_overlay_open = (_back != "") ? _back : OV_NONE;
            return;
        }
        _handle_overlay_interaction();
        return;
    }
    // Phase 1 Batch 4 (B3): ESC cancels card-select mode. 2026-04-26: route through _exit_select_card_mode
    // so callback-specific cleanup (e.g. force_opp_replay opp_hand hoverable reset) also runs.
    if (obj_game.ui_select_card_mode && keyboard_check_pressed(vk_escape)) {
        show_debug_message("[select_card_mode] cancelled via ESC (callback=" + obj_game.ui_select_card_callback + ")");
        _exit_select_card_mode();
        return;
    }
    // Phase 1 Batch 5 (D3): ESC opens pause overlay during in-battle states.
    // Excluded: TITLE / RUN_VICTORY / RUN_DEFEAT (already menu-state, no pause needed).
    if (keyboard_check_pressed(vk_escape)
        && obj_game.state != "TITLE"
        && obj_game.state != "RUN_VICTORY"
        && obj_game.state != "RUN_DEFEAT") {
        obj_game.ui_overlay_open = OV_PAUSE;
        return;
    }
    // Phase 1 Batch 5 (D2): TITLE button clicks (SETTINGS / REPLAY TUTORIAL).
    if (obj_game.state == "TITLE") {
        _handle_title_click();
    }
    // 2026-04-26: replaced 4 corner buttons with 4 pile-region click. Active during PLAYER_WAIT only
    // (consistent with item bar gating — avoids clicks during DEAL/SHUFFLE/DISCARD).
    if (obj_game.state == "PLAYER_WAIT") {
        _handle_pile_click_regions();
    }
    // Block other handling in TITLE / RUN_VICTORY / RUN_DEFEAT
    if (obj_game.state != "TITLE"
        && obj_game.state != "RUN_VICTORY"
        && obj_game.state != "RUN_DEFEAT") {
        // Phase 1 Batch 1 (A1 review M1 fix): item bar only clickable during PLAYER_WAIT.
        // Other states (DEAL/SHUFFLE/REVEAL/JUDGE/DISCARD) have race conditions:
        //   - draw_extra during DEAL/SHUFFLE concurrently mutates player_draw_pile w/ obj_game Step_0
        //   - peek_opp_hand during REVEAL fires after opp_play.face_up flipped (no-op or stale)
        //   - immune_this_round during JUDGE/DISCARD is too late (damage already applied)
        // PLAYER_WAIT is the only safe window (player free-selecting cards, awaiting DUEL click).
        if (obj_game.state == "PLAYER_WAIT") {
            _handle_item_bar_click();
        }
    }
    // Phase 1 Batch 6 (F3) cleanup: stale comment block removed. Old Round 3 overlay click
    // handlers (_handle_branch_click / _handle_shop_click / etc) are gone — fully deleted in
    // Phase 2e.4 when the 6 obj_*_mgr subclasses owned their own UI per D56 architecture.
    switch (obj_game.state) {
        case "PLAYER_WAIT":         _handle_duel_click();     break;   // Sprint 3 Phase 2b.6
        case "RUN_VICTORY":
        case "RUN_DEFEAT":          _handle_run_end_click();  break;
    }
}

/// @desc H-2 fix: single source of truth for DUEL button rect.
/// Both _handle_duel_click (click detection) and obj_game.Draw_64 (visual draw) call this.
/// Keeps rect in sync — changing button dims/position requires only editing this function.
function _duel_btn_rect() {
    // 2026-04-26 v3.2: DUEL right side, bigger circle so text fits + clear visual.
    // Center (1080, 370), dia 100 → bbox (1030, 320, 100, 100). Right of all play cards (640).
    // Doesn't overlap OPP_DISCARD region (1145+) or PLR_PLAY (top 400, bot 540).
    return {
        x: 1030,
        y: 320,
        w: 100,
        h: 100
    };
}

/// @desc Sprint 3 Phase 2b.6: DUEL button click handler — commits the currently selected card.
/// Rect fetched from `_duel_btn_rect()` so click detection stays in sync with Draw_64.
/// Disabled (no-op) when no card is selected; enabled state drawn as HIGHLIGHT in Draw_64.
function _handle_duel_click() {
    if (obj_game.selected_card == noone) return;
    var _r = _duel_btn_rect();
    if (_click_in_rect(_r.x, _r.y, _r.w, _r.h)) {
        _player_commit_play(obj_game.selected_card);
    }
}

// UI per-frame updates (HP lerp + flash timer). Called from obj_game Step.
function _ui_per_frame_update() {
    // 2026-04-27: overlay open/close SFX edge detection (single point, all overlay sites covered).
    if (obj_game.prev_overlay != obj_game.ui_overlay_open) {
        if (obj_game.prev_overlay == OV_NONE && obj_game.ui_overlay_open != OV_NONE) {
            _play_sfx(snd_ui_open);
        } else if (obj_game.prev_overlay != OV_NONE && obj_game.ui_overlay_open == OV_NONE) {
            _play_sfx(snd_ui_close);
        }
        // overlay→overlay transition (e.g. pause → settings) — treat as silent (avoid double sfx).
        obj_game.prev_overlay = obj_game.ui_overlay_open;
    }
    // 2026-04-27: BGM auto-switch by state (in room0). TITLE → bgm_title_screen,
    // RUN_VICTORY/DEFEAT → bgm_run_end_win. Battle BGM TBD (user generating).
    if (room == room0) {
        if (obj_game.state == "TITLE") {
            _play_bgm(bgm_title_screen);
        } else if (obj_game.state == "RUN_VICTORY" || obj_game.state == "RUN_DEFEAT") {
            _play_bgm(bgm_run_end_win);
        }
    }

    obj_game.ui_player_hp_display = lerp(obj_game.ui_player_hp_display, obj_game.player_hp, 0.2);
    obj_game.ui_opp_hp_display    = lerp(obj_game.ui_opp_hp_display,    obj_game.opp_hp,    0.2);
    if (obj_game.ui_hp_flash_timer > 0) obj_game.ui_hp_flash_timer--;
    // Phase 1 Batch 2 (C2): hit FX timers tick (decay screen shake + hit flash vignette)
    if (obj_game.ui_screen_shake_timer > 0) obj_game.ui_screen_shake_timer--;
    if (obj_game.ui_hit_flash_timer > 0) obj_game.ui_hit_flash_timer--;
    // Reset tooltip target at start of frame; obj_card Step will re-set it if hovered
    obj_game.ui_tooltip_target = noone;

    // Sprint 3 Phase 2b.3: player hand fan layout (only when player can interact with hand)
    if (obj_game.state == "PLAYER_TURN" || obj_game.state == "PLAYER_WAIT") {
        _update_plr_hand_fan();
    }

    // Sprint 3 Phase 2b.4: opp hand mirror fan (always expanded; no hover; cards face down)
    _update_opp_hand_fan();
}

/// @desc Sprint 3 Phase 2c: shared BG + status bar for all non-battle rooms.
/// Each obj_*_mgr subclass calls this at the top of its Draw_64 (instead of event_inherited,
/// which would also draw the placeholder title/hint from the base class).
/// Draws: dark BG fill + top HUD (HP / Gold / Items / Battle counter) via obj_game data.
function _draw_room_bg_and_status() {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();

    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(0, 0, _w, _h, false);

    draw_set_font(fnt_score);
    if (instance_exists(obj_game)) {
        draw_set_colour(UI_COLOR_NEUTRAL);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text_transformed(20, 20, "HP: " + string(obj_game.player_hp) + "/" + string(obj_game.player_max_hp), 0.4, 0.4, 0);
        draw_text_transformed(200, 20, "Gold: " + string(obj_game.gold), 0.4, 0.4, 0);
        draw_text_transformed(340, 20, "Items: " + string(array_length(obj_game.items)) + "/4", 0.4, 0.4, 0);
        draw_text_transformed(_w - 200, 20, "Battle " + string(obj_game.current_battle_index + 1) + "/6", 0.4, 0.4, 0);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_set_alpha(1);
}

/// @desc Helper: is obj_game in a state where card positions are animating (DEAL pipeline / SHUFFLE)?
/// Fan position updates must skip these states, otherwise they'll override per-state target_x/y
/// (Step_0 sets them during DEAL, SHUFFLE_COLLECT etc.) and cause visible jerks.
function _is_card_animating_state() {
    var _s = obj_game.state;
    return _s == "BATTLE_START" || _s == "DEAL_GUARD" || _s == "DEAL"
        || _s == "DEAL_H1_CHECK" || _s == "FLIP_PLAYER"
        || _s == "SHUFFLE_COLLECT" || _s == "SHUFFLE_ANIM"
        || _s == "SHUFFLE_MIX" || _s == "SHUFFLE_RETURN";
}

/// @desc Sprint 3 Phase 2b.4 (H-1 fix): mirror fan for opp hand.
/// Pivot at top (y=40), fan opens downward (opposite of player's upward fan). No hover, no pop
/// — player doesn't interact with opp hand. State gate skips DEAL/SHUFFLE pipeline to avoid
/// overriding Step_0's per-state target_x/y.
function _update_opp_hand_fan() {
    if (_is_card_animating_state()) return;
    // 2026-04-26 v3: active count fan (n=2 redistributes to 2-card spread, no mid-gap).
    var _active = [];
    for (var _oi = 0; _oi < 3; _oi++) {
        if (obj_game.opp_hand[_oi] != noone) array_push(_active, obj_game.opp_hand[_oi]);
    }
    var _n = array_length(_active);
    for (var _k = 0; _k < _n; _k++) {
        var _card = _active[_k];
        var _angle_deg;
        if (_n == 1) _angle_deg = 0;
        else if (_n == 2) _angle_deg = (_k - 0.5) * obj_game.HAND_FAN_ANGLE_DEG;
        else _angle_deg = (_k - 1) * obj_game.HAND_FAN_ANGLE_DEG;
        var _angle_rad = degtorad(_angle_deg);
        var _dx = sin(_angle_rad) * obj_game.HAND_FAN_RADIUS;
        var _dy = cos(_angle_rad) * obj_game.HAND_FAN_RADIUS;   // +cos = downward
        _card.target_x = obj_game.HAND_FAN_PIVOT_X + _dx;
        _card.target_y = obj_game.OPP_HAND_FAN_PIVOT_Y + _dy;
        // Opp tilt: mirrored direction (cards above the table tilt outward symmetrically).
        var _tilt_unit;
        if (_n == 1) _tilt_unit = 0;
        else _tilt_unit = (_k / (_n - 1)) * 2.0 - 1.0;
        _card.target_rotation = _tilt_unit * obj_game.HAND_FAN_ROTATION_DEG;
        _card.is_moving = true;
        _card.move_speed = 0.25;
    }
}

/// @desc Compute per-frame player hand positions (fan expanded/collapsed + hover pop).
/// Sets plr_hand[i].target_x/target_y to drive the lerp animation in obj_card.Step_0.
/// hover threshold: mouse y > HAND_FAN_HOVER_THRESHOLD_Y → expand.
/// Hovered card (mouse over its current rect) pops outward HAND_FAN_POP_PX along its radial vector.
function _update_plr_hand_fan() {
    obj_game.plr_hand_fan_expanded = (mouse_y > obj_game.HAND_FAN_HOVER_THRESHOLD_Y);
    obj_game.plr_hand_hovered_idx = -1;

    // 2026-04-26 v3: build active list (excludes noone slots + selected_card).
    // Fan distributes N cards on arc with proper spacing (no mid-gap when 2 cards left).
    var _active = [];
    var _active_to_orig = [];   // map active-index → plr_hand[orig_index]
    for (var _oi = 0; _oi < 3; _oi++) {
        var _hc = obj_game.plr_hand[_oi];
        if (_hc == noone) continue;
        if (_hc == obj_game.selected_card) continue;
        array_push(_active, _hc);
        array_push(_active_to_orig, _oi);
    }
    var _n = array_length(_active);

    // First pass: hover detection on active cards
    if (obj_game.plr_hand_fan_expanded) {
        for (var _k = 0; _k < _n; _k++) {
            var _angle_deg_h;
            if (_n == 1) _angle_deg_h = 0;
            else if (_n == 2) _angle_deg_h = (_k - 0.5) * obj_game.HAND_FAN_ANGLE_DEG;
            else _angle_deg_h = (_k - 1) * obj_game.HAND_FAN_ANGLE_DEG;
            var _angle_rad_h = degtorad(_angle_deg_h);
            var _dx_h = sin(_angle_rad_h) * obj_game.HAND_FAN_RADIUS;
            var _dy_h = -cos(_angle_rad_h) * obj_game.HAND_FAN_RADIUS;
            var _tx_base = obj_game.HAND_FAN_PIVOT_X + _dx_h;
            var _ty_base = obj_game.HAND_FAN_PIVOT_Y + _dy_h;
            var _pop_h = obj_game.HAND_FAN_POP_PX / obj_game.HAND_FAN_RADIUS;
            var _tx_pop = _tx_base + _dx_h * _pop_h;
            var _ty_pop = _ty_base + _dy_h * _pop_h;
            var _in_base = (mouse_x > _tx_base - HAND_CARD_HALF_W && mouse_x < _tx_base + HAND_CARD_HALF_W &&
                           mouse_y > _ty_base - HAND_CARD_HALF_H && mouse_y < _ty_base + HAND_CARD_HALF_H);
            var _in_pop  = (mouse_x > _tx_pop  - HAND_CARD_HALF_W && mouse_x < _tx_pop  + HAND_CARD_HALF_W &&
                           mouse_y > _ty_pop  - HAND_CARD_HALF_H && mouse_y < _ty_pop  + HAND_CARD_HALF_H);
            if (_in_base || _in_pop) {
                obj_game.plr_hand_hovered_idx = _active_to_orig[_k];
            }
        }
    }

    // Second pass: per active card → fan target
    for (var _k = 0; _k < _n; _k++) {
        var _card = _active[_k];
        var _orig_idx = _active_to_orig[_k];

        if (obj_game.plr_hand_fan_expanded) {
            var _angle_deg;
            if (_n == 1) _angle_deg = 0;
            else if (_n == 2) _angle_deg = (_k - 0.5) * obj_game.HAND_FAN_ANGLE_DEG;
            else _angle_deg = (_k - 1) * obj_game.HAND_FAN_ANGLE_DEG;
            var _angle_rad = degtorad(_angle_deg);
            var _dx = sin(_angle_rad) * obj_game.HAND_FAN_RADIUS;
            var _dy = -cos(_angle_rad) * obj_game.HAND_FAN_RADIUS;
            var _tx = obj_game.HAND_FAN_PIVOT_X + _dx;
            var _ty = obj_game.HAND_FAN_PIVOT_Y + _dy;

            if (obj_game.plr_hand_hovered_idx == _orig_idx) {
                var _pop = obj_game.HAND_FAN_POP_PX / obj_game.HAND_FAN_RADIUS;
                _tx += _dx * _pop;
                _ty += _dy * _pop;
            }

            _card.target_x = _tx;
            _card.target_y = _ty;
            // Tilt: outward (peacock). Map normalized k position [0..1] to ±ROTATION.
            var _tilt_unit;
            if (_n == 1) _tilt_unit = 0;
            else _tilt_unit = (_k / (_n - 1)) * 2.0 - 1.0;   // -1 (leftmost) to +1 (rightmost)
            _card.target_rotation = -_tilt_unit * obj_game.HAND_FAN_ROTATION_DEG;
        } else {
            // Collapsed: tight stack at fan center (y=560, just below mid-table).
            _card.target_x = obj_game.HAND_FAN_PIVOT_X + (_k - (_n - 1) / 2) * obj_game.HAND_FAN_COLLAPSED_SPREAD;
            _card.target_y = 560;
            _card.target_rotation = 0;
        }
        _card.is_moving = true;
        _card.move_speed = 0.25;
    }
}

// ===== Overlay drawers =====

function _draw_full_overlay_bg(_alpha) {
    draw_set_alpha(_alpha);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
}

// Phase 2e.4 Deleted: 6 Round 3 overlay drawers — _draw_branch_choice_overlay /
// _draw_reward_overlay / _draw_shop_overlay / _draw_rest_overlay / _draw_event_overlay /
// _draw_remove_overlay — all replaced by independent rooms (rm_run_map / rm_reward / rm_shop /
// rm_rest / rm_event / rm_remove) under D56 architecture. obj_room_mgr_base subclasses own
// their UI via Draw_64 overrides.

function _draw_run_end_overlay() {
    // 2026-04-26 simplification per user: only the title text + RESTART button. No HP / battle counter.
    _draw_full_overlay_bg(0.92);
    var _cx = display_get_gui_width()/2;
    var _cy = display_get_gui_height()/2;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);

    if (obj_game.state == "RUN_VICTORY") {
        draw_set_colour(UI_COLOR_PLAYER);
        draw_text_transformed(_cx, _cy - 60, "VICTORY", 1.5, 1.5, 0);
    } else {
        draw_set_colour(UI_COLOR_OPP);
        draw_text_transformed(_cx, _cy - 60, "DEFEAT", 1.5, 1.5, 0);
    }

    _draw_button(_cx - 100, _cy + 80, 200, 50, "RESTART (R)", 0.45);
}

function _draw_deck_overlay() {
    _draw_full_overlay_bg(0.9);
    var _o = obj_game.ui_overlay_open;
    var _cx = display_get_gui_width()/2;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);

    // 2026-04-26 rewrite: grid of individual cards + per-card hover tooltip showing rules.
    // 4 sources: 3 instance arrays (player_draw / player_discard / opp_discard) + 1 struct
    // composition (enemy full deck). Player views show "remaining" semantics; enemy view shows
    // FULL composition (always visible per user spec).
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _title = "", _subtitle = "";
    switch (_o) {
        case OV_DECK_PD:  _title = "MY DECK"; _subtitle = "(remaining cards in deck)"; break;
        case OV_DECK_PDC: _title = "MY DISCARD"; _subtitle = "(used this battle)"; break;
        case OV_DECK_OD:  _title = "ENEMY DECK"; _subtitle = "(complete composition)"; break;
        case OV_DECK_ODC: _title = "ENEMY DISCARD"; _subtitle = "(enemy used this battle)"; break;
    }
    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, 70, _title, 0.7, 0.7, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_cx, 110, _subtitle, 0.32, 0.32, 0);

    // Build _cards_to_show: array of {card_type:int, rules:array, display_name:string}.
    var _cards_to_show = [];
    if (_o == OV_DECK_PD) {
        for (var _i = 0; _i < array_length(obj_game.player_draw_pile); _i++) {
            var _c = obj_game.player_draw_pile[_i];
            if (!instance_exists(_c)) continue;
            array_push(_cards_to_show, {card_type: _c.card_type, rules: _c.rules, display_name: _c.display_name});
        }
        // 2026-04-26: sort by card_type so future draw order is hidden (player can see WHAT
        // remains, not WHEN). Per user "查看还有哪些牌没抽到, 而不是直接展示完整的排序".
        array_sort(_cards_to_show, function(_a, _b) {
            return _a.card_type - _b.card_type;
        });
    } else if (_o == OV_DECK_PDC) {
        for (var _i = 0; _i < array_length(obj_game.player_discard_pile); _i++) {
            var _c = obj_game.player_discard_pile[_i];
            if (!instance_exists(_c)) continue;
            array_push(_cards_to_show, {card_type: _c.card_type, rules: _c.rules, display_name: _c.display_name});
        }
    } else if (_o == OV_DECK_ODC) {
        for (var _i = 0; _i < array_length(obj_game.opp_discard_pile); _i++) {
            var _c = obj_game.opp_discard_pile[_i];
            if (!instance_exists(_c)) continue;
            array_push(_cards_to_show, {card_type: _c.card_type, rules: _c.rules, display_name: _c.display_name});
        }
    } else if (_o == OV_DECK_OD) {
        var _enemy = _get_next_or_current_enemy();
        if (!is_undefined(_enemy)) {
            var _comp = _enemy.deck_composition;
            var _types = ["rock", "scissors", "paper"];
            for (var _t = 0; _t < 3; _t++) {
                var _count = _comp[$ _types[_t]] ?? 0;
                for (var _ci = 0; _ci < _count; _ci++) {
                    array_push(_cards_to_show, {card_type: _str_to_card_type_int(_types[_t]), rules: [], display_name: ""});
                }
            }
        }
    }

    var _total = array_length(_cards_to_show);
    if (_total == 0) {
        draw_set_colour(UI_COLOR_WARNING);
        draw_set_halign(fa_center);
        draw_text_transformed(_cx, _h / 2, "(empty)", 0.5, 0.5, 0);
        _draw_button(_w - 140, _h - 70, 120, 40, "CLOSE (Esc)", 0.3);
        return;
    }
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_set_halign(fa_center);
    draw_text_transformed(_cx, 145, "Total: " + string(_total) + " cards — hover any card for rules", 0.28, 0.28, 0);

    // Grid: 8 cols × N rows. Cards 70×98 (mini), 16/30 gaps.
    var _cols = 8;
    var _card_w = 70;
    var _card_h = 98;
    var _gap_x = 16;
    var _gap_y = 30;
    var _grid_w = _cols * _card_w + (_cols - 1) * _gap_x;
    var _start_x = _cx - _grid_w / 2;
    var _start_y = 180;
    var _hovered_idx = -1;
    for (var _i = 0; _i < _total; _i++) {
        var _c = _cards_to_show[_i];
        var _row = _i div _cols;
        var _col_i = _i mod _cols;
        var _x = _start_x + _col_i * (_card_w + _gap_x);
        var _y = _start_y + _row * (_card_h + _gap_y);
        var _spr = spr_card_back;
        switch (_c.card_type) {
            case 0: _spr = spr_card_rock;     break;
            case 1: _spr = spr_card_scissors; break;
            case 2: _spr = spr_card_paper;    break;
        }
        draw_sprite_ext(_spr, 0, _x, _y, _card_w / 99, _card_h / 140, 0, c_white, 1);
        if (_is_mouse_in_rect(_x, _y, _card_w, _card_h)) {
            _hovered_idx = _i;
            draw_set_alpha(0.85);
            draw_set_colour(UI_COLOR_HIGHLIGHT);
            draw_rectangle(_x - 2, _y - 2, _x + _card_w + 2, _y + _card_h + 2, true);
            draw_set_alpha(1);
        }
    }

    // Tooltip for hovered card (if has rules).
    if (_hovered_idx >= 0) {
        var _hc = _cards_to_show[_hovered_idx];
        if (array_length(_hc.rules) > 0) {
            var _tt_x = mouse_x + 16;
            var _tt_y = mouse_y + 16;
            var _tt_w = 280;
            var _tt_h = 14 + array_length(_hc.rules) * 20;
            if (_tt_x + _tt_w > _w) _tt_x = _w - _tt_w - 10;
            if (_tt_y + _tt_h > _h) _tt_y = _h - _tt_h - 10;
            draw_set_alpha(0.95);
            draw_set_colour(UI_COLOR_BG_MID);
            draw_rectangle(_tt_x, _tt_y, _tt_x + _tt_w, _tt_y + _tt_h, false);
            draw_set_colour(UI_COLOR_HIGHLIGHT);
            draw_rectangle(_tt_x, _tt_y, _tt_x + _tt_w, _tt_y + _tt_h, true);
            draw_set_alpha(1);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_colour(c_white);
            var _yy = _tt_y + 6;
            for (var _ri = 0; _ri < array_length(_hc.rules); _ri++) {
                var _rule = _hc.rules[_ri];
                var _level_str = (_rule.max_level > 1) ? (" [L" + string(_rule.level) + "/" + string(_rule.max_level) + "]") : "";
                draw_text_transformed(_tt_x + 8, _yy, "- " + _rule.description_text + _level_str, 0.22, 0.22, 0);
                _yy += 20;
            }
        }
    }

    _draw_button(_w - 140, _h - 70, 120, 40, "CLOSE (Esc)", 0.3);
}

function _draw_player_deck_counts(_deck, _cx, _y) {
    // Count by type
    var _rock = 0, _scissors = 0, _paper = 0;
    for (var i = 0; i < array_length(_deck); i++) {
        var _card = _deck[i];
        switch (_card.type_name) {
            case "rock":     _rock++; break;
            case "scissors": _scissors++; break;
            case "paper":    _paper++; break;
        }
    }
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_font(fnt_score);
    draw_text_transformed(_cx, _y, "TOTAL: " + string(array_length(_deck)) + " cards", 0.4, 0.4, 0);
    draw_text_transformed(_cx - 180, _y + 80, "ROCK",     0.35, 0.35, 0);
    draw_text_transformed(_cx - 180, _y + 120, "× " + string(_rock), 0.5, 0.5, 0);
    draw_text_transformed(_cx,       _y + 80, "SCISSORS", 0.35, 0.35, 0);
    draw_text_transformed(_cx,       _y + 120, "× " + string(_scissors), 0.5, 0.5, 0);
    draw_text_transformed(_cx + 180, _y + 80, "PAPER",    0.35, 0.35, 0);
    draw_text_transformed(_cx + 180, _y + 120, "× " + string(_paper), 0.5, 0.5, 0);
}

function _draw_instance_pile_counts(_pile, _cx, _y) {
    var _rock = 0, _scissors = 0, _paper = 0;
    for (var i = 0; i < array_length(_pile); i++) {
        var _inst = _pile[i];
        if (!instance_exists(_inst)) continue;
        switch (_inst.card_type) {
            case 0: _rock++; break;
            case 1: _scissors++; break;
            case 2: _paper++; break;
        }
    }
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_font(fnt_score);
    draw_text_transformed(_cx, _y, "TOTAL: " + string(array_length(_pile)) + " cards", 0.4, 0.4, 0);
    draw_text_transformed(_cx - 180, _y + 80, "ROCK",     0.35, 0.35, 0);
    draw_text_transformed(_cx - 180, _y + 120, "× " + string(_rock), 0.5, 0.5, 0);
    draw_text_transformed(_cx,       _y + 80, "SCISSORS", 0.35, 0.35, 0);
    draw_text_transformed(_cx,       _y + 120, "× " + string(_scissors), 0.5, 0.5, 0);
    draw_text_transformed(_cx + 180, _y + 80, "PAPER",    0.35, 0.35, 0);
    draw_text_transformed(_cx + 180, _y + 120, "× " + string(_paper), 0.5, 0.5, 0);
}

function _draw_enemy_deck_composition(_comp, _cx, _y) {
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_font(fnt_score);
    var _rock = _comp[$ "rock"] ?? 0;
    var _scissors = _comp[$ "scissors"] ?? 0;
    var _paper = _comp[$ "paper"] ?? 0;
    var _total = _rock + _scissors + _paper;
    draw_text_transformed(_cx, _y, "TOTAL: " + string(_total) + " cards", 0.4, 0.4, 0);
    draw_text_transformed(_cx - 180, _y + 80, "ROCK",     0.35, 0.35, 0);
    draw_text_transformed(_cx - 180, _y + 120, "× " + string(_rock), 0.5, 0.5, 0);
    draw_text_transformed(_cx,       _y + 80, "SCISSORS", 0.35, 0.35, 0);
    draw_text_transformed(_cx,       _y + 120, "× " + string(_scissors), 0.5, 0.5, 0);
    draw_text_transformed(_cx + 180, _y + 80, "PAPER",    0.35, 0.35, 0);
    draw_text_transformed(_cx + 180, _y + 120, "× " + string(_paper), 0.5, 0.5, 0);
    draw_set_alpha(0.6);
    draw_text_transformed(_cx, _y + 200, "(complete composition; subtract discard to estimate remaining)", 0.22, 0.22, 0);
    draw_set_alpha(1);
}

// Phase 2e.4 Deleted: _draw_remove_confirm_dialog — replaced by rm_remove room's own confirm flow.

function _draw_card_tooltip(_card) {
    if (!instance_exists(_card)) return;
    if (!_card.face_up) return;
    var _tx = _card.x;
    var _ty = _card.y - 120;
    var _w = 220;
    var _h = 100;
    // Clamp within screen
    if (_tx + _w > display_get_gui_width()) _tx = display_get_gui_width() - _w - 10;
    if (_tx < 10) _tx = 10;
    if (_ty < 10) _ty = _card.y + 145;   // flip below if too close to top

    draw_set_alpha(0.95);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(_tx, _ty, _tx + _w, _ty + _h, false);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_PLAYER);
    draw_rectangle(_tx, _ty, _tx + _w, _ty + _h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(c_white);
    var _name = (_card.display_name != "") ? _card.display_name : "(no name)";
    draw_text_transformed(_tx + 8, _ty + 6, _name, 0.3, 0.3, 0);

    if (array_length(_card.rules) == 0) {
        draw_set_alpha(0.6);
        draw_text_transformed(_tx + 8, _ty + 40, "(no rules)", 0.22, 0.22, 0);
        draw_set_alpha(1);
    } else {
        var _yy = _ty + 30;
        for (var i = 0; i < array_length(_card.rules); i++) {
            var _r = _card.rules[i];
            var _level_str = (_r.max_level > 1) ? (" [L" + string(_r.level) + "/" + string(_r.max_level) + "]") : "";
            draw_text_transformed(_tx + 8, _yy, "• " + _r.description_text + _level_str, 0.2, 0.2, 0);
            _yy += 18;
            if (_yy > _ty + _h - 10) break;
        }
    }
}

// ===== Phase 1 Batch 4 (B4): Scry top-3 overlay =====
// Shows top 3 of player_draw_pile face-up + 3 "Take #N" buttons.
// Pick: chosen card → first empty plr_hand slot; remaining 2 reshuffle into random draw_pile positions.

function _draw_scry_overlay() {
    _draw_full_overlay_bg(0.9);
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);

    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, 100, "SCRY — TOP OF DECK", 0.6, 0.6, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_cx, 145, "Pick 1 to draw — others shuffle back into the deck", 0.32, 0.32, 0);

    var _scry = obj_game.ui_scry_cards;
    var _count = array_length(_scry);
    if (_count == 0) {
        draw_set_colour(UI_COLOR_WARNING);
        draw_text_transformed(_cx, _cy, "(empty)", 0.5, 0.5, 0);
        _draw_button(display_get_gui_width() - 140, display_get_gui_height() - 70, 120, 40, "CLOSE (Esc)", 0.3);
        return;
    }

    // Card sprite display (3 cards horizontally with name + rule dot)
    var _card_w = 90;
    var _card_h = 126;
    var _spacing = 50;
    var _total_w = _count * _card_w + (_count - 1) * _spacing;
    var _start_x = _cx - _total_w / 2;
    for (var i = 0; i < _count; i++) {
        var _c = _scry[i];
        var _x = _start_x + i * (_card_w + _spacing) + _card_w / 2;
        var _y = _cy - 20;

        // Card sprite (face-up, by type)
        var _spr = spr_card_back;
        switch (_c.card_type) {
            case 0: _spr = spr_card_rock;     break;
            case 1: _spr = spr_card_scissors; break;
            case 2: _spr = spr_card_paper;    break;
        }
        draw_sprite_ext(_spr, 0, _x - _card_w / 2, _y - _card_h / 2, 1, 1, 0, c_white, 1);

        // Display name underneath
        if (_c.display_name != "") {
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(UI_COLOR_NEUTRAL);
            draw_text_transformed(_x, _y + _card_h / 2 + 18, _c.display_name, 0.28, 0.28, 0);
        }

        // "Take #N" button
        var _btn_y = _y + _card_h / 2 + 50;
        _draw_button(_x - 45, _btn_y, 90, 36, "TAKE #" + string(i + 1), 0.32);
    }

    // Cancel button bottom
    _draw_button(_cx - 70, display_get_gui_height() - 70, 140, 36, "CANCEL", 0.3);
}

function _handle_scry_click() {
    if (!mouse_check_button_pressed(mb_left)) return;
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;
    var _scry = obj_game.ui_scry_cards;
    var _count = array_length(_scry);

    // Cancel button: just close, refund? No — handler succeeded so charge already deducted.
    // (Player committed to using the item; cancel just means "skip without picking".)
    if (_click_in_rect(_cx - 70, display_get_gui_height() - 70, 140, 36)) {
        // 2026-04-26: cards stay face-up permanently (is_peek_revealed=true set in handler).
        // No flip-back-face-down loop here. Cards remain in draw_pile, visible as face-up to player.
        obj_game.ui_scry_cards = [];
        obj_game.ui_overlay_open = OV_NONE;
        show_debug_message("[scry overlay] cancelled — 3 cards stay in draw pile (permanently revealed)");
        return;
    }

    // Take #N buttons
    if (_count == 0) {
        // Close button on empty
        if (_click_in_rect(display_get_gui_width() - 140, display_get_gui_height() - 70, 120, 40)) {
            obj_game.ui_overlay_open = OV_NONE;
            obj_game.ui_scry_cards = [];
        }
        return;
    }

    var _card_w = 90;
    var _card_h = 126;
    var _spacing = 50;
    var _total_w = _count * _card_w + (_count - 1) * _spacing;
    var _start_x = _cx - _total_w / 2;
    for (var i = 0; i < _count; i++) {
        var _x = _start_x + i * (_card_w + _spacing) + _card_w / 2;
        var _y = _cy - 20;
        var _btn_y = _y + _card_h / 2 + 50;
        if (_click_in_rect(_x - 45, _btn_y, 90, 36)) {
            // Take card #i: move to first empty hand slot, others reshuffle
            var _picked = _scry[i];
            // Find empty hand slot
            var _slot = -1;
            for (var j = 0; j < 3; j++) {
                if (obj_game.plr_hand[j] == noone) { _slot = j; break; }
            }
            if (_slot < 0) {
                show_debug_message("[scry overlay] hand full at pick time — abort");
                obj_game.ui_overlay_open = OV_NONE;
                obj_game.ui_scry_cards = [];
                return;
            }
            // Remove picked from draw_pile
            for (var j = array_length(obj_game.player_draw_pile) - 1; j >= 0; j--) {
                if (obj_game.player_draw_pile[j] == _picked) {
                    array_delete(obj_game.player_draw_pile, j, 1);
                    break;
                }
            }
            obj_game.plr_hand[_slot] = _picked;
            _picked.target_x = obj_game.HAND_X[_slot];
            _picked.target_y = obj_game.PLR_HAND_Y;
            _picked.is_moving = true;
            _picked.move_speed = 0.18;
            _picked.depth = -50 - _slot;
            _picked.hoverable = true;
            _picked.clickable = true;
            _picked.target_rotation = 0;
            // Already face-up from scry preview — keep as is.

            // Reshuffle other cards: flip back face-down + insert random pos in draw_pile
            // (they're still in draw_pile from original snapshot; we just shuffle their positions)
            var _shuffle_targets = [];
            for (var j = 0; j < _count; j++) {
                if (j == i) continue;
                array_push(_shuffle_targets, _scry[j]);
            }
            for (var k = 0; k < array_length(_shuffle_targets); k++) {
                var _other = _shuffle_targets[k];
                // Remove from draw_pile current position
                for (var m = array_length(obj_game.player_draw_pile) - 1; m >= 0; m--) {
                    if (obj_game.player_draw_pile[m] == _other) {
                        array_delete(obj_game.player_draw_pile, m, 1);
                        break;
                    }
                }
                // Insert random position
                var _pile_size = array_length(obj_game.player_draw_pile);
                var _insert_at = (_pile_size > 0) ? irandom(_pile_size) : 0;
                array_insert(obj_game.player_draw_pile, _insert_at, _other);
                // 2026-04-26: permanent face-up — don't flip back face-down (is_peek_revealed=true).
                // Cards stay visible in draw_pile after reshuffle.
            }

            _play_sfx(snd_card_move);
            show_debug_message("[scry overlay] picked #" + string(i + 1) + ", reshuffled " + string(_count - 1));
            obj_game.ui_scry_cards = [];
            obj_game.ui_overlay_open = OV_NONE;
            return;
        }
    }
}

// ===== Phase 1 Batch 4 (B5): Pile picker overlay =====
// Shows opp_discard or player_discard pile face-up in a grid; click any card → moves to plr_hand.

function _draw_pile_picker_overlay() {
    _draw_full_overlay_bg(0.9);
    var _cx = display_get_gui_width() / 2;
    var _target = obj_game.ui_pile_picker_target;
    var _pile = (_target == "opp_discard") ? obj_game.opp_discard_pile : obj_game.player_discard_pile;
    var _label = (_target == "opp_discard") ? "STEAL FROM ENEMY DISCARD" : "RECOVER FROM YOUR DISCARD";

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, 100, _label, 0.55, 0.55, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_cx, 145, "Click a card to take it", 0.32, 0.32, 0);

    var _count = array_length(_pile);
    if (_count == 0) {
        draw_set_colour(UI_COLOR_WARNING);
        draw_text_transformed(_cx, display_get_gui_height() / 2, "(empty)", 0.5, 0.5, 0);
        _draw_button(display_get_gui_width() - 140, display_get_gui_height() - 70, 120, 40, "CLOSE (Esc)", 0.3);
        return;
    }

    // Grid: 6 cols × ceil(N/6) rows
    var _cols = 6;
    var _card_w = 70;
    var _card_h = 98;
    var _spacing_x = 18;
    var _spacing_y = 30;
    var _grid_w = _cols * _card_w + (_cols - 1) * _spacing_x;
    var _start_x = _cx - _grid_w / 2;
    var _start_y = 200;

    for (var i = 0; i < _count; i++) {
        var _c = _pile[i];
        if (!instance_exists(_c)) continue;
        var _r = i div _cols;
        var _col = i mod _cols;
        var _x = _start_x + _col * (_card_w + _spacing_x);
        var _y = _start_y + _r * (_card_h + _spacing_y);

        var _spr = spr_card_back;
        switch (_c.card_type) {
            case 0: _spr = spr_card_rock;     break;
            case 1: _spr = spr_card_scissors; break;
            case 2: _spr = spr_card_paper;    break;
        }
        draw_sprite_ext(_spr, 0, _x, _y, _card_w / 100, _card_h / 140, 0, c_white, 1);

        // Hover highlight
        if (_is_mouse_in_rect(_x, _y, _card_w, _card_h)) {
            draw_set_colour(UI_COLOR_HIGHLIGHT);
            draw_rectangle(_x - 2, _y - 2, _x + _card_w + 2, _y + _card_h + 2, true);
        }
    }

    _draw_button(_cx - 70, display_get_gui_height() - 70, 140, 36, "CANCEL", 0.3);
}

function _handle_pile_picker_click() {
    if (!mouse_check_button_pressed(mb_left)) return;
    var _cx = display_get_gui_width() / 2;
    var _target = obj_game.ui_pile_picker_target;
    var _pile = (_target == "opp_discard") ? obj_game.opp_discard_pile : obj_game.player_discard_pile;
    var _count = array_length(_pile);

    // Cancel button (refund? same as scry — charge already deducted)
    if (_click_in_rect(_cx - 70, display_get_gui_height() - 70, 140, 36)) {
        obj_game.ui_overlay_open = OV_NONE;
        obj_game.ui_pile_picker_target = "";
        show_debug_message("[pile picker] cancelled");
        return;
    }

    if (_count == 0) {
        if (_click_in_rect(display_get_gui_width() - 140, display_get_gui_height() - 70, 120, 40)) {
            obj_game.ui_overlay_open = OV_NONE;
            obj_game.ui_pile_picker_target = "";
        }
        return;
    }

    // Card grid (must mirror _draw_pile_picker_overlay layout exactly)
    var _cols = 6;
    var _card_w = 70;
    var _card_h = 98;
    var _spacing_x = 18;
    var _spacing_y = 30;
    var _grid_w = _cols * _card_w + (_cols - 1) * _spacing_x;
    var _start_x = _cx - _grid_w / 2;
    var _start_y = 200;
    for (var i = 0; i < _count; i++) {
        var _c = _pile[i];
        if (!instance_exists(_c)) continue;
        var _r = i div _cols;
        var _col = i mod _cols;
        var _x = _start_x + _col * (_card_w + _spacing_x);
        var _y = _start_y + _r * (_card_h + _spacing_y);
        if (_click_in_rect(_x, _y, _card_w, _card_h)) {
            // Move card from source pile to first empty plr_hand slot
            var _slot = -1;
            for (var j = 0; j < 3; j++) {
                if (obj_game.plr_hand[j] == noone) { _slot = j; break; }
            }
            if (_slot < 0) {
                show_debug_message("[pile picker] hand full at pick time — abort");
                obj_game.ui_overlay_open = OV_NONE;
                obj_game.ui_pile_picker_target = "";
                return;
            }
            // Remove from source pile
            array_delete(_pile, i, 1);
            if (_target == "opp_discard") {
                obj_game.opp_discard_pile = _pile;
                // Stolen opp card now belongs to player — flip ownership tag
                _c.card_owner = "player";
            } else {
                obj_game.player_discard_pile = _pile;
            }
            // Place in hand
            obj_game.plr_hand[_slot] = _c;
            _c.target_x = obj_game.HAND_X[_slot];
            _c.target_y = obj_game.PLR_HAND_Y;
            _c.is_moving = true;
            _c.move_speed = 0.18;
            _c.depth = -50 - _slot;
            _c.hoverable = true;
            _c.clickable = true;
            _c.target_rotation = 0;
            if (!_c.face_up) {
                _c.flip_state = 1;
                _c.flip_to_face = true;
            }
            _play_sfx(snd_card_move);
            show_debug_message("[pile picker] took card from " + _target + " idx=" + string(i) + " → hand slot " + string(_slot));
            obj_game.ui_overlay_open = OV_NONE;
            obj_game.ui_pile_picker_target = "";
            return;
        }
    }
}

// ===== Phase 1 Batch 5 (D1): Settings overlay =====
// Language toggle (zh/en) + 3 volume sliders + fullscreen toggle + CLOSE.
// Reachable from TITLE screen "SETTINGS" button OR pause overlay's "Settings" button.
// Persists to settings.ini on every change (write-through).

function _draw_settings_overlay() {
    _draw_full_overlay_bg(0.92);
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);

    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, 80, _t("ui_settings"), 0.85, 0.85, 0);

    // Layout: rows with label (left) + control (right), centered around cx with width 600.
    var _row_y = 170;
    var _row_step = 75;
    var _label_x = _cx - 280;
    var _ctrl_x = _cx + 40;

    // === Row 1: Language ===
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_label_x, _row_y, _t("ui_language"), 0.4, 0.4, 0);
    // 2 toggle buttons
    var _btn_w = 90, _btn_h = 36;
    var _zh_active = (global.current_language == "zh");
    var _en_active = (global.current_language == "en");
    draw_set_colour(_zh_active ? UI_COLOR_HIGHLIGHT : UI_COLOR_BG_MID);
    draw_rectangle(_ctrl_x, _row_y - _btn_h / 2, _ctrl_x + _btn_w, _row_y + _btn_h / 2, false);
    draw_set_colour(_zh_active ? UI_COLOR_BG : UI_COLOR_NEUTRAL);
    draw_rectangle(_ctrl_x, _row_y - _btn_h / 2, _ctrl_x + _btn_w, _row_y + _btn_h / 2, true);
    draw_set_halign(fa_center);
    draw_text_transformed(_ctrl_x + _btn_w / 2, _row_y, "中文", 0.35, 0.35, 0);

    var _en_x = _ctrl_x + _btn_w + 12;
    draw_set_colour(_en_active ? UI_COLOR_HIGHLIGHT : UI_COLOR_BG_MID);
    draw_rectangle(_en_x, _row_y - _btn_h / 2, _en_x + _btn_w, _row_y + _btn_h / 2, false);
    draw_set_colour(_en_active ? UI_COLOR_BG : UI_COLOR_NEUTRAL);
    draw_rectangle(_en_x, _row_y - _btn_h / 2, _en_x + _btn_w, _row_y + _btn_h / 2, true);
    draw_text_transformed(_en_x + _btn_w / 2, _row_y, "EN", 0.35, 0.35, 0);

    // === Rows 2-4: Volume sliders (master/sfx/music) ===
    var _vol_keys = ["ui_volume_master", "ui_volume_sfx", "ui_volume_music"];
    var _vol_values = [global.master_volume, global.sfx_volume, global.music_volume];
    for (var i = 0; i < 3; i++) {
        var _vy = _row_y + (i + 1) * _row_step;
        // Label
        draw_set_halign(fa_left);
        draw_set_colour(UI_COLOR_NEUTRAL);
        draw_text_transformed(_label_x, _vy, _t(_vol_keys[i]), 0.4, 0.4, 0);
        // Slider track
        var _slider_w = 220;
        var _slider_h = 8;
        var _slider_x = _ctrl_x;
        var _slider_y = _vy - _slider_h / 2;
        draw_set_colour(UI_COLOR_BG_MID);
        draw_rectangle(_slider_x, _slider_y, _slider_x + _slider_w, _slider_y + _slider_h, false);
        // Fill
        draw_set_colour(UI_COLOR_PLAYER);
        draw_rectangle(_slider_x, _slider_y, _slider_x + _slider_w * _vol_values[i], _slider_y + _slider_h, false);
        // Handle
        var _handle_x = _slider_x + _slider_w * _vol_values[i];
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_rectangle(_handle_x - 5, _slider_y - 8, _handle_x + 5, _slider_y + _slider_h + 8, false);
        // Value % label
        draw_set_halign(fa_left);
        draw_set_colour(UI_COLOR_NEUTRAL);
        draw_text_transformed(_slider_x + _slider_w + 16, _vy, string(round(_vol_values[i] * 100)) + "%", 0.35, 0.35, 0);
    }

    // === Row 5: Fullscreen toggle ===
    var _fy = _row_y + 4 * _row_step;
    draw_set_halign(fa_left);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_label_x, _fy, _t("ui_fullscreen"), 0.4, 0.4, 0);
    draw_set_colour(global.fullscreen ? UI_COLOR_HIGHLIGHT : UI_COLOR_BG_MID);
    draw_rectangle(_ctrl_x, _fy - _btn_h / 2, _ctrl_x + _btn_w, _fy + _btn_h / 2, false);
    draw_set_colour(global.fullscreen ? UI_COLOR_BG : UI_COLOR_NEUTRAL);
    draw_rectangle(_ctrl_x, _fy - _btn_h / 2, _ctrl_x + _btn_w, _fy + _btn_h / 2, true);
    draw_set_halign(fa_center);
    draw_text_transformed(_ctrl_x + _btn_w / 2, _fy, global.fullscreen ? _t("ui_on") : _t("ui_off"), 0.35, 0.35, 0);

    // === CLOSE button (bottom center) ===
    _draw_button(_cx - 90, _h - 90, 180, 44, _t("ui_close"), 0.4);
}

function _handle_settings_click() {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;
    var _row_y = 170;
    var _row_step = 75;
    var _ctrl_x = _cx + 40;
    var _btn_w = 90, _btn_h = 36;

    // Slider drag: live update during drag (audio responsive), persist ONLY on mouse release.
    // Phase 1 Batch 5 (D1 review HIGH-4 fix): without debounce, settings_save fires every frame
    // of drag = ~60 ini I/O ops/sec → frame stutter on slow disks + SSD wear.
    var _slider_w = 220;
    var _slider_dragging = false;
    if (mouse_check_button(mb_left)) {
        for (var i = 0; i < 3; i++) {
            var _vy = _row_y + (i + 1) * _row_step;
            if (mouse_y > _vy - 14 && mouse_y < _vy + 14
                && mouse_x >= _ctrl_x && mouse_x <= _ctrl_x + _slider_w) {
                var _new_val = clamp((mouse_x - _ctrl_x) / _slider_w, 0, 1);
                if      (i == 0) global.master_volume = _new_val;
                else if (i == 1) global.sfx_volume    = _new_val;
                else if (i == 2) global.music_volume  = _new_val;
                _apply_volume_settings();
                _slider_dragging = true;
                break;
            }
        }
    }
    // Persist only when player releases mouse on a slider (debounce — single I/O per drag).
    if (mouse_check_button_released(mb_left)) {
        // We can't easily detect "was dragging" without state, so save on any release while
        // mouse is still inside any slider's hit zone. Cheap heuristic, no false positives.
        for (var i = 0; i < 3; i++) {
            var _vy_r = _row_y + (i + 1) * _row_step;
            if (mouse_y > _vy_r - 14 && mouse_y < _vy_r + 14
                && mouse_x >= _ctrl_x && mouse_x <= _ctrl_x + _slider_w) {
                settings_save();
                return;
            }
        }
    }
    if (_slider_dragging) return;   // skip click checks if mid-drag

    // Single-click controls (only on _pressed)
    if (!mouse_check_button_pressed(mb_left)) return;

    // Language buttons
    if (_btn_click(_ctrl_x, _row_y - _btn_h / 2, _btn_w, _btn_h)) {
        _set_language("zh");
        settings_save();
        return;
    }
    var _en_x = _ctrl_x + _btn_w + 12;
    if (_btn_click(_en_x, _row_y - _btn_h / 2, _btn_w, _btn_h)) {
        _set_language("en");
        settings_save();
        return;
    }

    // Fullscreen toggle
    var _fy = _row_y + 4 * _row_step;
    if (_btn_click(_ctrl_x, _fy - _btn_h / 2, _btn_w, _btn_h)) {
        global.fullscreen = !global.fullscreen;
        window_set_fullscreen(global.fullscreen);
        settings_save();
        return;
    }

    // Close button — backlog cleanup: respect back-stack (pause → settings → close = back to pause).
    if (_btn_click(_cx - 90, _h - 90, 180, 44)) {
        var _back = obj_game.ui_overlay_prev;
        obj_game.ui_overlay_prev = "";
        obj_game.ui_overlay_open = (_back != "") ? _back : OV_NONE;
        return;
    }
}

// ===== Phase 1 Batch 5 (D3): Pause overlay =====
// 3 buttons stacked center: Resume / Settings / Quit to Title.

function _draw_pause_overlay() {
    _draw_full_overlay_bg(0.85);
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;
    var _cy = _h / 2;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, _cy - 160, _t("ui_pause"), 1.0, 1.0, 0);

    var _btn_w = 240, _btn_h = 50, _btn_gap = 18;
    _draw_button(_cx - _btn_w / 2, _cy - 40,                          _btn_w, _btn_h, _t("ui_resume"),       0.4);
    _draw_button(_cx - _btn_w / 2, _cy - 40 + (_btn_h + _btn_gap),    _btn_w, _btn_h, _t("ui_settings"),     0.4);
    _draw_button(_cx - _btn_w / 2, _cy - 40 + (_btn_h + _btn_gap)*2,  _btn_w, _btn_h, _t("ui_quit_to_title"),0.4);
}

function _handle_pause_click() {
    if (!mouse_check_button_pressed(mb_left)) return;
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;
    var _cy = _h / 2;
    var _btn_w = 240, _btn_h = 50, _btn_gap = 18;

    if (_btn_click(_cx - _btn_w / 2, _cy - 40, _btn_w, _btn_h)) {
        obj_game.ui_overlay_prev = "";
        obj_game.ui_overlay_open = OV_NONE;
        return;
    }
    if (_btn_click(_cx - _btn_w / 2, _cy - 40 + (_btn_h + _btn_gap), _btn_w, _btn_h)) {
        obj_game.ui_overlay_prev = OV_PAUSE;
        obj_game.ui_overlay_open = OV_SETTINGS;
        return;
    }
    if (_btn_click(_cx - _btn_w / 2, _cy - 40 + (_btn_h + _btn_gap) * 2, _btn_w, _btn_h)) {
        // Quit to Title: reset state + clear all run-scoped UI flags so next run starts clean.
        // Phase 1 Batch 5 (D3 review MEDIUM-4 fix): without these resets, interrupted battle
        // state (select_card_mode, scry, pile_picker, hand selection) could leak into next run.
        obj_game.ui_overlay_open = OV_NONE;
        obj_game.ui_overlay_prev = "";
        obj_game.ui_select_card_mode = false;
        obj_game.ui_select_card_callback = "";
        obj_game.ui_scry_cards = [];
        obj_game.ui_pile_picker_target = "";
        obj_game.player_excluded_pile = [];
        obj_game.selected_card = noone;
        obj_game.wait_timer = 0;
        obj_game.state = "TITLE";
        room_goto(room0);
        return;
    }
}

// ===== 2026-04-26: NEW GAME tutorial-skip confirm overlay =====
function _draw_new_game_confirm_overlay() {
    _draw_full_overlay_bg(0.85);
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;
    var _cy = _h / 2;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_cx, _cy - 130, "NEW GAME", 0.9, 0.9, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_cx, _cy - 70, "Skip tutorial?", 0.45, 0.45, 0);
    draw_text_transformed(_cx, _cy - 40, "(Tutorial = 1 practice battle before run starts)", 0.25, 0.25, 0);

    var _btn_w = 240, _btn_h = 50, _btn_gap = 14;
    _draw_button(_cx - _btn_w / 2, _cy + 10,                              _btn_w, _btn_h, "PLAY TUTORIAL", 0.4);
    _draw_button(_cx - _btn_w / 2, _cy + 10 + (_btn_h + _btn_gap),        _btn_w, _btn_h, "SKIP TUTORIAL", 0.4);
    _draw_button(_cx - _btn_w / 2, _cy + 10 + (_btn_h + _btn_gap) * 2,    _btn_w, _btn_h, "CANCEL",        0.4);
}

function _handle_new_game_confirm_click() {
    if (!mouse_check_button_pressed(mb_left)) return;
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;
    var _cy = _h / 2;
    var _btn_w = 240, _btn_h = 50, _btn_gap = 14;
    var _y_play   = _cy + 10;
    var _y_skip   = _cy + 10 + (_btn_h + _btn_gap);
    var _y_cancel = _cy + 10 + (_btn_h + _btn_gap) * 2;

    if (_btn_click(_cx - _btn_w / 2, _y_play, _btn_w, _btn_h)) {
        global.tutorial_done = false;
        settings_save();
        _new_game_start_fresh();
        return;
    }
    if (_btn_click(_cx - _btn_w / 2, _y_skip, _btn_w, _btn_h)) {
        global.tutorial_done = true;
        settings_save();
        _new_game_start_fresh();
        return;
    }
    if (_btn_click(_cx - _btn_w / 2, _y_cancel, _btn_w, _btn_h)) {
        obj_game.ui_overlay_open = OV_NONE;
        return;
    }
}

/// @desc 2026-04-26: shared "fresh run start" — close overlay, destroy any stale instances,
/// transition to RUN_START with no wait. Used by both PLAY TUTORIAL and SKIP TUTORIAL paths.
function _new_game_start_fresh() {
    _clear_all_card_instances();
    obj_game.ui_overlay_open = OV_NONE;
    obj_game.ui_overlay_prev = "";
    obj_game.ui_select_card_mode = false;
    obj_game.ui_select_card_callback = "";
    obj_game.ui_scry_cards = [];
    obj_game.ui_pile_picker_target = "";
    obj_game.selected_card = noone;
    obj_game.state = "RUN_START";
    obj_game.wait_timer = 0;
}

// ===== Phase 1 Batch 5 (D2): TITLE button click handler =====
// Layout mirrors obj_game/Draw_64.gml TITLE block (SETTINGS + REPLAY TUTORIAL stacked below SPACE prompt).

function _handle_title_click() {
    if (!mouse_check_button_pressed(mb_left)) return;
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;
    var _btn_w = 220, _btn_h = 50, _btn_gap = 16;
    var _btn_y0 = _h / 2 + 60;
    var _y_play     = _btn_y0;
    var _y_settings = _btn_y0 + (_btn_h + _btn_gap);
    var _y_exit     = _btn_y0 + (_btn_h + _btn_gap) * 2;

    if (_btn_click(_cx - _btn_w / 2, _y_play, _btn_w, _btn_h)) {
        obj_game.ui_overlay_open = OV_NEW_GAME_CONFIRM;
        return;
    }
    if (_btn_click(_cx - _btn_w / 2, _y_settings, _btn_w, _btn_h)) {
        obj_game.ui_overlay_open = OV_SETTINGS;
        return;
    }
    if (_btn_click(_cx - _btn_w / 2, _y_exit, _btn_w, _btn_h)) {
        game_end();
        return;
    }
}
