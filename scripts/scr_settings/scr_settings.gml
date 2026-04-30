// scr_settings.gml — settings.ini persistence (D30 + D45 tutorial_done + D46 stage pool)
// Call settings_load() right after i18n_init() in obj_game Create.

function settings_load() {
    ini_open("settings.ini");

    var _lang = ini_read_string("general", "language", "zh");
    _set_language(_lang);

    global.tutorial_done = ini_read_real("general", "tutorial_done", 0) == 1;
    // Phase 1 Batch 5 (D1): added master_volume + fullscreen
    global.master_volume = ini_read_real("audio", "master_volume", 1.0);
    global.sfx_volume    = ini_read_real("audio", "sfx_volume", 1.0);
    global.music_volume  = ini_read_real("audio", "music_volume", 1.0);
    global.fullscreen    = ini_read_real("general", "fullscreen", 0) == 1;

    ini_close();

    // Apply audio + fullscreen on load so settings take effect immediately.
    _apply_volume_settings();
    window_set_fullscreen(global.fullscreen);
}

function settings_save() {
    ini_open("settings.ini");
    ini_write_string("general", "language", global.current_language);
    ini_write_real("general", "tutorial_done", global.tutorial_done ? 1 : 0);
    ini_write_real("general", "fullscreen", global.fullscreen ? 1 : 0);
    ini_write_real("audio", "master_volume", global.master_volume);
    ini_write_real("audio", "sfx_volume", global.sfx_volume);
    ini_write_real("audio", "music_volume", global.music_volume);
    ini_close();
}

/// @desc Mark tutorial as done and save. Call after first tutorial completion (D45).
function settings_mark_tutorial_done() {
    global.tutorial_done = true;
    settings_save();
}

/// @desc Phase 1 Batch 5 (D1): clear tutorial_done flag and persist (TITLE → "Replay Tutorial").
function settings_replay_tutorial() {
    global.tutorial_done = false;
    settings_save();
}

/// @desc Phase 1 Batch 5 (D1): apply master_volume to audio engine (audio_master_gain affects all sounds).
/// SFX/Music split applied via per-sound audio_sound_gain in playback sites (Phase 4 audio batch).
function _apply_volume_settings() {
    audio_master_gain(global.master_volume);
    // 2026-04-27: also update active BGM gain (music slider should affect already-playing track).
    if (variable_global_exists("current_bgm_inst") && audio_is_playing(global.current_bgm_inst)) {
        audio_sound_gain(global.current_bgm_inst, global.master_volume * global.music_volume, 0);
    }
}
