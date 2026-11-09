#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_perk_divetonuke;
#include maps\mp\zombies\_zm_perk_electric_cherry;
#include maps\mp\zombies\_zm_perk_vulture;
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_laststand;

#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_pers_upgrades_functions;

init_dvars() {
  set_dvar_default("sv_cheats", 0);
  set_dvar_default("refill_player_banks", 1);

  set_dvar_default("scr_allowFileIo", "1");
  set_dvar_default("version", "1.0");

  set_dvar_default("player_strafeSpeedScale",        "0.8");
  set_dvar_default("player_backSpeedScale",          "0.7");
  set_dvar_default("g_speed",                        "190");
  set_dvar_default("con_gameMsgWindow0MsgTime",      "5");
  set_dvar_default("con_gameMsgWindow0Filter",       "gamenotify obituary");
  set_dvar_default("ai_corpseCount",                 "5");
  set_dvar_default("sv_endGameIfISuck",              "0");
  set_dvar_default("sv_patch_zm_weapons",            "1");
  set_dvar_default("r_dof_enable",                   "0");
  set_dvar_default("scr_skip_devblock",              "1");
  set_dvar_default("g_zm_fix_damage_overflow",       "1");
  set_dvar_default("g_fix_entity_leaks",             "0");
  set_dvar_default("cg_flashScriptHashes",           "1");
  set_dvar_default("cg_debugInfoCornerOffset",       "-20 15");
  set_dvar_default("cg_drawIdentifier",              "1");
  set_dvar_default("sv_clientFpsLimit",              "250");
  set_dvar_default("sv_clientFpsLimit",              "332");
}

init_values() {
  level.solo_framework = 100;
  level.coop_framework = 50;
}

safe_replacefunc(path, name, replacement) {
  func = getfunction(path, name);

  if (!isdefined(func))
    return false;

  if (!isdefined(level.old_funcs))
    level.old_funcs = [];

  level.old_funcs[name] = func;
  replacefunc(func, replacement);

  return true;
}

set_dvar_default(name, value) {
  if (getdvar(name) != "")
    return;

  setdvar(name, value);
}

get_dvar_default(dvar, def, type) {
  if (!isdefined(dvar) || dvar == "" || getdvar(dvar) == "")
    return def;
  if (!isdefined(type))
    type = "string";

  switch (tolower(type)) {
    case "int":
      return getdvarint(dvar);

    case "float":
      return getdvarfloat(dvar);

    case "bool":
      return getdvarint(dvar) != 0;

    case "string":
    default:
      return getdvar(dvar);
  }
}

get_current_map() {
  return getdvar("mapname");
}

is_bank_map() {
  map = get_current_map();
  return map == "zm_transit" || map == "zm_highrise" || map == "zm_buried";
}

is_active_player() {
  if (!isdefined(self) || !isplayer(self))
    return false;

  if (!isdefined(self.sessionstate) || self.sessionstate != "playing")
    return false;

  if (!isalive(self))
    return false;

  if (!isdefined(self.health) || self.health <= 0)
    return false;

  if (isdefined(self.is_zombie) && self.is_zombie)
    return false;

  if (isdefined(self.in_zombify_call) && self.in_zombify_call)
    return false;

  if (isdefined(self.intermission) && self.intermission)
    return false;

  if (isdefined(self.laststand) && self.laststand)
    return false;

  if (self maps\mp\zombies\_zm_laststand::player_is_in_laststand())
    return false;

  return true;
}


queue_print_client(message) {
  if (!isdefined(self) || !isplayer(self) || !isdefined(message))
    return;

  if (!isdefined(self.print_queue)) {
    self.print_queue = [];
    self.print_queue_head = 0;
    self.print_queue_tail = 0;
    self.print_queue_running = false;
  }

  self.print_queue[self.print_queue_tail] = message;
  self.print_queue_tail++;

  if (self.print_queue_running)
    return;

  self.print_queue_running = true;
  self thread queue_print_worker_client();
}

queue_print_worker_client() {
  self endon("disconnect");
  level endon("end_game");

  while (self.print_queue_head < self.print_queue_tail) {
    message = self.print_queue[self.print_queue_head];

    self.print_queue[self.print_queue_head] = undefined;
    self.print_queue_head++;

    if (isdefined(message))
      self iprintln(message);

    wait 0.85;
  }

  self.print_queue = [];
  self.print_queue_head = 0;
  self.print_queue_tail = 0;
  self.print_queue_running = false;
}

queue_print_server(message) {
  if (!isdefined(message))
    return;

  if (!isdefined(level.print_queue)) {
    level.print_queue = [];
    level.print_queue_head = 0;
    level.print_queue_tail = 0;
    level.print_queue_running = false;
  }

  level.print_queue[level.print_queue_tail] = message;
  level.print_queue_tail++;

  if (!level.print_queue_running) {
    level.print_queue_running = true;
    level thread queue_print_worker_server();
  }
}

queue_print_worker_server() {
  level endon("end_game");

  while (level.print_queue_head < level.print_queue_tail) {
    message = level.print_queue[level.print_queue_head];

    level.print_queue[level.print_queue_head] = undefined;
    level.print_queue_head++;

    if (isdefined(message))
      iprintln(message);

    wait 0.8;
  }

  level.print_queue = [];
  level.print_queue_head = 0;
  level.print_queue_tail = 0;
  level.print_queue_running = false;
}

remove_all_door_buys() {
  flag_wait("initial_blackscreen_passed");

  doors = getentarray("zombie_door", "targetname");
  debris = getentarray("zombie_debris", "targetname");

  foreach (door in doors) {
    if (!isdefined(door))
      continue;

    door trigger_off();
  }

  foreach (blocker in debris) {
    if (!isdefined(blocker))
      continue;

    blocker trigger_off();
  }
}

print_checksums() {
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  if (is_vanilla())
    cmdexec("flashScriptHashes");

  setdvar("cg_drawChecksums", 1);
  wait 3;
  setdvar("cg_drawChecksums", 0);
}

is_vanilla() {
  validMaps = array("zm_transit", "zm_nuked", "zm_highrise", "zm_prison", "zm_buried", "zm_tomb");
  currentMap = get_current_map();

  return is_in_array(validMaps, currentMap);
}

is_in_array(arr, val) {
  if (arr.size <= 0)
    return false;

  for (j = 0; j < arr.size; j++)
    if (arr[j] == val)
      return true;

  return false;
}

init_timers() {
  if (isdefined(level.fr_timers_initialized))
    return;

  level.fr_timers_initialized = true;
  level.fr_game_start = undefined;
  level.fr_round_start = undefined;
  level.fr_round_time = 0;
  level.fr_round_active = false;
  level.fr_split_round = 0;
  level.fr_split_time = 0;

  level thread track_timer_rounds();
  level thread create_timer_hud();
}

track_timer_rounds() {
  level endon("end_game");

  for (;;) {
    level waittill("start_of_round");

    if (!isdefined(level.fr_game_start))
      level.fr_game_start = gettime();

    level.fr_round_start = gettime();
    level.fr_round_time = 0;
    level.fr_round_active = true;

    if (isdefined(level.fr_round_hud))
      level.fr_round_hud setTimerUp(0);

    level waittill("end_of_round");

    level.fr_round_time = gettime() - level.fr_round_start;
    level.fr_round_active = false;

    level.fr_split_round = level.round_number;
    level.fr_split_time = gettime() - level.fr_game_start;

    if (isdefined(level.fr_round_hud))
      level.fr_round_hud set_string_text(format_timer_time(level.fr_round_time));

    if (isdefined(level.fr_split_hud))
      level.fr_split_hud set_string_text("R" + level.fr_split_round + " - " + format_timer_time(level.fr_split_time));
  }
}

create_timer_hud() {
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  if (!isdefined(level.fr_game_start))
    level.fr_game_start = gettime();

  level.fr_game_hud = create_timer_element(-30, "^2GAME  ^7");
  level.fr_round_hud = create_timer_element(-10, "^3ROUND  ^7");
  level.fr_split_hud = create_timer_element(10, "^5SPLIT  ^7");

  game_elapsed = (gettime() - level.fr_game_start) / 1000.0;

  level.fr_game_hud setTimerUp(game_elapsed);

  if (level.fr_round_active && isdefined(level.fr_round_start)) {
    round_elapsed = (gettime() - level.fr_round_start) / 1000.0;
    level.fr_round_hud setTimerUp(round_elapsed);
  } else {
    level.fr_round_hud set_string_text(format_timer_time(level.fr_round_time));
  }

  if (level.fr_split_round > 0) {
    level.fr_split_hud set_string_text("R" + level.fr_split_round + " - " + format_timer_time(level.fr_split_time));
  } else {
    level.fr_split_hud set_string_text("--:--");
  }
}

create_timer_element(y, label) {
  hud = createServerFontString("objective", 1.5);

  hud setpoint("TOPLEFT", "TOPLEFT", -55, y);

  hud.label = istring(label);
  hud.color = (1, 1, 1);
  hud.alpha = 1;
  hud.sort = 10;
  hud.hideWhenInMenu = 0;
  hud.glowAlpha = 0;

  return hud;
}

format_timer_time(milliseconds) {
  if (!isdefined(milliseconds) || milliseconds < 0)
    milliseconds = 0;

  total_seconds = int(milliseconds / 1000);

  hours = int(total_seconds / 3600);
  minutes = int(total_seconds / 60) % 60;
  seconds = total_seconds % 60;

  seconds_text = "" + seconds;

  if (seconds < 10)
    seconds_text = "0" + seconds;

  if (hours > 0) {
    minutes_text = "" + minutes;

    if (minutes < 10)
      minutes_text = "0" + minutes;

    return hours + ":" + minutes_text + ":" + seconds_text;
  }

  return minutes + ":" + seconds_text;
}

set_string_text(text) {
  if (!isdefined(text))
    text = "";

  if (isdefined(self.text) && self.text == text)
    return;

  self settextunlimited(text);
  self.text = text;
}

set_value_text(value) {
  if (!isdefined(value))
    value = 0;

  text = "" + value;

  if (isdefined(self.text) && self.text == text)
    return;

  self settextunlimitedun(text);
  self.text = text;
}

destroy_element() {
  if (isdefined(self.frame))
    self.frame destroy();

  if (isdefined(self.bar))
    self.bar destroy();

  if (isdefined(self.barframe))
    self.barframe destroy();

  self destroy();
}

init_violation_monitor() {
  if (isdefined(level.vm_initialized))
    return;

  level.vm_initialized = true;
  level.vm_seen = [];

  level thread vm_start();
}

vm_start() {
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  level.vm_status = createServerFontString("objective", 1.3);
  level.vm_status setPoint("CENTER", "TOP", 0, 28);
  level.vm_status.color = (0.3, 1, 0.5);
  level.vm_status.alpha = 1;
  level.vm_status.sort = 20;
  level.vm_status.hideWhenInMenu = 0;
  level.vm_status set_string_text("INTEGRITY MONITOR ACTIVE");

  level thread vm_status_intro();

  level.vm_alert = createServerFontString("objective", 1.6);
  level.vm_alert setPoint("CENTER", "TOP", 0, 65);
  level.vm_alert.color = (1, 0.2, 0.2);
  level.vm_alert.alpha = 0;
  level.vm_alert.sort = 20;
  level.vm_alert.hideWhenInMenu = 0;
  level.vm_alert set_string_text("VIOLATION DETECTED");

  level.vm_reason = createServerFontString("objective", 1.4);
  level.vm_reason setPoint("CENTER", "TOP", 0, 88);
  level.vm_reason.color = (1, 1, 1);
  level.vm_reason.alpha = 0;
  level.vm_reason.sort = 20;
  level.vm_reason.hideWhenInMenu = 0;
  level.vm_reason set_string_text("UNKNOWN VIOLATION");

  level.vm_speed = getdvar("g_speed");
  level.vm_gravity = getdvar("g_gravity");

  level thread vm_monitor();
}


vm_status_intro() {
  level endon("end_game");
  level endon("vm_status_override");

  for (i = 0; i < 3; i++) {
    level.vm_status fadeOverTime(0.2);
    level.vm_status.alpha = 1;

    wait 0.4;

    level.vm_status fadeOverTime(0.2);
    level.vm_status.alpha = 0.25;

    wait 0.3;
  }

  level.vm_status fadeOverTime(0.2);
  level.vm_status.alpha = 1;

  wait 2.9;

  level.vm_status fadeOverTime(0.5);
  level.vm_status.alpha = 0;
}


vm_report(code, message) {
  if (!isdefined(level.vm_status))
    return;

  if (isdefined(level.vm_seen[code]))
    return;

  level.vm_seen[code] = true;

  level notify("vm_status_override");

  level.vm_status.color = (1, 0.2, 0.2);
  level.vm_status.alpha = 1;
  level.vm_status set_string_text("RUN INVALIDATED");

  level notify("vm_next_alert");
  level thread vm_flash(message);
}


vm_flash(message) {
  level endon("end_game");
  level endon("vm_next_alert");

  level.vm_reason set_string_text(message);

  for (i = 0; i < 3; i++) {
    level.vm_alert.alpha = 1;
    level.vm_reason.alpha = 1;

    wait 0.3;

    level.vm_alert.alpha = 0.2;
    level.vm_reason.alpha = 0.2;

    wait 0.3;
  }

  level.vm_alert.alpha = 1;
  level.vm_reason.alpha = 1;

  wait 3;

  level.vm_alert fadeOverTime(0.5);
  level.vm_alert.alpha = 0;

  level.vm_reason fadeOverTime(0.5);
  level.vm_reason.alpha = 0;
}

vm_monitor() {
  level endon("end_game");

  for (;;) {
    if (getdvarint("sv_cheats") != 0)
      vm_report("CHEATS", "CHEATS ENABLED");

    if (level.vm_speed != "" && getdvar("g_speed") != level.vm_speed)
      vm_report("SPEED", "MOVEMENT SPEED MODIFIED");

    if (level.vm_gravity != "" && getdvar("g_gravity") != level.vm_gravity)
      vm_report("GRAVITY", "GRAVITY MODIFIED");

    foreach (player in get_players()) {
      if (!isdefined(player) || !isplayer(player))
        continue;

      if (isdefined(player.vm_godmode) && player.vm_godmode)
        vm_report("GOD_" + player.name, "GOD MODE ENABLED");

      if (isdefined(player.godmode_active) && player.godmode_active)
        vm_report("GOD_" + player.name, "GOD MODE ENABLED");

      if (!isdefined(player.health) || !isdefined(player.maxhealth))
        continue;

      if (player.health > player.maxhealth || player.maxhealth > 300)
        vm_report("HEALTH_" + player.name, "ABNORMAL PLAYER HEALTH");
    }

    wait 0.5;
  }
}

remove_mystery_box() {
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  if (isdefined(level.chests)) {
    foreach (chest in level.chests) {
      if (!isdefined(chest))
        continue;

      chest.disabled = 1;
      chest notify("kill_chest_think");

      if (isdefined(chest.unitrigger_stub))
        maps\mp\zombies\_zm_unitrigger::unregister_unitrigger(chest.unitrigger_stub);

      chest maps\mp\zombies\_zm_magicbox::hide_chest();
    }
  }
}


init_endgame_restart() {
  if (isdefined(level.fr_restart_initialized))
    return;

  level.fr_restart_initialized = true;

  precacheShader("white");

  level thread fr_restart_listener();
}

fr_restart_listener() {
  level waittill("end_game");

  if (getdvarint("dedicated") != 0)
    return;

  host = gethostplayer();

  if (!isdefined(host) || !isplayer(host))
    return;

  host thread fr_restart_host();
}

fr_restart_host() {
  self endon("disconnect");

  wait 0.5;

  self fr_restart_create_hud();

  self.fr_restart_header set_string_text("FIRST ROOM  /  HOST CONTROL");
  self.fr_restart_title set_string_text("RESTART AVAILABLE");
  self.fr_restart_hint set_string_text("^7[{+speed_throw}] ^3+ ^7[{+melee}]");
  self.fr_restart_footer set_string_text("PRESS BOTH TO RESTART THE GAME");

  self.fr_restart_bg fadeOverTime(0.4);
  self.fr_restart_bg.alpha = 0.85;

  self.fr_restart_accent fadeOverTime(0.4);
  self.fr_restart_accent.alpha = 1;

  self.fr_restart_header fadeOverTime(0.4);
  self.fr_restart_header.alpha = 1;

  self.fr_restart_title fadeOverTime(0.5);
  self.fr_restart_title.alpha = 1;

  self.fr_restart_hint fadeOverTime(0.6);
  self.fr_restart_hint.alpha = 1;

  self.fr_restart_footer fadeOverTime(0.7);
  self.fr_restart_footer.alpha = 1;

  self thread fr_restart_pulse();

  end_time = gettime() + 17000;

  self.fr_restart_held = self adsbuttonpressed() && self meleebuttonpressed();

  while (gettime() < end_time) {
    if (self fr_restart_combo_pressed()) {
      self notify("fr_restart_close");

      self.fr_restart_title.color = (0.35, 1, 0.6);
      self.fr_restart_title set_string_text("RESTARTING GAME");

      self.fr_restart_hint set_string_text("PLEASE WAIT");
      self.fr_restart_footer set_string_text("PREPARING A NEW RUN");

      self.fr_restart_accent.alpha = 1;

      wait 0.4;

      cmdexec("map_restart");
      return;
    }

    wait 0.05;
  }

  self fr_restart_remove_hud();
}

fr_restart_combo_pressed() {
  pressed = self adsbuttonpressed() && self meleebuttonpressed();

  if (!isdefined(self.fr_restart_held))
    self.fr_restart_held = false;

  if (pressed && !self.fr_restart_held) {
    self.fr_restart_held = true;
    return true;
  }

  self.fr_restart_held = pressed;

  return false;
}

fr_restart_create_hud() {
  self fr_restart_remove_hud();

  self.fr_restart_bg = newclienthudelem(self);
  self.fr_restart_bg.horzalign = "center";
  self.fr_restart_bg.vertalign = "middle";
  self.fr_restart_bg.alignx = "center";
  self.fr_restart_bg.aligny = "middle";
  self.fr_restart_bg.x = 0;
  self.fr_restart_bg.y = 95;
  self.fr_restart_bg.color = (0.025, 0.045, 0.065);
  self.fr_restart_bg.alpha = 0;
  self.fr_restart_bg.sort = 25;
  self.fr_restart_bg.hideWhenInMenu = 0;
  self.fr_restart_bg setShader("white", 440, 145);

  self.fr_restart_accent = newclienthudelem(self);
  self.fr_restart_accent.horzalign = "center";
  self.fr_restart_accent.vertalign = "middle";
  self.fr_restart_accent.alignx = "center";
  self.fr_restart_accent.aligny = "middle";
  self.fr_restart_accent.x = 0;
  self.fr_restart_accent.y = 23;
  self.fr_restart_accent.color = (0.3, 1, 0.78);
  self.fr_restart_accent.alpha = 0;
  self.fr_restart_accent.sort = 26;
  self.fr_restart_accent.hideWhenInMenu = 0;
  self.fr_restart_accent setShader("white", 440, 3);

  self.fr_restart_header = self fr_restart_text(42, 1.15, (0.55, 0.8, 0.8));
  self.fr_restart_title = self fr_restart_text(70, 2.5, (1, 1, 1));
  self.fr_restart_hint = self fr_restart_text(108, 2, (0.35, 1, 0.75));
  self.fr_restart_footer = self fr_restart_text(140, 1.15, (0.75, 0.8, 0.85));
}

fr_restart_text(y, scale, color) {
  hud = newclienthudelem(self);

  hud.horzalign = "center";
  hud.vertalign = "middle";
  hud.alignx = "center";
  hud.aligny = "middle";
  hud.x = 0;
  hud.y = y;
  hud.font = "default";
  hud.fontscale = scale;
  hud.color = color;
  hud.alpha = 0;
  hud.foreground = 1;
  hud.sort = 30;
  hud.hideWhenInMenu = 0;

  return hud;
}

fr_restart_pulse() {
  self endon("disconnect");
  self endon("fr_restart_close");

  for (;;) {
    self.fr_restart_accent fadeOverTime(0.65);
    self.fr_restart_accent.alpha = 0.35;

    wait 0.65;

    self.fr_restart_accent fadeOverTime(0.65);
    self.fr_restart_accent.alpha = 1;

    wait 0.65;
  }
}

fr_restart_remove_hud() {
  self notify("fr_restart_close");

  if (isdefined(self.fr_restart_bg)) {
    self.fr_restart_bg destroy();
    self.fr_restart_bg = undefined;
  }

  if (isdefined(self.fr_restart_accent)) {
    self.fr_restart_accent destroy();
    self.fr_restart_accent = undefined;
  }

  if (isdefined(self.fr_restart_header)) {
    self.fr_restart_header destroy();
    self.fr_restart_header = undefined;
  }

  if (isdefined(self.fr_restart_title)) {
    self.fr_restart_title destroy();
    self.fr_restart_title = undefined;
  }

  if (isdefined(self.fr_restart_hint)) {
    self.fr_restart_hint destroy();
    self.fr_restart_hint = undefined;
  }

  if (isdefined(self.fr_restart_footer)) {
    self.fr_restart_footer destroy();
    self.fr_restart_footer = undefined;
  }
}


init_powerup_monitor() {
  if (isdefined(level.pm_initialized))
    return;

  level.pm_initialized = true;
  level.pm_last_drop_count = 0;

  level thread pm_reset_round();
  level thread pm_monitor_drops();
}

pm_reset_round() {
  level endon("end_game");

  for (;;) {
    level waittill("start_of_round");
    level.pm_last_drop_count = 0;
  }
}

pm_monitor_drops() {
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  for (;;) {
    level waittill("powerup_dropped", powerup);

    if (!isdefined(level.powerup_drop_count))
      continue;

    count = level.powerup_drop_count;

    if (count <= level.pm_last_drop_count)
      continue;

    level.pm_last_drop_count = count;

    if (!isdefined(powerup) || !isdefined(powerup.powerup_name))
      continue;

    powerup thread pm_monitor_pickup(powerup.powerup_name);
  }
}

pm_monitor_pickup(powerup_name) {
  level endon("end_game");

  for (;;) {
    if (!isdefined(self))
      return;

    if (isdefined(self.claimed) && self.claimed) {
      pm_print_pickup(powerup_name);
      return;
    }

    wait 0.05;
  }
}

pm_print_pickup(powerup_name) {
  max_drops = 4;

  if (isdefined(level.zombie_vars["zombie_powerup_drop_max_per_round"]))
    max_drops = level.zombie_vars["zombie_powerup_drop_max_per_round"];

  dropped = level.powerup_drop_count;
  remaining = max_drops - dropped;

  if (remaining < 0)
    remaining = 0;

  name = pm_powerup_name(powerup_name);
  cycle = pm_remaining_cycle();

  foreach (player in get_players()) {
    if (!isdefined(player) || !isplayer(player))
      continue;

    player queue_print_client("^2[POWERUP]^7: " + name + " ^3-^7 Drops left: ^2" + remaining + "/" + max_drops);
    player queue_print_client("^5[CYCLE]^7: " + cycle);
  }
}

pm_remaining_cycle() {
  if (!isdefined(level.zombie_powerup_array))
    return "Unavailable";

  if (!isdefined(level.zombie_powerup_index))
    return "Unavailable";

  remaining = "";
  pool = level.zombie_powerup_array;

  for (i = level.zombie_powerup_index; i < pool.size; i++) {
    powerup = pool[i];

    if (!isdefined(level.zombie_powerups[powerup]))
      continue;

    info = level.zombie_powerups[powerup];

    if (!isdefined(info.func_should_drop_with_regular_powerups))
      continue;

    if (![[ info.func_should_drop_with_regular_powerups ]]())
      continue;

    if (remaining != "")
      remaining += ", ";

    remaining += pm_powerup_name(powerup);
  }

  if (remaining == "")
    return "No eligible powerups left in cycle";

  return remaining;
}

pm_powerup_name(powerup) {
  switch (powerup) {
    case "nuke":
      return "Nuke";

    case "insta_kill":
      return "Insta-Kill";

    case "full_ammo":
      return "Max Ammo";

    case "double_points":
      return "Double Points";

    case "carpenter":
      return "Carpenter";

    case "fire_sale":
      return "Fire Sale";

    case "bonfire_sale":
      return "Bonfire Sale";

    case "minigun":
      return "Death Machine";

    case "free_perk":
      return "Free Perk";

    case "zombie_blood":
      return "Zombie Blood";

    case "bonus_points_team":
    case "bonus_points_player":
      return "Bonus Points";

    default:
      return powerup;
  }
}