#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;

#include scripts\zm\_utils;

main() {
  safe_replacefunc("maps\mp\animscripts\zm_utility", "wait_network_frame", ::wait_network_frame_override);
  safe_replacefunc("maps\mp\zombies\_zm_utility", "wait_network_frame", ::wait_network_frame_override);

  safe_replacefunc("maps/mp/zombies/_zm_pers_upgrades", "is_pers_system_active", ::is_pers_active);
  safe_replacefunc("maps/mp/zombies/_zm_pers_upgrades", "is_pers_system_disabled", ::is_pers_disabled);
  safe_replacefunc("maps/mp/zombies/_zm_pers_upgrades", "pers_upgrade_init", ::blank);
  safe_replacefunc("maps/mp/zombies/_zm_pers_upgrades_system", "pers_upgrades_monitor", ::blank);

  if (get_current_map() == "zm_tomb")
    replacefunc(maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options, ::get_pack_a_punch_weapon_options_override);

  init_dvars();
  init_values();
}

init() {
  level thread remove_all_door_buys();
  level thread remove_mystery_box();
  level thread print_checksums();
  level thread track_zombie_counter_rounds();
  level thread remove_buildables();
  
  level thread init_violation_monitor();
  level thread init_timers();
  level thread init_endgame_restart();
  level thread init_powerup_monitor();

  if (get_current_map() == "zm_nuked") {
    y = array((1058.2, 387.3, -57), (609.28, 315.9, -53.89), (872.48, 461.88, -56.8), (851.1, 156.6, -51), (808, 140.5, -51), (602.53, 281.09, -55));
    
    foreach (origin in y)
      remove_mannequin(origin);
  }

  onplayerconnect_callback(::on_player_connected);
}

on_player_connected() {
  self endon("disconnect");

  self waittill("spawned_player");

  flag_wait("initial_blackscreen_passed");

  // store og username incase server changes
  self.original_name = self.name;

  self create_zombie_counter_hud();

  self thread record_fill_bank();
  self thread mule_kick_weapon_hud();
  self thread verify_network_frames();
  self thread give_weapon_on_spawn();
  self thread update_zombie_counter();
}

give_weapon_on_spawn() {
  self endon("disconnect");

  self give_weapons();

  for (;;) {
    self waittill_any("played_spawned", "spawned_player");

    self give_weapons();
  }
}

give_weapons() {
  weapon = get_map_weapon();
  
  self giveweapon(weapon);
  self switchtoweapon(weapon);

  if (self.score < 2500 && level.round_number >= 10)
    self.score = 2500;
}

get_map_weapon() {
  return "m14_zm";
}

verify_network_frames() {
  self notify("stop_network_verification");
  self endon("stop_network_verification");
  self endon("disconnect");
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  last_checked_round = -1;

  for (;;) {
    if (!isdefined(level.round_number) || level.round_number < 1 || level.round_number == last_checked_round) {
      level waittill("start_of_round");
      continue;
    }

    last_checked_round = level.round_number;

    if (!isdefined(level.players) || level.players.size < 1)
      continue;

    player_count = level.players.size;

    expected_frame = 50;

    if (player_count == 1)
      expected_frame = 100;

    start_time = gettime();
    wait_network_frame();
    frame_length = gettime() - start_time;

    if (!isdefined(level.players) || level.players.size != player_count)
      continue;

    if (frame_length == expected_frame) {
      self queue_print_client("Network frame: ^3" + frame_length + "ms^7 (^2GOOD^7)");
    } else {
      self queue_print_client("Network frame: ^3" + frame_length + "ms^7 (expected: ^3" + expected_frame + "ms^7) (^1BAD^7)");
    }
  }
}

is_good_either(player_count, frame_length, solo_framework, coop_framework) {
  if (player_count < 1 || frame_length <= 0)
    return false;

  if (player_count == 1)
    return frame_length == solo_framework;

  return frame_length == coop_framework;
}

wait_network_frame_override() {
  if (level.players.size == 1)
     wait 0.1;
  
  if (numremoteclients()) {
    snapshot_ids = getsnapshotindexarray();

    for (acked = undefined; !isdefined(acked); acked = snapshotacknowledged(snapshot_ids))
      level waittill("snapacknowledged");

    return;
  }
  
  wait 0.1;
}

record_fill_bank() {
  self endon("disconnect");
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  should_refill = get_dvar_default("refill_player_banks", 0, "int");

  if (!should_refill)
    return;

  if (!is_bank_map())
    return;

  self.account_value = int(level.bank_account_max);
  self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", self.account_value, level.banking_map);
}

mule_kick_weapon_hud() {
  self endon("disconnect");
  level endon("game_ended");
  level endon("end_game");

  hud = self create_mule_kick_hud();

  self.mule_third_weapon = undefined;

  for (;;) {
    owned = self hasperk("specialty_additionalprimaryweapon");
    primaries = self getweaponslistprimaries();

    if (!owned || primaries.size < 3) {
      hud.alpha = 0;
      self.mule_third_weapon = undefined;

      wait 0.15;
      continue;
    }

    if (!self is_active_player()) {
      hud.alpha = 0;

      wait 0.15;
      continue;
    }

    if (!isdefined(self.mule_third_weapon) || !self hasweapon(self.mule_third_weapon))
      self.mule_third_weapon = primaries[2];

    hud.alpha = 0;

    if (self getcurrentweapon() == self.mule_third_weapon)
      hud.alpha = 0.95;

    wait 0.15;
  }
}

create_mule_kick_hud() {
  hud_x = -96;
  hud_y = 12;

  if (isdefined(level.mule_icon_x))
    hud_x = level.mule_icon_x;

  if (isdefined(level.mule_icon_y))
    hud_y = level.mule_icon_y;

  hud = self createicon("specialty_additionalprimaryweapon_zombies", 24, 24);
  hud setpoint("BOTTOM_RIGHT", "BOTTOM_RIGHT", hud_x, hud_y);

  hud.foreground = 1;
  hud.sort = 30;
  hud.alpha = 0;
  hud.archived = 0;
  hud.hidewheninmenu = 1;

  return hud;
}

get_pack_a_punch_weapon_options_override(weapon) {
  if (!isdefined(self.pack_a_punch_weapon_options))
    self.pack_a_punch_weapon_options = [];

  if (!is_weapon_upgraded(weapon))
    return self calcweaponoptions(0, 0, 0, 0, 0);

  if (isdefined(self.pack_a_punch_weapon_options[weapon]))
    return self.pack_a_punch_weapon_options[weapon];

  base = get_base_name(weapon);
  reticle_index = self get_reticle_stat();

  if (!isdefined(reticle_index))
    reticle_index = randomintrange(0, 16);

  if (reticle_index == 16)
    reticle_index = 0;

  return self calcweaponoptions(45, 0, reticle_index, 0);
}

get_reticle_stat() {
  stat = self maps\mp\zombies\_zm_stats::get_map_weaponlocker_stat("stock", "zm_tomb");
  stat = int(stat);

  if (stat >= 1 && stat <= 16)
    return stat;

  return undefined;
}

remove_mannequin(origin, extra_delay) {
  level endon("end_game");

  if (isdefined(extra_delay))
    wait extra_delay;

  all_mannequins = [];
  destructibles = getentarray("destructible", "targetname");
    
  foreach (destructible in destructibles)
    if (issubstr(destructible.destructibledef, "male"))
      all_mannequins[all_mannequins.size] = destructible;

  foreach (mannequin in all_mannequins) {
    if (mannequin.origin == origin) {
      getent(mannequin.target, "targetname") delete();
      mannequin delete();

      break;
    }
  }
}