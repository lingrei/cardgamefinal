// Round 3 UI helpers. All draw/interaction functions for obj_game's expanded UI.
// Follows plan conventions: macro-based overlay state, helper-internal draw state management.

// ===== Overlay state macros (prevent string typo) =====
#macro OV_NONE           ""
#macro OV_DECK_PD        "deck_pd"
#macro OV_DECK_PDC       "deck_pdc"
#macro OV_DECK_OD        "deck_od"
#macro OV_DECK_ODC       "deck_odc"
#macro OV_SCRY_TOP_3     "scry_top_3"
#macro OV_PILE_PICKER    "pile_picker"
// Phase 1 Batch 5 (D1/D3): system overlays.
#macro OV_SETTINGS       "settings"
#macro OV_PAUSE          "pause"
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
#macro UI_COLOR_BG          make_colour_rgb(18, 13, 18)      // walnut table base
#macro UI_COLOR_BG_MID      make_colour_rgb(42, 32, 34)      // leather / dark panel
#macro UI_COLOR_PLAYER      make_colour_rgb(72, 201, 214)    // cyan court light
#macro UI_COLOR_OPP         make_colour_rgb(184, 48, 72)     // wax / threat accent
#macro UI_COLOR_HIGHLIGHT   make_colour_rgb(226, 182, 88)    // brass / selected / CTA
#macro UI_COLOR_DIM         make_colour_rgb(90, 90, 90)      // disabled
#macro UI_COLOR_NEUTRAL     make_colour_rgb(200, 200, 200)   // standard text
#macro UI_COLOR_SUCCESS     make_colour_rgb(0, 230, 118)     // heal / buff / victory / draw tag
#macro UI_COLOR_WARNING     make_colour_rgb(255, 152, 0)     // low HP / risk
#macro UI_COLOR_RULE_DECK   make_colour_rgb(156, 39, 176)    // deck-manipulating rules tag
#macro UI_COLOR_PARCHMENT   make_colour_rgb(218, 199, 154)
#macro UI_COLOR_PARCHMENT_D make_colour_rgb(145, 105, 68)
#macro UI_COLOR_INK         make_colour_rgb(38, 29, 33)
#macro UI_COLOR_ROCK_ACCENT     make_colour_rgb(176, 73, 61)
#macro UI_COLOR_SCISSORS_ACCENT make_colour_rgb(70, 150, 190)
#macro UI_COLOR_PAPER_ACCENT    make_colour_rgb(207, 170, 71)
#macro UI_COLOR_TABLE_LINE  make_colour_rgb(92, 67, 58)

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
function _play_battle_sfx(_cue) {
    show_debug_message("[sfx] battle cue=" + string(_cue));
    switch (_cue) {
        case "card_drag_start":    return _play_sfx(snd_card_move);
        case "card_drop_return":   return _play_sfx(snd_card_move);
        case "card_drop_discard":  return _play_sfx(snd_card_move);
        case "card_commit":        return _play_sfx(snd_duel_commit);
        case "card_land_play":     return _play_sfx(snd_card_move);
        case "card_deal":          return _play_sfx(snd_card_deal);
        case "card_flip":          return _play_sfx(snd_card_flip);
        case "match_win":          return _play_sfx(snd_win);
        case "match_lose":         return _play_sfx(snd_lose);
        case "match_tie":          return _play_sfx(snd_tie);
        case "damage_hit":         return _play_sfx(snd_screen_shake);
        case "ko":                 return _play_sfx(snd_ko_kill);
        case "shuffle":            return _play_sfx(snd_card_move);
    }
    return _play_sfx(snd_card_move);
}

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
        case 0: return UI_COLOR_ROCK_ACCENT;
        case 1: return UI_COLOR_SCISSORS_ACCENT;
        case 2: return UI_COLOR_PAPER_ACCENT;
    }
    return c_white;
}

function _card_type_accent(_card_type) {
    if (is_string(_card_type)) _card_type = _str_to_card_type_int(_card_type);
    switch (_card_type) {
        case 0: return UI_COLOR_ROCK_ACCENT;
        case 1: return UI_COLOR_SCISSORS_ACCENT;
        case 2: return UI_COLOR_PAPER_ACCENT;
    }
    return UI_COLOR_NEUTRAL;
}

function _card_type_display_label(_card_type) {
    if (is_string(_card_type)) _card_type = _str_to_card_type_int(_card_type);
    switch (_card_type) {
        case 0: return "ROCK";
        case 1: return "SCISSORS";
        case 2: return "PAPER";
    }
    return "UNKNOWN";
}

function _card_type_sprite(_card_type, _face_up) {
    if (!_face_up) return spr_card_back;
    if (is_string(_card_type)) _card_type = _str_to_card_type_int(_card_type);
    switch (_card_type) {
        case 0: return spr_card_rock;
        case 1: return spr_card_scissors;
        case 2: return spr_card_paper;
    }
    return spr_card_back;
}

function _draw_case_file_lines(_x, _y, _w, _h, _alpha) {
    draw_set_alpha(_alpha);
    draw_set_colour(UI_COLOR_TABLE_LINE);
    for (var _i = 0; _i < 5; _i++) {
        var _yy = _y + (_i + 1) * _h / 6;
        draw_line_width(_x + 18, _yy, _x + _w - 18, _yy + 2 * sin(_i), 1);
    }
    draw_set_alpha(1);
}

function _draw_rps_type_icon(_card_type, _cx, _cy, _size, _alpha) {
    if (is_string(_card_type)) _card_type = _str_to_card_type_int(_card_type);
    var _s = _size;
    var _col = _card_type_accent(_card_type);
    draw_set_alpha(_alpha);

    switch (_card_type) {
        case 0:
            // Rock: sealed stone.
            draw_set_colour(make_colour_rgb(68, 57, 54));
            draw_circle(_cx, _cy + _s * 0.04, _s * 0.30, false);
            draw_circle(_cx - _s * 0.11, _cy - _s * 0.05, _s * 0.20, false);
            draw_circle(_cx + _s * 0.13, _cy - _s * 0.02, _s * 0.22, false);
            draw_set_colour(_col);
            draw_circle(_cx + _s * 0.02, _cy + _s * 0.05, _s * 0.17, false);
            draw_set_colour(UI_COLOR_PARCHMENT);
            draw_line_width(_cx - _s * 0.08, _cy + _s * 0.05, _cx + _s * 0.10, _cy + _s * 0.05, max(1, _s * 0.035));
            draw_line_width(_cx + _s * 0.01, _cy - _s * 0.04, _cx + _s * 0.01, _cy + _s * 0.14, max(1, _s * 0.035));
            break;

        case 1:
            // Scissors: two-finger pointer.
            draw_set_colour(make_colour_rgb(214, 184, 148));
            draw_line_width(_cx - _s * 0.20, _cy + _s * 0.18, _cx + _s * 0.17, _cy - _s * 0.22, max(3, _s * 0.09));
            draw_line_width(_cx - _s * 0.08, _cy + _s * 0.23, _cx + _s * 0.28, _cy - _s * 0.06, max(3, _s * 0.08));
            draw_circle(_cx - _s * 0.18, _cy + _s * 0.20, _s * 0.16, false);
            draw_set_colour(_col);
            draw_rectangle(_cx - _s * 0.39, _cy + _s * 0.22, _cx - _s * 0.04, _cy + _s * 0.38, false);
            draw_set_colour(UI_COLOR_INK);
            draw_line_width(_cx + _s * 0.12, _cy - _s * 0.25, _cx + _s * 0.22, _cy - _s * 0.10, max(1, _s * 0.025));
            break;

        case 2:
            // Paper: parchment sheet.
            draw_set_colour(UI_COLOR_PARCHMENT);
            draw_rectangle(_cx - _s * 0.31, _cy - _s * 0.36, _cx + _s * 0.31, _cy + _s * 0.36, false);
            draw_set_colour(UI_COLOR_PARCHMENT_D);
            draw_rectangle(_cx - _s * 0.31, _cy - _s * 0.36, _cx + _s * 0.31, _cy + _s * 0.36, true);
            draw_set_colour(_col);
            draw_line_width(_cx - _s * 0.20, _cy + _s * 0.18, _cx - _s * 0.06, _cy - _s * 0.07, max(1, _s * 0.035));
            draw_line_width(_cx - _s * 0.06, _cy - _s * 0.07, _cx + _s * 0.18, _cy - _s * 0.20, max(1, _s * 0.035));
            draw_circle(_cx - _s * 0.20, _cy + _s * 0.18, max(2, _s * 0.045), false);
            draw_circle(_cx - _s * 0.06, _cy - _s * 0.07, max(2, _s * 0.045), false);
            draw_circle(_cx + _s * 0.18, _cy - _s * 0.20, max(2, _s * 0.045), false);
            break;

        default:
            draw_set_colour(UI_COLOR_DIM);
            draw_circle(_cx, _cy, _s * 0.25, true);
            break;
    }
    draw_set_alpha(1);
}

function _draw_card_face(_card_type, _x, _y, _w, _h, _rotation, _alpha, _face_up) {
    var _spr = _card_type_sprite(_card_type, _face_up);
    var _sx = _w / max(1, sprite_get_width(_spr));
    var _sy = _h / max(1, sprite_get_height(_spr));
    draw_set_alpha(1);
    draw_sprite_ext(_spr, 0, _x, _y, _sx, _sy, _rotation, c_white, _alpha);
    draw_set_alpha(1);
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

function _draw_text_ext_scaled(_x, _y, _text, _line_px, _width_px, _scale) {
    var _s = max(0.01, _scale);
    draw_text_ext_transformed(_x, _y, _text, _line_px / _s, _width_px / _s, _s, _s, 0);
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

function _effect_color_by_tag(_tag) {
    switch (_tag) {
        case "damage":      return UI_COLOR_OPP;
        case "peek":        return UI_COLOR_RULE_DECK;
        case "matchup":     return UI_COLOR_HIGHLIGHT;
        case "draw":        return UI_COLOR_SUCCESS;
        case "held":        return UI_COLOR_HIGHLIGHT;
        case "same":        return UI_COLOR_HIGHLIGHT;
        case "route":       return UI_COLOR_RULE_DECK;
        case "rps_discard": return UI_COLOR_WARNING;
        default:            return UI_COLOR_NEUTRAL;
    }
}

function _draw_effect_icon(_icon_id, _x, _y, _size, _color) {
    draw_set_alpha(1);
    draw_set_colour(_color);
    draw_circle(_x + _size / 2, _y + _size / 2, _size / 2, false);
    draw_set_colour(UI_COLOR_BG);
    draw_circle(_x + _size / 2, _y + _size / 2, _size / 2 - 2, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    var _label = "?";
    switch (_icon_id) {
        case "target_rock":     _label = "R"; break;
        case "target_paper":    _label = "P"; break;
        case "target_scissors": _label = "S"; break;
        case "impact_plus":     _label = "+"; break;
        case "tie_hit":         _label = "="; break;
        case "double_card":     _label = "2"; break;
        case "return_deck":
        case "return_top":
        case "topdeck":         _label = "^"; break;
        case "eye":
        case "eye_card":
        case "eye_hour":
        case "eye_discard":
        case "observation_mirror":
        case "hand_mirror":     _label = "O"; break;
        case "draw_card":
        case "draw_chain":
        case "hand_plus":
        case "funnel_card":     _label = ">"; break;
        case "hour_plus":       _label = "H"; break;
        case "discard_plus":    _label = "D"; break;
        case "random_stamp":    _label = "*"; break;
        case "prey":
        case "tooth_totem":     _label = "V"; break;
        case "shed":            _label = "/"; break;
        case "same_fuel":       _label = "~"; break;
        case "ember_bowl":      _label = "E"; break;
        case "anchor_stone":    _label = "A"; break;
        case "stamp_press":     _label = "C"; break;
        case "ice_box":         _label = "I"; break;
        case "equal_ring":      _label = "="; break;
        case "tri_compass":     _label = "3"; break;
        case "single_blade":    _label = "1"; break;
        case "half_mask":       _label = "M"; break;
        case "balance_scales":  _label = "B"; break;
        case "backlight_lamp":  _label = "L"; break;
        case "blind_die":       _label = "?"; break;
        case "slow_clock":      _label = "T"; break;
        case "card_spark":      _label = "*"; break;
        case "knot_charm":      _label = "K"; break;
        case "gold_cache":      _label = "G"; break;
        case "random_card":     _label = "C"; break;
        case "choose_upgrade":  _label = "+"; break;
        case "auto_upgrade":    _label = "++"; break;
    }
    _draw_inner_effect_symbol(_icon_id, _x + _size / 2, _y + _size / 2, _size * 0.72, _color);
}

function _draw_inner_effect_symbol(_icon_id, _cx, _cy, _size, _color) {
    var _s = _size;
    draw_set_colour(_color);
    switch (_icon_id) {
        case "target_rock":
            _draw_rps_type_icon(0, _cx, _cy, _s * 0.95, 1);
            break;
        case "target_scissors":
            _draw_rps_type_icon(1, _cx, _cy, _s * 0.95, 1);
            break;
        case "target_paper":
            _draw_rps_type_icon(2, _cx, _cy, _s * 0.95, 1);
            break;

        case "impact_plus":
        case "card_spark":
            draw_line_width(_cx - _s * 0.24, _cy, _cx + _s * 0.24, _cy, max(1, _s * 0.08));
            draw_line_width(_cx, _cy - _s * 0.24, _cx, _cy + _s * 0.24, max(1, _s * 0.08));
            draw_line_width(_cx - _s * 0.17, _cy - _s * 0.17, _cx + _s * 0.17, _cy + _s * 0.17, max(1, _s * 0.035));
            break;

        case "tie_hit":
        case "equal_ring":
        case "balance_scales":
            draw_line_width(_cx - _s * 0.30, _cy - _s * 0.04, _cx + _s * 0.30, _cy - _s * 0.04, max(1, _s * 0.04));
            draw_line_width(_cx, _cy - _s * 0.26, _cx, _cy + _s * 0.26, max(1, _s * 0.04));
            draw_circle(_cx - _s * 0.20, _cy + _s * 0.14, max(2, _s * 0.11), true);
            draw_circle(_cx + _s * 0.20, _cy + _s * 0.14, max(2, _s * 0.11), true);
            break;

        case "double_card":
        case "same_fuel":
            draw_rectangle(_cx - _s * 0.28, _cy - _s * 0.18, _cx + _s * 0.08, _cy + _s * 0.22, true);
            draw_rectangle(_cx - _s * 0.08, _cy - _s * 0.28, _cx + _s * 0.28, _cy + _s * 0.12, true);
            break;

        case "return_deck":
        case "return_top":
        case "topdeck":
            draw_rectangle(_cx - _s * 0.25, _cy + _s * 0.05, _cx + _s * 0.25, _cy + _s * 0.28, true);
            draw_line_width(_cx, _cy + _s * 0.22, _cx, _cy - _s * 0.24, max(1, _s * 0.06));
            draw_line_width(_cx, _cy - _s * 0.24, _cx - _s * 0.15, _cy - _s * 0.08, max(1, _s * 0.06));
            draw_line_width(_cx, _cy - _s * 0.24, _cx + _s * 0.15, _cy - _s * 0.08, max(1, _s * 0.06));
            break;

        case "eye":
        case "eye_card":
        case "eye_hour":
        case "eye_discard":
        case "observation_mirror":
        case "hand_mirror":
        case "backlight_lamp":
            draw_line_width(_cx - _s * 0.32, _cy, _cx - _s * 0.12, _cy - _s * 0.14, max(1, _s * 0.04));
            draw_line_width(_cx - _s * 0.12, _cy - _s * 0.14, _cx + _s * 0.12, _cy - _s * 0.14, max(1, _s * 0.04));
            draw_line_width(_cx + _s * 0.12, _cy - _s * 0.14, _cx + _s * 0.32, _cy, max(1, _s * 0.04));
            draw_line_width(_cx - _s * 0.32, _cy, _cx - _s * 0.12, _cy + _s * 0.14, max(1, _s * 0.04));
            draw_line_width(_cx - _s * 0.12, _cy + _s * 0.14, _cx + _s * 0.12, _cy + _s * 0.14, max(1, _s * 0.04));
            draw_line_width(_cx + _s * 0.12, _cy + _s * 0.14, _cx + _s * 0.32, _cy, max(1, _s * 0.04));
            draw_circle(_cx, _cy, max(2, _s * 0.09), false);
            break;

        case "draw_card":
        case "draw_chain":
        case "hand_plus":
        case "funnel_card":
            draw_rectangle(_cx - _s * 0.27, _cy - _s * 0.23, _cx + _s * 0.08, _cy + _s * 0.25, true);
            draw_line_width(_cx + _s * 0.02, _cy, _cx + _s * 0.30, _cy, max(1, _s * 0.06));
            draw_line_width(_cx + _s * 0.30, _cy, _cx + _s * 0.18, _cy - _s * 0.11, max(1, _s * 0.06));
            draw_line_width(_cx + _s * 0.30, _cy, _cx + _s * 0.18, _cy + _s * 0.11, max(1, _s * 0.06));
            break;

        case "hour_plus":
        case "slow_clock":
            draw_circle(_cx, _cy, _s * 0.28, true);
            draw_line_width(_cx, _cy, _cx, _cy - _s * 0.18, max(1, _s * 0.04));
            draw_line_width(_cx, _cy, _cx + _s * 0.13, _cy + _s * 0.07, max(1, _s * 0.04));
            break;

        case "discard_plus":
        case "shed":
            draw_line_width(_cx - _s * 0.24, _cy + _s * 0.24, _cx + _s * 0.24, _cy - _s * 0.24, max(1, _s * 0.07));
            draw_line_width(_cx + _s * 0.02, _cy + _s * 0.18, _cx + _s * 0.24, _cy + _s * 0.18, max(1, _s * 0.045));
            draw_line_width(_cx + _s * 0.13, _cy + _s * 0.07, _cx + _s * 0.13, _cy + _s * 0.29, max(1, _s * 0.045));
            break;

        case "random_stamp":
            for (var _i = 0; _i < 6; _i++) {
                var _a = _i * 60;
                draw_line_width(_cx, _cy, _cx + lengthdir_x(_s * 0.30, _a), _cy + lengthdir_y(_s * 0.30, _a), max(1, _s * 0.035));
            }
            break;

        case "prey":
        case "tooth_totem":
            draw_triangle(_cx, _cy - _s * 0.30, _cx - _s * 0.20, _cy + _s * 0.25, _cx + _s * 0.20, _cy + _s * 0.25, false);
            break;

        case "ember_bowl":
            draw_line_width(_cx - _s * 0.25, _cy + _s * 0.14, _cx + _s * 0.25, _cy + _s * 0.14, max(1, _s * 0.07));
            draw_line_width(_cx - _s * 0.17, _cy + _s * 0.14, _cx, _cy + _s * 0.28, max(1, _s * 0.04));
            draw_line_width(_cx + _s * 0.17, _cy + _s * 0.14, _cx, _cy + _s * 0.28, max(1, _s * 0.04));
            draw_line_width(_cx, _cy - _s * 0.27, _cx - _s * 0.08, _cy + _s * 0.06, max(1, _s * 0.08));
            draw_line_width(_cx, _cy - _s * 0.27, _cx + _s * 0.10, _cy + _s * 0.06, max(1, _s * 0.05));
            break;

        case "anchor_stone":
        case "ice_box":
            draw_rectangle(_cx - _s * 0.25, _cy - _s * 0.18, _cx + _s * 0.25, _cy + _s * 0.20, true);
            draw_line_width(_cx - _s * 0.14, _cy - _s * 0.02, _cx + _s * 0.14, _cy - _s * 0.02, max(1, _s * 0.04));
            break;

        case "stamp_press":
            draw_rectangle(_cx - _s * 0.18, _cy - _s * 0.28, _cx + _s * 0.18, _cy + _s * 0.10, true);
            draw_line_width(_cx - _s * 0.30, _cy + _s * 0.18, _cx + _s * 0.30, _cy + _s * 0.18, max(1, _s * 0.07));
            break;

        case "tri_compass":
            draw_circle(_cx, _cy, _s * 0.31, true);
            draw_line_width(_cx, _cy - _s * 0.25, _cx - _s * 0.22, _cy + _s * 0.17, max(1, _s * 0.035));
            draw_line_width(_cx - _s * 0.22, _cy + _s * 0.17, _cx + _s * 0.22, _cy + _s * 0.17, max(1, _s * 0.035));
            draw_line_width(_cx + _s * 0.22, _cy + _s * 0.17, _cx, _cy - _s * 0.25, max(1, _s * 0.035));
            break;

        case "single_blade":
            draw_line_width(_cx - _s * 0.20, _cy + _s * 0.25, _cx + _s * 0.24, _cy - _s * 0.25, max(2, _s * 0.08));
            draw_line_width(_cx - _s * 0.24, _cy + _s * 0.20, _cx - _s * 0.04, _cy + _s * 0.36, max(1, _s * 0.05));
            break;

        case "half_mask":
            draw_circle(_cx - _s * 0.07, _cy, _s * 0.26, true);
            draw_line_width(_cx, _cy - _s * 0.25, _cx, _cy + _s * 0.25, max(1, _s * 0.04));
            draw_circle(_cx - _s * 0.14, _cy - _s * 0.04, max(1, _s * 0.04), false);
            break;

        case "blind_die":
            draw_rectangle(_cx - _s * 0.24, _cy - _s * 0.24, _cx + _s * 0.24, _cy + _s * 0.24, true);
            draw_circle(_cx, _cy, max(2, _s * 0.055), false);
            draw_circle(_cx - _s * 0.13, _cy - _s * 0.13, max(2, _s * 0.045), false);
            draw_circle(_cx + _s * 0.13, _cy + _s * 0.13, max(2, _s * 0.045), false);
            break;

        case "knot_charm":
            draw_circle(_cx - _s * 0.11, _cy, _s * 0.15, true);
            draw_circle(_cx + _s * 0.11, _cy, _s * 0.15, true);
            draw_line_width(_cx - _s * 0.25, _cy + _s * 0.22, _cx + _s * 0.25, _cy - _s * 0.22, max(1, _s * 0.04));
            break;

        case "gold_cache":
            draw_circle(_cx - _s * 0.10, _cy + _s * 0.08, _s * 0.16, true);
            draw_circle(_cx + _s * 0.08, _cy - _s * 0.04, _s * 0.16, true);
            draw_line_width(_cx - _s * 0.18, _cy + _s * 0.25, _cx + _s * 0.24, _cy + _s * 0.25, max(1, _s * 0.05));
            break;
        case "random_card":
            draw_rectangle(_cx - _s * 0.21, _cy - _s * 0.28, _cx + _s * 0.21, _cy + _s * 0.28, true);
            draw_line_width(_cx - _s * 0.12, _cy, _cx + _s * 0.12, _cy, max(1, _s * 0.05));
            break;
        case "choose_upgrade":
        case "auto_upgrade":
            draw_line_width(_cx - _s * 0.26, _cy, _cx + _s * 0.26, _cy, max(1, _s * 0.07));
            draw_line_width(_cx, _cy - _s * 0.26, _cx, _cy + _s * 0.26, max(1, _s * 0.07));
            draw_circle(_cx, _cy, _s * 0.31, true);
            break;

        default:
            draw_circle(_cx, _cy, _s * 0.22, true);
            draw_line_width(_cx - _s * 0.18, _cy, _cx + _s * 0.18, _cy, max(1, _s * 0.04));
            break;
    }
}

function _draw_trait_mark(_rule, _x, _y, _size) {
    var _rule_obj = is_string(_rule) ? _get_rule_template_by_id(_rule) : _rule;
    var _meta = _rule_ui_meta(_rule);
    var _col = _effect_color_by_tag(_meta.tag);
    var _cx = _x + _size / 2;
    var _cy = _y + _size / 2;
    var _trigger = is_undefined(_rule_obj) ? "" : (_rule_obj[$ "trigger"] ?? "");

    draw_set_alpha(1);
    switch (_trigger) {
        case "on_play":
            draw_set_colour(_col);
            draw_circle(_cx, _cy, _size * 0.48, false);
            draw_set_colour(UI_COLOR_INK);
            draw_circle(_cx, _cy, _size * 0.31, true);
            break;
        case "on_active_discard":
        case "held_on_owner_active_discard":
        case "on_any_active_discard":
            draw_set_colour(_col);
            draw_rectangle(_x, _y + _size * 0.12, _x + _size, _y + _size * 0.88, false);
            draw_set_colour(UI_COLOR_BG);
            draw_triangle(_x + _size * 0.72, _y + _size * 0.12, _x + _size, _y + _size * 0.12, _x + _size, _y + _size * 0.42, false);
            draw_set_colour(UI_COLOR_INK);
            draw_rectangle(_x + 2, _y + _size * 0.16, _x + _size - 2, _y + _size * 0.84, true);
            break;
        case "on_draw":
            draw_set_colour(_col);
            draw_rectangle(_x + _size * 0.10, _y + _size * 0.22, _x + _size * 0.90, _y + _size * 0.86, false);
            draw_rectangle(_x + _size * 0.52, _y + _size * 0.08, _x + _size * 0.88, _y + _size * 0.28, false);
            draw_set_colour(UI_COLOR_INK);
            draw_rectangle(_x + _size * 0.13, _y + _size * 0.25, _x + _size * 0.87, _y + _size * 0.83, true);
            break;
        case "while_held_turn_start":
        case "held_passive":
            draw_set_colour(_col);
            draw_circle(_cx, _cy, _size * 0.44, true);
            draw_circle(_cx, _cy, _size * 0.28, true);
            draw_line_width(_cx + _size * 0.18, _cy - _size * 0.34, _cx + _size * 0.18, _cy + _size * 0.32, max(1, _size * 0.08));
            break;
        case "on_win":
            draw_set_colour(_col);
            draw_circle(_cx, _cy, _size * 0.45, false);
            draw_set_colour(UI_COLOR_BG);
            draw_line_width(_cx - _size * 0.18, _cy - _size * 0.18, _cx + _size * 0.18, _cy + _size * 0.18, max(1, _size * 0.05));
            break;
        case "on_tie":
        case "judge":
            draw_set_colour(_col);
            draw_rectangle(_x + _size * 0.08, _y + _size * 0.12, _x + _size * 0.92, _y + _size * 0.88, false);
            draw_set_colour(UI_COLOR_INK);
            draw_rectangle(_x + _size * 0.13, _y + _size * 0.17, _x + _size * 0.87, _y + _size * 0.83, true);
            break;
        case "on_played":
            draw_set_colour(_col);
            draw_rectangle(_x + _size * 0.08, _y + _size * 0.20, _x + _size * 0.92, _y + _size * 0.84, false);
            draw_set_colour(UI_COLOR_INK);
            draw_rectangle(_x + _size * 0.12, _y + _size * 0.24, _x + _size * 0.88, _y + _size * 0.80, true);
            break;
        default:
            draw_set_colour(_col);
            draw_circle(_cx, _cy, _size * 0.46, false);
            draw_set_colour(UI_COLOR_INK);
            draw_circle(_cx, _cy, _size * 0.32, true);
            break;
    }

    _draw_inner_effect_symbol(_meta.icon_id, _cx, _cy, _size * 0.62, UI_COLOR_PARCHMENT);
    draw_set_alpha(1);
}

function _draw_relic_object_token(_icon_id, _x, _y, _size, _pulse) {
    var _cx = _x + _size / 2;
    var _cy = _y + _size / 2;
    var _col = _pulse ? UI_COLOR_HIGHLIGHT : UI_COLOR_PARCHMENT_D;
    draw_set_alpha(1);
    draw_set_colour(make_colour_rgb(31, 23, 25));
    draw_circle(_cx, _cy, _size * 0.50, false);
    draw_set_colour(_pulse ? UI_COLOR_HIGHLIGHT : UI_COLOR_TABLE_LINE);
    draw_circle(_cx, _cy, _size * 0.48, true);
    draw_circle(_cx, _cy, _size * 0.42, true);
    _draw_inner_effect_symbol(_icon_id, _cx, _cy, _size * 0.86, _col);
}

function _draw_rule_chip(_rule, _x, _y, _size) {
    _draw_trait_mark(_rule, _x, _y, _size);
}

function _rule_tag_label(_tag) {
    switch (_tag) {
        case "damage":      return "DAMAGE";
        case "peek":        return "INFO";
        case "matchup":     return "MATCHUP";
        case "draw":        return "DRAW";
        case "held":        return "HELD";
        case "same":        return "SAME";
        case "route":       return "ROUTE";
        case "rps_discard": return "DISCARD";
    }
    return "TRAIT";
}

function _draw_rule_info_card(_rule, _x, _y, _w, _h, _selected) {
    var _meta = _rule_ui_meta(_rule);
    var _col = _effect_color_by_tag(_meta.tag);
    var _hover = point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h);

    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(_selected ? UI_COLOR_HIGHLIGHT : (_hover ? UI_COLOR_PLAYER : UI_COLOR_NEUTRAL));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    if (_selected || _hover) {
        draw_rectangle(_x + 1, _y + 1, _x + _w - 1, _y + _h - 1, true);
    }

    _draw_rule_chip(_rule, _x + 16, _y + 16, 34);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(_col);
    draw_text_transformed(_x + 60, _y + 14, _rule_tag_label(_meta.tag), 0.16, 0.16, 0);

    draw_set_colour(c_white);
    draw_text_transformed(_x + 60, _y + 35, _t(_meta.display_text), 0.22, 0.22, 0);

    draw_set_colour(UI_COLOR_NEUTRAL);
    _draw_text_ext_scaled(_x + 16, _y + 72, _t(_meta.description_text), 17, _w - 32, 0.18);

    if (variable_struct_exists(_rule, "cost") && _rule.cost > 0) {
        draw_set_halign(fa_right);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_x + _w - 14, _y + 14, string(_rule.cost) + "G", 0.28, 0.28, 0);
    }
}

function _draw_rule_hover_tooltip(_rule, _x, _y) {
    var _meta = _rule_ui_meta(_rule);
    var _w = 360;
    var _h = 112;
    if (_x + _w > display_get_gui_width()) _x = display_get_gui_width() - _w - 8;
    if (_y + _h > display_get_gui_height()) _y = display_get_gui_height() - _h - 8;
    if (_x < 8) _x = 8;
    if (_y < 8) _y = 8;

    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1);
    draw_set_colour(_effect_color_by_tag(_meta.tag));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    _draw_rule_chip(_rule, _x + 10, _y + 12, 30);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_text_transformed(_x + 50, _y + 10, _t(_meta.display_text), 0.26, 0.26, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_x + 50, _y + 36, _rule_tag_label(_meta.tag), 0.16, 0.16, 0);
    draw_set_colour(c_white);
    _draw_text_ext_scaled(_x + 12, _y + 62, _t(_meta.description_text), 19, _w - 24, 0.20);
}

function _draw_card_struct_tooltip(_card, _x, _y) {
    var _rules = _card.rules;
    if (!is_array(_rules)) _rules = [];
    var _w = 330;
    var _h = 74 + array_length(_rules) * 30;
    if (_x + _w > display_get_gui_width()) _x = display_get_gui_width() - _w - 8;
    if (_y + _h > display_get_gui_height()) _y = display_get_gui_height() - _h - 8;
    if (_x < 8) _x = 8;
    if (_y < 8) _y = 8;

    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_PLAYER);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(c_white);
    draw_text_transformed(_x + 12, _y + 10, _card_type_display_label(_card.type_name), 0.28, 0.28, 0);

    if (array_length(_rules) == 0) {
        draw_set_colour(UI_COLOR_DIM);
        draw_text_transformed(_x + 12, _y + 42, "No added traits", 0.20, 0.20, 0);
        return;
    }

    var _yy = _y + 42;
    for (var i = 0; i < array_length(_rules); i++) {
        var _r = _rules[i];
        _draw_rule_chip(_r, _x + 12, _yy, 22);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_x + 42, _yy - 2, _t(_rule_display_key(_r.id)), 0.20, 0.20, 0);
        draw_set_colour(UI_COLOR_NEUTRAL);
        _draw_text_ext_scaled(_x + 42, _yy + 14, _t(_r.description_text), 16, _w - 54, 0.16);
        _yy += 30;
    }
}

function _draw_relic_token(_relic, _x, _y, _size) {
    var _pulse = (_relic[$ "pulse_timer"] ?? 0) > 0;
    var _s = _pulse ? (_size + 4 + 2 * sin(current_time / 80)) : _size;
    var _meta = _relic_ui_meta(_relic);
    _draw_relic_object_token(_meta.icon_id, _x - (_s - _size) / 2, _y - (_s - _size) / 2, _s, _pulse);
}

function _draw_relic_card(_relic, _x, _y, _w, _h, _selected) {
    var _hover = point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(_selected ? UI_COLOR_HIGHLIGHT : (_hover ? UI_COLOR_PLAYER : UI_COLOR_NEUTRAL));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    _draw_relic_token(_relic, _x + 16, _y + 18, 44);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(c_white);
    draw_text_transformed(_x + 72, _y + 16, _t(_relic.display_text), 0.3, 0.3, 0);
    draw_set_colour(UI_COLOR_NEUTRAL);
    _draw_text_ext_scaled(_x + 72, _y + 48, _t(_relic.description_text), 19, _w - 88, 0.22);
}

function _draw_relic_shelf(_x, _y) {
    var _relics = obj_game.relics;
    var _max_show = min(5, array_length(_relics));
    var _hovered = -1;
    draw_set_alpha(0.85);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x - 8, _y - 18, _x + 228, _y + 40, false);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_score);
    draw_set_colour(array_length(_relics) > 0 ? UI_COLOR_HIGHLIGHT : UI_COLOR_DIM);
    draw_text_transformed(_x - 4, _y - 8, "RELICS", 0.16, 0.16, 0);

    if (array_length(_relics) == 0) {
        draw_set_colour(UI_COLOR_DIM);
        draw_rectangle(_x, _y + 6, _x + 32, _y + 38, true);
        draw_text_transformed(_x + 42, _y + 22, "none", 0.18, 0.18, 0);
        return;
    }

    for (var i = 0; i < _max_show; i++) {
        var _tx = _x + i * 42;
        _draw_relic_token(_relics[i], _tx, _y + 6, 32);
        if (point_in_rectangle(mouse_x, mouse_y, _tx, _y + 6, _tx + 32, _y + 38)) _hovered = i;
    }
    if (array_length(_relics) > 5) {
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_x + 5 * 42, _y + 22, "+" + string(array_length(_relics) - 5), 0.28, 0.28, 0);
    }
    if (_hovered >= 0) {
        _draw_relic_hover_tooltip(_relics[_hovered], mouse_x + 16, mouse_y + 16);
    }
}

function _draw_relic_hover_tooltip(_relic, _x, _y) {
    var _w = 330;
    var _h = 86;
    if (_x + _w > display_get_gui_width()) _x = display_get_gui_width() - _w - 8;
    if (_y + _h > display_get_gui_height()) _y = display_get_gui_height() - _h - 8;
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_alpha(1);
    _draw_relic_token(_relic, _x + 8, _y + 10, 32);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_text_transformed(_x + 50, _y + 8, _t(_relic.display_text), 0.28, 0.28, 0);
    draw_set_colour(c_white);
    _draw_text_ext_scaled(_x + 50, _y + 34, _t(_relic.description_text), 19, _w - 60, 0.22);
}

function _get_rule_color(_rule) {
    var _tag = _rule[$ "tag"] ?? "";
    return _effect_color_by_tag(_tag);
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

function _get_next_or_current_stage() {
    var _map = obj_game.map;
    var _start = obj_game.map_position;
    for (var i = _start; i < array_length(_map); i++) {
        if (_map[i].type == "battle") {
            var _stage_id = _map[i].payload[$ "stage_id"] ?? "stage_1";
            return _get_stage_by_id(_stage_id);
        }
    }
    return _get_stage_by_id("stage_1");
}

function _enemy_ai_summary(_enemy) {
    if (is_undefined(_enemy)) return "Unknown AI.";
    var _ai = _enemy.ai_params[$ "type"] ?? "";
    switch (_ai) {
        case "stage1_f": return "Learns your last winning type.";
        case "stage3_rock": return "Prefers Rock when available.";
        case "stage4_paper_hoarder": return "Keeps Paper, discards non-Paper.";
        case "fixed_first": return "Plays the first available card.";
    }
    return "Deterministic enemy plan.";
}

function _stage_mechanic_summary(_stage) {
    if (is_undefined(_stage)) return "";
    var _parts = [];
    if (variable_struct_exists(_stage, "mechanics")) {
        var _m = _stage.mechanics;
        if (variable_struct_exists(_m, "hand_limit_delta_both") && _m.hand_limit_delta_both != 0) {
            array_push(_parts, "Both hands " + ((_m.hand_limit_delta_both > 0) ? "+" : "") + string(_m.hand_limit_delta_both));
        }
    }
    if (array_length(_parts) == 0) return "";
    var _out = _parts[0];
    for (var i = 1; i < array_length(_parts); i++) _out += " / " + _parts[i];
    return _out;
}

function _enemy_deck_line(_enemy, _type_name) {
    var _comp = _enemy.deck_composition;
    var _count = _comp[$ _type_name] ?? 0;
    var _label = string_upper(string_copy(_type_name, 1, 1)) + " x" + string(_count);
    var _rules = _enemy_rules_for_type(_enemy, _type_name);
    if (array_length(_rules) == 0) return _label + ": no traits";

    var _names = "";
    for (var i = 0; i < array_length(_rules); i++) {
        if (i > 0) _names += ", ";
        _names += _t(_rule_display_key(_rules[i].id));
    }
    return _label + ": " + _names;
}

function _draw_enemy_briefing_panel(_x, _y, _w, _h, _stage, _enemy) {
    if (is_undefined(_stage) || is_undefined(_enemy)) return;

    var _mechanic = _stage_mechanic_summary(_stage);

    draw_set_alpha(0.96);
    draw_set_colour(UI_COLOR_PARCHMENT);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_PARCHMENT_D);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    draw_set_font(fnt_score);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(UI_COLOR_INK);
    draw_text_transformed(_x + 24, _y + 20, "Battle", 0.48, 0.48, 0);
    draw_set_colour(UI_COLOR_OPP);
    draw_text_transformed(_x + 24, _y + 70, "Enemy HP " + string(_enemy.max_hp), 0.30, 0.30, 0);

    var _line_y = _y + 112;
    if (_mechanic != "") {
        draw_set_colour(UI_COLOR_PLAYER);
        draw_text_transformed(_x + 24, _line_y, "Mechanic", 0.26, 0.26, 0);
        draw_set_colour(UI_COLOR_INK);
        _draw_text_ext_scaled(_x + 24, _line_y + 30, _mechanic, 18, _w - 48, 0.23);
        _line_y += 78;
    }

    draw_set_colour(UI_COLOR_PLAYER);
    draw_text_transformed(_x + 24, _line_y, "Deck", 0.28, 0.28, 0);
    draw_set_colour(UI_COLOR_INK);
    _draw_text_ext_scaled(_x + 24, _line_y + 34, _enemy_deck_line(_enemy, "rock"), 18, _w - 48, 0.22);
    _draw_text_ext_scaled(_x + 24, _line_y + 72, _enemy_deck_line(_enemy, "scissors"), 18, _w - 48, 0.22);
    _draw_text_ext_scaled(_x + 24, _line_y + 110, _enemy_deck_line(_enemy, "paper"), 18, _w - 48, 0.22);
}

function _draw_enemy_battle_strip() {
    if (obj_game.current_enemy_id == "") return;
    var _stage = _get_stage_by_id(obj_game.current_stage_id);
    if (is_undefined(_stage)) return;

    var _mechanic = _stage_mechanic_summary(_stage);
    if (_mechanic == "") return;

    var _x = 294;
    var _y = 18;
    var _w = 360;
    var _h = 30;
    draw_set_alpha(0.82);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(UI_COLOR_NEUTRAL);
    draw_text_transformed(_x + 10, _y + 7, "Mechanic", 0.18, 0.18, 0);
    draw_set_colour(c_white);
    draw_text_transformed(_x + 96, _y + 7, _mechanic, 0.18, 0.18, 0);
    draw_set_alpha(1);
}

function _ui_set_duel_result(_text) {
    obj_game.ui_duel_result_text = _text;
    obj_game.ui_duel_result_timer = obj_game.ui_duel_result_max_timer;
}

function _ui_add_damage_feedback(_owner, _amount, _delay) {
    if (_amount <= 0) return;
    if (is_undefined(_delay)) _delay = 0;
    array_push(obj_game.ui_damage_events, {
        owner: _owner,
        amount: _amount,
        delay: max(0, _delay),
        timer: 44,
        max_timer: 44
    });
}

function _queue_side_hit_feedback(_owner, _color, _delay) {
    if (is_undefined(_delay)) _delay = 0;
    if (_owner == "opp") {
        obj_game.ui_hit_flash_opp_color = _color;
        obj_game.ui_hit_flash_opp_delay = max(0, _delay);
        if (_delay <= 0) {
            obj_game.ui_hit_flash_opp_timer = 25;
            obj_game.ui_screen_shake_timer = max(obj_game.ui_screen_shake_timer, 20);
        }
    } else if (_owner == "player") {
        obj_game.ui_hit_flash_player_color = _color;
        obj_game.ui_hit_flash_player_delay = max(0, _delay);
        if (_delay <= 0) {
            obj_game.ui_hit_flash_player_timer = 25;
            obj_game.ui_screen_shake_timer = max(obj_game.ui_screen_shake_timer, 20);
        }
    }
}

function _draw_duel_feedback() {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    var _cx = _w / 2;

    if (obj_game.ui_duel_result_timer > 0 && obj_game.ui_duel_result_text != "") {
        var _life = obj_game.ui_duel_result_timer / max(1, obj_game.ui_duel_result_max_timer);
        var _alpha = (_life > 0.34) ? 1 : clamp(_life / 0.34, 0, 1);
        var _scale = 1.20 + (1 - _life) * 0.12;
        var _col = UI_COLOR_NEUTRAL;
        if (obj_game.ui_duel_result_text == "WIN") _col = UI_COLOR_SUCCESS;
        else if (obj_game.ui_duel_result_text == "LOSE") _col = UI_COLOR_OPP;

        draw_set_alpha(_alpha);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_font(fnt_score);
        draw_set_colour(UI_COLOR_BG);
        draw_text_transformed(_cx + 4, _h * 0.47 + 4, obj_game.ui_duel_result_text, _scale, _scale, 0);
        draw_set_colour(_col);
        draw_text_transformed(_cx, _h * 0.47, obj_game.ui_duel_result_text, _scale, _scale, 0);
        draw_set_alpha(1);
    }

    for (var i = 0; i < array_length(obj_game.ui_damage_events); i++) {
        var _ev = obj_game.ui_damage_events[i];
        if (_ev.delay > 0) continue;
        var _t = _ev.timer / max(1, _ev.max_timer);
        var _progress = 1 - _t;
        var _target_y = (_ev.owner == "opp") ? _h * 0.30 : _h * 0.68;
        var _start_offset = (_ev.owner == "opp") ? -46 : 46;
        var _y = _target_y + _start_offset * _t;
        var _scale_d = 0.82 + 0.22 * sin(_progress * 3.14159);
        var _text = "-" + string(_ev.amount);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_font(fnt_score);
        draw_set_alpha(clamp(0.42 + _t * 0.75, 0, 1));
        draw_set_colour(UI_COLOR_BG);
        draw_text_transformed(_cx + 3, _y + 3, _text, _scale_d, _scale_d, 0);
        draw_set_colour(make_colour_rgb(255, 70, 110));
        draw_text_transformed(_cx, _y, _text, _scale_d, _scale_d, 0);
    }
    draw_set_alpha(1);
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
    var _cy = display_get_gui_height()/2;
    var _btn_w = (obj_game.state == "RUN_CONTENT_WIP") ? 240 : 200;
    var _btn_y = (obj_game.state == "RUN_CONTENT_WIP") ? (_cy + 96) : (_cy + 80);
    if (_btn_click(_cx - _btn_w / 2, _btn_y, _btn_w, 50)) {
        game_restart();
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
    // Excluded: TITLE / RUN_VICTORY / RUN_DEFEAT / RUN_CONTENT_WIP (already menu-state, no pause needed).
    if (keyboard_check_pressed(vk_escape)
        && obj_game.state != "TITLE"
        && obj_game.state != "RUN_VICTORY"
        && obj_game.state != "RUN_DEFEAT"
        && obj_game.state != "RUN_CONTENT_WIP") {
        obj_game.ui_overlay_open = OV_PAUSE;
        return;
    }
    // Phase 1 Batch 5 (D2): TITLE button clicks.
    if (obj_game.state == "TITLE") {
        _handle_title_click();
    }
    // 2026-04-26: replaced 4 corner buttons with 4 pile-region click. Active during PLAYER_WAIT only
    // (consistent with item bar gating — avoids clicks during DEAL/SHUFFLE/DISCARD).
    if (obj_game.state == "PLAYER_WAIT") {
        _handle_pile_click_regions();
    }
    // Phase 1 Batch 6 (F3) cleanup: stale comment block removed. Old Round 3 overlay click
    // handlers (_handle_branch_click / _handle_shop_click / etc) are gone — fully deleted in
    // Phase 2e.4 when the 6 obj_*_mgr subclasses owned their own UI per D56 architecture.
    switch (obj_game.state) {
        case "RUN_VICTORY":
        case "RUN_DEFEAT":
        case "RUN_CONTENT_WIP":     _handle_run_end_click();  break;
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
function _discard_btn_rect() {
    return {
        x: 1038,
        y: 430,
        w: 84,
        h: 34
    };
}

function _handle_discard_mode_click() {
    var _r = _discard_btn_rect();
    if (_click_in_rect(_r.x, _r.y, _r.w, _r.h)) {
        obj_game.ui_active_discard_mode = !obj_game.ui_active_discard_mode;
        obj_game.selected_card = noone;
        _play_battle_sfx("card_drag_start");
    }
}

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
        } else if (obj_game.state == "RUN_VICTORY" || obj_game.state == "RUN_DEFEAT" || obj_game.state == "RUN_CONTENT_WIP") {
            _play_bgm(bgm_run_end_win);
        }
    }

    obj_game.ui_player_hp_display = lerp(obj_game.ui_player_hp_display, obj_game.player_hp, 0.2);
    obj_game.ui_opp_hp_display    = lerp(obj_game.ui_opp_hp_display,    obj_game.opp_hp,    0.2);
    if (obj_game.ui_hp_flash_timer > 0) obj_game.ui_hp_flash_timer--;
    if (obj_game.ui_hp_flash_player_timer > 0) obj_game.ui_hp_flash_player_timer--;
    if (obj_game.ui_hp_flash_opp_timer > 0) obj_game.ui_hp_flash_opp_timer--;
    // Phase 1 Batch 2 (C2): hit FX timers tick (decay screen shake + hit flash vignette)
    if (obj_game.ui_screen_shake_timer > 0) obj_game.ui_screen_shake_timer--;
    if (obj_game.ui_hit_flash_timer > 0) obj_game.ui_hit_flash_timer--;
    if (obj_game.ui_hit_flash_opp_delay > 0) {
        obj_game.ui_hit_flash_opp_delay--;
        if (obj_game.ui_hit_flash_opp_delay <= 0) {
            obj_game.ui_hit_flash_opp_timer = 25;
            obj_game.ui_screen_shake_timer = max(obj_game.ui_screen_shake_timer, 20);
        }
    } else if (obj_game.ui_hit_flash_opp_timer > 0) {
        obj_game.ui_hit_flash_opp_timer--;
    }
    if (obj_game.ui_hit_flash_player_delay > 0) {
        obj_game.ui_hit_flash_player_delay--;
        if (obj_game.ui_hit_flash_player_delay <= 0) {
            obj_game.ui_hit_flash_player_timer = 25;
            obj_game.ui_screen_shake_timer = max(obj_game.ui_screen_shake_timer, 20);
        }
    } else if (obj_game.ui_hit_flash_player_timer > 0) {
        obj_game.ui_hit_flash_player_timer--;
    }
    if (obj_game.ui_duel_result_timer > 0) obj_game.ui_duel_result_timer--;
    if (array_length(obj_game.ui_damage_events) > 0) {
        var _damage_next = [];
        for (var _di = 0; _di < array_length(obj_game.ui_damage_events); _di++) {
            var _ev = obj_game.ui_damage_events[_di];
            if (_ev.delay > 0) _ev.delay--;
            else _ev.timer--;
            if (_ev.delay > 0 || _ev.timer > 0) array_push(_damage_next, _ev);
        }
        obj_game.ui_damage_events = _damage_next;
    }
    _relic_tick_ui();
    with (obj_card) {
        if (ui_pulse_timer > 0) ui_pulse_timer--;
    }
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
/// Draws: dark BG fill + top HUD (HP / Gold / Relics / Battle counter) via obj_game data.
function _draw_room_bg_and_status() {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();

    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_BG);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(0.18);
    draw_set_colour(UI_COLOR_TABLE_LINE);
    for (var _grain = 0; _grain < 8; _grain++) {
        var _gy = 84 + _grain * 78;
        draw_line_width(0, _gy, _w, _gy + 10 * sin(_grain), 1);
    }
    draw_set_alpha(1);

    draw_set_font(fnt_score);
    if (instance_exists(obj_game)) {
        draw_set_alpha(0.72);
        draw_set_colour(UI_COLOR_BG_MID);
        draw_rectangle(0, 0, _w, 58, false);
        draw_set_alpha(1);

        draw_set_colour(UI_COLOR_NEUTRAL);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var _status_text = "HP " + string(obj_game.player_hp) + "/" + string(obj_game.player_max_hp)
            + "   Gold " + string(obj_game.gold)
            + "   Deck " + string(array_length(obj_game.player_deck));
        draw_text_transformed(18, 15, _status_text, 0.26, 0.26, 0);

        draw_set_halign(fa_right);
        draw_set_colour(UI_COLOR_DIM);
        draw_text_transformed(_w - 270, 15, "Battle " + string(obj_game.current_battle_index + 1) + "/" + string(_run_battle_total()), 0.26, 0.26, 0);

        _draw_relic_shelf(_w - 238, 18);
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
    if (obj_game.state == "TITLE" || obj_game.state == "RUN_VICTORY" || obj_game.state == "RUN_DEFEAT" || obj_game.state == "RUN_CONTENT_WIP") return;
    // 2026-04-26 v3: active count fan (n=2 redistributes to 2-card spread, no mid-gap).
    var _active = [];
    for (var _oi = 0; _oi < obj_game.opp_hand_limit; _oi++) {
        if (obj_game.opp_hand[_oi] != noone && instance_exists(obj_game.opp_hand[_oi])) array_push(_active, obj_game.opp_hand[_oi]);
    }
    var _n = array_length(_active);
    for (var _k = 0; _k < _n; _k++) {
        var _card = _active[_k];
        var _angle_deg;
        if (_n == 1) _angle_deg = 0;
        else _angle_deg = (_k - (_n - 1) / 2) * obj_game.HAND_FAN_ANGLE_DEG;
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
    for (var _oi = 0; _oi < obj_game.player_hand_limit; _oi++) {
        var _hc = obj_game.plr_hand[_oi];
        if (_hc == noone) continue;
        if (!instance_exists(_hc)) continue;
        if (_hc == obj_game.selected_card) continue;
        if (_hc == obj_game.ui_drag_card) continue;
        array_push(_active, _hc);
        array_push(_active_to_orig, _oi);
    }
    var _n = array_length(_active);

    // First pass: hover detection on active cards
    if (obj_game.plr_hand_fan_expanded) {
        for (var _k = 0; _k < _n; _k++) {
            var _angle_deg_h;
            if (_n == 1) _angle_deg_h = 0;
            else _angle_deg_h = (_k - (_n - 1) / 2) * obj_game.HAND_FAN_ANGLE_DEG;
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
            else _angle_deg = (_k - (_n - 1) / 2) * obj_game.HAND_FAN_ANGLE_DEG;
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

    if (obj_game.state == "RUN_CONTENT_WIP") {
        draw_set_colour(UI_COLOR_HIGHLIGHT);
        draw_text_transformed(_cx, _cy - 82, "CONTENT IN", 0.9, 0.9, 0);
        draw_text_transformed(_cx, _cy - 34, "DEVELOPMENT", 0.9, 0.9, 0);
        draw_set_colour(UI_COLOR_NEUTRAL);
        draw_text_transformed(_cx, _cy + 20, "More stages are still being made.", 0.28, 0.28, 0);
        _draw_button(_cx - 120, _cy + 96, 240, 50, "BACK TO TITLE", 0.34);
        return;
    }

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
            var _enemy_cards = _enemy_deck_card_structs(_enemy);
            for (var _ec = 0; _ec < array_length(_enemy_cards); _ec++) {
                var _card_struct = _enemy_cards[_ec];
                array_push(_cards_to_show, {card_type: _str_to_card_type_int(_card_struct.type_name), rules: _card_struct.rules, display_name: ""});
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
        _draw_card_face(_c.card_type, _x, _y, _card_w, _card_h, 0, 1, true);
        var _stamp_n = min(3, array_length(_c.rules));
        for (var _sr = 0; _sr < _stamp_n; _sr++) {
            _draw_rule_chip(_c.rules[_sr], _x + _card_w - 18 - _sr * 13, _y + 6, 12);
        }
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
                draw_text_transformed(_tt_x + 8, _yy, "- " + _t(_rule_display_key(_rule.id)) + _level_str, 0.22, 0.22, 0);
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
    var _ty = _card.y - 150;
    var _w = 330;
    var _h = 94 + max(0, array_length(_card.rules)) * 28;
    // Clamp within screen
    if (_tx + _w > display_get_gui_width()) _tx = display_get_gui_width() - _w - 10;
    if (_tx < 10) _tx = 10;
    if (_ty < 10) _ty = _card.y + 145;   // flip below if too close to top

    draw_set_alpha(0.95);
    draw_set_colour(UI_COLOR_BG_MID);
    draw_rectangle(_tx, _ty, _tx + _w, _ty + _h, false);
    draw_set_alpha(1);
    draw_set_colour(UI_COLOR_HIGHLIGHT);
    draw_rectangle(_tx, _ty, _tx + _w, _ty + _h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_score);
    draw_set_colour(c_white);
    var _type_name = _card_type_display_label(_card.card_type);
    draw_text_transformed(_tx + 12, _ty + 8, _type_name + "  DMG " + string(_get_card_win_damage(_card)), 0.28, 0.28, 0);

    if (array_length(_card.rules) == 0) {
        draw_set_alpha(0.6);
        draw_text_transformed(_tx + 12, _ty + 42, "(no traits)", 0.22, 0.22, 0);
        draw_set_alpha(1);
    } else {
        var _yy = _ty + 42;
        for (var i = 0; i < array_length(_card.rules); i++) {
            var _r = _card.rules[i];
            var _level_str = (_r.max_level > 1) ? (" [L" + string(_r.level) + "/" + string(_r.max_level) + "]") : "";
            _draw_rule_chip(_r, _tx + 12, _yy, 22);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_colour(UI_COLOR_HIGHLIGHT);
            draw_text_transformed(_tx + 42, _yy - 2, _t(_rule_display_key(_r.id)) + _level_str, 0.22, 0.22, 0);
            draw_set_colour(c_white);
            _draw_text_ext_scaled(_tx + 42, _yy + 16, _t(_r.description_text), 17, _w - 54, 0.18);
            _yy += 28;
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

        // Card asset (face-up, by type)
        _draw_card_face(_c.card_type, _x - _card_w / 2, _y - _card_h / 2, _card_w, _card_h, 0, 1, true);

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

            _play_battle_sfx("shuffle");
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

        _draw_card_face(_c.card_type, _x, _y, _card_w, _card_h, 0, 1, true);

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
            _play_battle_sfx("card_land_play");
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

/// @desc 2026-04-26: shared "fresh run start" — close overlay, destroy any stale instances,
/// transition to RUN_START with no wait.
function _new_game_start_fresh() {
    _clear_all_card_instances();
    obj_game.ui_overlay_open = OV_NONE;
    obj_game.ui_overlay_prev = "";
    obj_game.ui_select_card_mode = false;
    obj_game.ui_select_card_callback = "";
    obj_game.ui_scry_cards = [];
    obj_game.ui_pile_picker_target = "";
    obj_game.selected_card = noone;
    obj_game.ui_drag_card = noone;
    obj_game.ui_drag_drop_target = "";
    obj_game.state = "RUN_START";
    obj_game.wait_timer = 0;
}

// ===== Phase 1 Batch 5 (D2): TITLE button click handler =====
// Layout mirrors obj_game/Draw_64.gml TITLE block.

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
        _new_game_start_fresh();
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
