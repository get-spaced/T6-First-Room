#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include scripts\zm\zm_tomb\zm_tomb_util;

#include scripts\zm\_utils;

init() {
  if (tolower(getdvar("mapname")) != "zm_tomb")
    return;

  onplayerconnect_callback(::on_player_connect);
}

on_player_connect() {
  self endon("disconnect");

  self thread give_origin_challenges();

  if (has_completed_headshot_goal()) {
    self thread lock_headshot_reward();
    return;
  }

  self thread info_display();
}

has_completed_headshot_goal() {
  if (!isdefined(level.completed_headshot_guids))
    return false;

  guid = "" + self.guid;

  if (isdefined(level.completed_headshot_guids[guid]))
    return true;

  return false;
}

mark_headshot_goal_complete() {
  if (!isdefined(level.completed_headshot_guids))
    level.completed_headshot_guids = [];

  guid = "" + self.guid;

  level.completed_headshot_guids[guid] = true;
}

lock_headshot_reward() {
  self endon("disconnect");

  while (!isdefined(level._challenges))
    wait 0.05;

  while (!maps\mp\zombies\_zm_challenges::challenge_exists("zc_headshots"))
    wait 0.05;

  wait 0.1;

  headshots = maps\mp\zombies\_zm_challenges::get_stat(
  "zc_headshots",
  self
  );

  if (!isdefined(headshots))
    return;

  headshots.n_value = 115;
  headshots.b_reward_claimed = 1;

  if (isdefined(self.characterindex))
    headshots.a_b_player_rewarded[self.characterindex] = 1;
}

info_display() {
  self endon("disconnect");
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  while (!isdefined(level._challenges))
    wait 0.05;

  while (!maps\mp\zombies\_zm_challenges::challenge_exists("zc_headshots"))
    wait 0.05;

  wait 3;

  headshot_goal = 115;
  last_headshot_value = 0;

  hud_args = spawnstruct();
  hud_args.font = "objective";
  hud_args.scale = 1.45;
  hud_args.alignx = "center";
  hud_args.aligny = "top";
  hud_args.horzalign = "center";
  hud_args.vertalign = "top";
  hud_args.x = 0;
  hud_args.y = -25;
  hud_args.hidewheninmenu = 1;
  hud_args.color = (1, 1, 1);
  hud_args.alpha = 1;

  self.origins_text = create_hud_elem(true, hud_args);

  for (;;) {
    headshots = maps\mp\zombies\_zm_challenges::get_stat(
    "zc_headshots",
    self
    );

    if (
    isdefined(headshots) &&
    isdefined(headshots.n_value)
    ) {
      last_headshot_value = headshots.n_value;
    }
    else if (last_headshot_value >= headshot_goal - 1) {
      last_headshot_value = headshot_goal;
    }

    if (last_headshot_value > headshot_goal)
      last_headshot_value = headshot_goal;

    if (last_headshot_value >= headshot_goal) {
      mark_headshot_goal_complete();

      self.origins_text set_string_text(
      "^2Claim your free weapon at the box!"
      );

      wait 10;

      if (isdefined(self.origins_text))
        self.origins_text destroy();

      self.origins_text = undefined;

      return;
    }

    self.origins_text set_string_text(
    "Headshots: ^3" +
    last_headshot_value +
    "^7/^3" +
    headshot_goal
    );

    wait 0.1;
  }
}

get_challenge_value(stat) {
  if (!isdefined(level._challenges))
    return 0;

  if (!maps\mp\zombies\_zm_challenges::challenge_exists(stat))
    return 0;

  data = maps\mp\zombies\_zm_challenges::get_stat(stat, self);

  if (!isdefined(data))
    return 0;

  return data.n_value;
}

give_origin_challenges() {
  self endon("disconnect");

  while (!isdefined(level._challenges))
    wait 0.05;

  while (!maps\mp\zombies\_zm_challenges::challenge_exists("zc_zone_captures"))
    wait 0.05;

  wait 3;

  self maps\mp\zombies\_zm_challenges::set_stat(
  "zc_zone_captures",
  6
  );

  self maps\mp\zombies\_zm_challenges::set_stat(
  "zc_points_spent",
  30000
  );

}

create_hud_elem(is_client, args) {
  if (is_client)
    hud = newclienthudelem(self);
  else
    hud = newhudelem();

  if (isdefined(args.text))
    hud settextunlimited(args.text);

  hud.font = isdefined(args.font) ? args.font : "objective";
  hud.fontscale = isdefined(args.scale) ? args.scale : 1.10;
  hud.x = isdefined(args.x) ? args.x : 0;
  hud.y = isdefined(args.y) ? args.y : 0;
  hud.alignx = isdefined(args.alignx) ? args.alignx : "center";
  hud.aligny = isdefined(args.aligny) ? args.aligny : "middle";
  hud.horzalign = isdefined(args.horzalign) ? args.horzalign : hud.alignx;
  hud.vertalign = isdefined(args.vertalign) ? args.vertalign : hud.aligny;
  hud.alpha = isdefined(args.alpha) ? args.alpha : 1;
  hud.foreground = 1;
  hud.hidewheninmenu = 1;
  hud.color = (1, 1, 1);
  return hud;
}