// ===== Sprint 3 Phase 1: duplicate instance guard (D56 persistent + room-layer dup) =====
// obj_game.persistent = true so run state survives room_goto to rm_shop/rest/etc.
// But room0's layer re-creates an instance each time room is entered → dup. Self-destroy the 2nd.
if (instance_number(obj_game) > 1) {
    instance_destroy();
    exit;
}

// ===== Round 4 Sprint 2: i18n + settings init (must run before any UI text draws) =====
i18n_init();
settings_load();

// ===== Layout constants (Sprint 3 Phase 2b.2 — 4-pile table layout for 1280×720, D63 §3.13.4) =====
// opp pile 上 y=110, plr pile 下 y=620 (中场线 y=420 分割). 左 x=50 = draw pile, 右 x=1150 = discard pile.
// 2026-04-26 layout rebuild — vertical zones (0-720):
// 0-30 opp HP bar / 30-220 opp fan / 220-380 opp_play / 380-450 mid + DUEL /
// 450-620 plr_play / 530-680 plr fan / 690-720 plr HP bar.
DRAW_X = 50;          // left side
DISCARD_X = 1110;     // right side. Was 1150 — moved in 40px so region (1105+110=1215) clears 1280 with 65px gap (was only 25).
// Decks pulled further from HP bar (HP top 20-44, bot 680-704) per user "字体和血条重叠".
OPP_DRAW_Y = 100;     // region top 95, label at y=91 — 47px gap from HP bar (44)
OPP_DISCARD_Y = 100;
PLR_DRAW_Y = 480;     // region top 475, plr_play bottom 540 → gap-clean
PLR_DISCARD_Y = 480;

OPP_HAND_Y = 130;     // opp hand horizontal row y (Phase 2b.4 will change to fan center)
PLR_HAND_Y = 560;     // plr hand center y target — fan layout takes over via _update_plr_hand_fan
HAND_X[0] = 530;      // spread for DEAL temporary positioning before fan
HAND_X[1] = 640;
HAND_X[2] = 750;

// 2026-04-26 layout v3 — even 5-zone vertical (per user "5 个东西始终清晰可见"):
//   0-30   opp HP / region label
//   30-170 opp fan (中卡 top y=30, bottom 170)
//   200-340 opp_play (140px tall card, top y=200)
//   350-390 DUEL btn (h=40, gap 10/10)
//   400-540 plr_play (top y=400)
//   560-700 plr fan (中卡 top y=560, bottom 700)
//   680-720 plr HP / region label / item bar
OPP_PLAY_X = 640;
OPP_PLAY_Y = 200;
PLR_PLAY_X = 640;
PLR_PLAY_Y = 400;

PILE_OFFSET = 1;      // 3 → 1: tighter stack, deck cards fit within 150px region without overflow.

// ===== Sprint 3 Phase 2b.3: 玩家手牌扇形花切 constants (D63 §3.13.4) =====
// Fan v3: pivot 780 + radius 220 → 中卡 top y=560 (visible, bottom 700 < HP bar 680 — wait, overlap).
// Actually: 中卡 top y = pivot - radius = 560. 边卡 top y = pivot - cos(30°)*radius = 590.
// 边卡 bottom = 590 + 140 = 730. 超出. 用 radius 200: 中卡 top 580, 边卡 bottom 580+27+140=747. 还超.
// Pragmatic: radius 200 + pivot 760 → 中卡 top 560, 边卡 top 587, 边卡 bottom 727 (slight overflow,
// HP bar at y=680-704 in (20,20)-(260,260) doesn't overlap fan x=540-750 anyway).
HAND_FAN_PIVOT_X = 640;
HAND_FAN_PIVOT_Y = 760;
HAND_FAN_RADIUS  = 200;
HAND_FAN_ANGLE_DEG = 26;             // slightly tighter to keep 边卡 bottom in screen
HAND_FAN_ROTATION_DEG = 8;
HAND_FAN_HOVER_THRESHOLD_Y = 500;    // mouse > 500 → expand
HAND_FAN_POP_PX = 50;
HAND_FAN_COLLAPSED_SPREAD = 10;      // collapsed stack slight x-offset between cards

// Fan state (updated per-frame by _update_plr_hand_fan in _ui_per_frame_update)
plr_hand_fan_expanded = false;
plr_hand_hovered_idx = -1;           // 0/1/2 or -1 if none

// Sprint 3 Phase 2b.4: 敌人手牌镜像扇形 — pivot 在屏幕顶部 y=40, fan 向下开 (与玩家镜像)
// 敌人扇形始终展开 (玩家不与其交互), 无 hover pop, 卡始终背面朝玩家
OPP_HAND_FAN_PIVOT_Y = -170;         // mirror: 中卡 top y=30, 边卡 top y=4 (visible)

// ===== Score (Midterm transient; not used for win/lose in Round 2) =====
score_opp = 0;
score_plr = 0;
WIN_SCORE = 5;          // Midterm GAME_OVER; unused in Round 2 (replaced by HP)
game_over_result = "";  // Midterm artifact; unused in Round 2

// ===== Round 2 / D49 (revised 2026-04-26): HP system (player starts at 5, was 10) =====
player_hp = 5;
player_max_hp = 5;
opp_hp = 0;
opp_max_hp = 0;

// ===== Round 2: Resources =====
gold = 0;
items = [];

// ===== Round 3: UI state =====
ui_overlay_open = "";          // Use OV_* macros (see scr_ui_helpers)
ui_tooltip_target = noone;
ui_remove_selected_idx = -1;
ui_remove_confirming = false;
ui_player_hp_display = 5;       // lerped HP for animation; init matches player_hp
ui_opp_hp_display = 0;
ui_hp_flash_timer = 0;
ui_hp_flash_owner = "";
// Phase 1 Batch 2 (C2/C3): Tier A hit FX + KO ritual state (D27).
// `ui_last_hit_fast` removed — semantics inverted: KO is now slow-mo (×3) not fast-forward (÷2).
ui_screen_shake_timer = 0;       // ticks remaining (decays linearly, amp = timer * 0.4)
ui_hit_flash_timer = 0;           // vignette duration on loser side
ui_hit_flash_color = c_white;     // RPS-typed (rock=#8B0000, scissors=#00FFFF, paper=#FFFFFF)
ui_hit_flash_owner = "";          // "player"/"opp" — which half-screen gets the vignette
ui_ko_active = false;             // C3: true between JUDGE (HP→0) and BATTLE_END_CHECK
// Round 4 前瞻 slot（避免 Round 4 回填 struct）
ui_reward_candidates = [];
ui_shop_items = [];
ui_event_data = undefined;

// Backlog cleanup: overlay back-stack — when nested overlay opens (e.g. pause → settings),
// store prev so ESC closes back to it instead of dumping to OV_NONE. Currently only used by
// pause→settings nav, but generalizes to any future nested overlay.
ui_overlay_prev = "";

// 2026-04-27: previous overlay for SFX edge detection (open/close transitions).
prev_overlay = "";

// 2026-04-27: BGM globals (init once on game launch — settings_load handles persistence).
if (!variable_global_exists("current_bgm")) global.current_bgm = "";
if (!variable_global_exists("current_bgm_inst")) global.current_bgm_inst = noone;

// Phase 1 Batch 4 (B3/B4/B5): item-driven card-select / overlay state.
// `ui_select_card_mode` enables hand-click-resolves-to-callback flow (B3 discard_own_hand).
// `ui_scry_cards` snapshots top 3 of player_draw_pile for scry overlay (B4).
// `ui_pile_picker_target` tells pile picker overlay which discard to show (B5 steal/recover).
// `player_excluded_pile` is a limbo array for discard_own_hand (B3 limbo design — cards not in
// discard pile so they don't get reshuffled into the draw pile mid-battle; reset on BATTLE_START).
ui_select_card_mode = false;
ui_select_card_callback = "";
ui_scry_cards = [];
ui_pile_picker_target = "";
player_excluded_pile = [];

// ===== Round 2: Run map state =====
map = [];
map_position = 0;
current_battle_index = 0;
current_stage_id = "";         // D55: current stage (used for rule_pool / reward lookup)
current_branch_line = "";      // "A" | "B" | ""
current_branch_sub_index = 0;  // 0 or 1 (within a branch line)

// ===== Round 4 Sprint 2: AI rule F memory (D48/D58) + H1 hidden draw flag (D59) =====
last_player_play_type = "";        // "rock" | "scissors" | "paper" | "" (first turn / no data)
last_player_won_last_turn = false; // true if player beat enemy last round → F rule triggers
current_stage_has_h1 = false;      // mirror of stage.has_h1 for current battle
player_immune_this_round = false;  // D48: set by item_immune_this_round, cleared after DISCARD

// Sprint 3 Phase 2d: upgrade context — set by source rooms (rest/shop/event_d/starter), cleared after finalize
upgrade_context = undefined;

// Sprint 3 Phase 3.tutorial (D28): flag set by RUN_START if tutorial_done=false (first play).
// _upgrade_finalize source="starter" checks this to decide: tutorial complete → TITLE; regular → BATTLE_START.
is_tutorial_run = false;

// ===== Round 2: Player deck (config layer, persists across battles) =====
player_deck = [];              // Array<CardStruct>

// ===== State machine =====
state = "TITLE";
wait_timer = 0;
deal_step = 0;
discard_step = 0;
selected_card = noone;

// ===== PEEK state (Sprint 2 / D42+D43): held item peek now in PLAYER_WAIT, not phase =====
// peeked_card / peek_used fields removed — peek is now item-driven (item_use spawns
// reveal immediately), and dedupe is tracked via obj_card.is_peek_revealed (D60).

// ===== Independent decks (Round 2; replaces midterm draw_pile/discard_pile) =====
player_draw_pile = [];
player_discard_pile = [];
opp_draw_pile = [];
opp_discard_pile = [];

// ===== SHUFFLE parameterization (Round 2) =====
shuffling_owner = "";  // "player" | "opp" | ""

// ===== Hand / play slots (Midterm retained) =====
opp_hand[0] = noone; opp_hand[1] = noone; opp_hand[2] = noone;
plr_hand[0] = noone; plr_hand[1] = noone; plr_hand[2] = noone;
opp_play = noone;
plr_play = noone;
discard_queue = [];

// ===== Initialize rule engine (M2 guard inside prevents reset on room_restart) =====
rule_engine_init();

// Round 1 verification block removed in Sprint 2 — it referenced sample_*_training_dummy
// and display_name/name fields that were deleted under D51/D54 minimal-naming refactor.

// ===== Sprint 2 self-test (runs once on Create; logs PASS/FAIL for new helpers + configs) =====
_sprint2_self_test();
