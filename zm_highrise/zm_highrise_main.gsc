#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include scripts\zm\zm_highrise\zm_highrise_util;

#include scripts\zm\_utils;

main() {
  if (tolower(getdvar("mapname")) != "zm_highrise")
    return;

  safe_replacefunc("maps/mp/zm_highrise_classic", "escape_pod", ::escape_pod_override);
  safe_replacefunc("maps/mp/zombies/_zm_perks", "give_random_perk", ::give_random_perk_override);
  safe_replacefunc("maps/mp/zombies/_zm_ai_leaper", "leaper_round_accuracy_tracking", ::leaper_round_accuracy_tracking_override);
}

escape_pod_override() {
  escape_pod = getent( "elevator_bldg1a_body", "targetname" );
  escape_pod setmovingplatformenabled( 1 );
  escape_pod maps\mp\zm_highrise_classic::escapeelevatoruseanimtree();
  escape_pod_trigger = getent( "escape_pod_trigger", "targetname" );
  escape_pod.is_elevator = 1;
  escape_pod._post_host_migration_thread = maps\mp\zm_highrise_elevators::escape_pod_host_migration_respawn_check;

  if ( !isdefined( escape_pod_trigger ) )
    return;

    escape_pod.home_origin = escape_pod.origin;
    escape_pod.link_start = [];
    escape_pod.link_end = [];
    escape_pod_blocker_door = getent( "elevator_bldg1a_body_door_clip", "targetname" );
    number_of_times_used = 0;
    used_at_least_once = 0;
    escape_pod setanim( level.escape_elevator_1_state );
    escape_pod setclientfield( "clientfield_escape_pod_light_fx", 1 );
    escape_pod_trigger thread maps\mp\zm_highrise_classic::escape_pod_walk_on_off( escape_pod );

    while ( true ) {
        escape_pod setanim( level.escape_elevator_idle );
        flag_clear( "escape_pod_needs_reset" );

        if ( isdefined( escape_pod_blocker_door ) ) {
            escape_pod maps\mp\zm_highrise_classic::escape_pod_linknodes( "escape_pod_door_l_node" );
            escape_pod maps\mp\zm_highrise_classic::escape_pod_linknodes( "escape_pod_door_r_node" );
            escape_pod_blocker_door unlink();
            escape_pod_blocker_door thread trigger_off();
        }

        if ( is_true( used_at_least_once ) )
            wait 3;

        escape_pod thread maps\mp\zm_highrise_classic::escape_pod_state_run();

        while ( true ) {
            players_in_escape_pod = escape_pod_trigger maps\mp\zm_highrise_classic::escape_pod_get_all_alive_players_inside();

            if ( players_in_escape_pod == 0 ) {
                escape_pod.escape_pod_state = 1;
                wait 0.05;
                continue;
            }

            all_players_touching = escape_pod_trigger maps\mp\zm_highrise_classic::escape_pod_are_all_alive_players_ready();
            players_total = escape_pod_trigger maps\mp\zm_highrise_classic::escape_pod_get_all_alive_players();
            players_in_escape_pod = escape_pod_trigger maps\mp\zm_highrise_classic::escape_pod_get_all_alive_players_inside();

            if ( players_in_escape_pod > 0 )
                escape_pod.escape_pod_state = 2;

            wait 0.05;
        }

        level notify( "escape_pod_falling_begin" );
        players = get_players();

        foreach ( player in players ) {
            player.riding_escape_pod = 1;
            player allowjump( 0 );
        }

        if ( isdefined( escape_pod_blocker_door ) ) {
            escape_pod_blocker_door trigger_on();
            escape_pod_blocker_door linkto( escape_pod );
            escape_pod maps\mp\zm_highrise_classic::escape_pod_unlinknodes( "escape_pod_door_l_node" );
            escape_pod maps\mp\zm_highrise_classic::escape_pod_unlinknodes( "escape_pod_door_r_node" );
        }

        escape_pod.escape_pod_state = 5;
        escape_pod thread maps\mp\zm_highrise_classic::escape_pod_shake();
        wait( getanimlength( level.escape_elevator_5_state ) - 0.05 );
        escape_pod setanim( level.escape_elevator_drop );
        escape_pod setclientfield( "clientfield_escape_pod_light_fx", 0 );
        escape_pod setclientfield( "clientfield_escape_pod_sparks_fx", 1 );
        escape_pod thread maps\mp\zm_highrise_classic::escape_pod_move();
        escape_pod thread maps\mp\zm_highrise_classic::escape_pod_rotate();
        escape_pod waittill( "reached_destination" );
        number_of_times_used++;
        escape_pod thread maps\mp\zm_highrise_classic::impact_animate();

        if ( number_of_times_used == 1 ) {
            level.escape_elevator_idle = level.escape_elevator_damage_idle_state;
            level.escape_elevator_drop = level.escape_elevator_damage_drop_state;
            level.escape_elevator_impact = level.escape_elevator_damage_impact_state;
        }

        level notify( "escape_pod_falling_complete" );

        if ( isdefined( escape_pod_blocker_door ) ) {
            escape_pod_blocker_door unlink();
            escape_pod_blocker_door trigger_off();
            escape_pod maps\mp\zm_highrise_classic::escape_pod_linknodes( "escape_pod_door_l_node" );
            escape_pod maps\mp\zm_highrise_classic::escape_pod_linknodes( "escape_pod_door_r_node" );
        }

        escape_pod setclientfield( "clientfield_escape_pod_sparks_fx", 0 );
        escape_pod setclientfield( "clientfield_escape_pod_impact_fx", 1 );
        escape_pod setclientfield( "clientfield_escape_pod_light_fx", 1 );
        flag_set( "escape_pod_needs_reset" );
        level waittill( "reset_escape_pod" );
        flag_clear( "escape_pod_needs_reset" );
        escape_pod setclientfield( "clientfield_escape_pod_impact_fx", 0 );
        escape_pod thread maps\mp\zm_highrise_classic::escape_pod_breaking_rotate();
        wait 6;
        escape_pod playsound( "zmb_elevator_run_start" );
        escape_pod playloopsound( "zmb_elevator_run", 1 );
        level notify( "escape_pod_moving_back_to_start_position" );

        if ( isdefined( escape_pod_blocker_door ) ) {
            escape_pod_blocker_door trigger_on();
            escape_pod_blocker_door linkto( escape_pod );
            escape_pod maps\mp\zm_highrise_classic::escape_pod_unlinknodes( "escape_pod_door_l_node" );
            escape_pod maps\mp\zm_highrise_classic::escape_pod_unlinknodes( "escape_pod_door_r_node" );
        }

        escape_pod moveto( escape_pod.home_origin, 3, 0.1, 0.1 );
        escape_pod waittill( "movedone" );
        escape_pod stoploopsound( 1 );
        escape_pod playsound( "zmb_esc_pod_crash" );
        escape_pod playsound( "zmb_elevator_run_stop" );
        escape_pod playsound( "zmb_elevator_ding" );
        escape_pod thread maps\mp\zm_highrise_classic::reset_impact_animate();
        used_at_least_once = 1;
    }
}

give_random_perk_override() {
  random_perk = undefined;
  perks = get_available_random_perks();

  if (perks.size <= 0) {
    self tell("You have ^1all available ^7perks on the map.");
    self playsoundtoplayer(level.zmb_laugh_alias, self);
    return undefined;
  }

  perks = array_randomize(perks);
  random_perk = perks[randomint(perks.size)];

  self maps\mp\zombies\_zm_perks::give_perk(random_perk, 0);

  return random_perk;
}

get_available_random_perks() {
  perks = get_map_random_perks();
  available = [];

  for (i = 0; i < perks.size; i++) {
    perk = perks[i];

    if (!isdefined(perk))
      continue;

    if (isdefined(self.perk_purchased) && self.perk_purchased == perk)
      continue;

    if (self hasperk(perk))
      continue;

    if (self maps\mp\zombies\_zm_perks::has_perk_paused(perk))
      continue;

    available[available.size] = perk;
  }

  return available;
}

get_map_random_perks() {
  switch (level.script) {
    case "zm_highrise":
      return array(
        "specialty_quickrevive",
        "specialty_armorvest",
        "specialty_fastreload",
        "specialty_rof"
      );
  }

  return get_existing_map_perks();
}

get_existing_map_perks() {
  perks = [];
  vending_triggers = getentarray("zombie_vending", "targetname");

  for (i = 0; i < vending_triggers.size; i++) {
    trigger = vending_triggers[i];

    if (!isdefined(trigger))
      continue;

    if (!isdefined(trigger.script_noteworthy))
      continue;

    perk = trigger.script_noteworthy;

    if (perk == "specialty_weapupgrade")
      continue;

    if (!array_contains_perk(perks, perk))
      perks[perks.size] = perk;
  }

  return perks;
}

array_contains_perk(perks, perk) {
  for (i = 0; i < perks.size; i++) {
    if (perks[i] == perk)
      return true;
  }

  return false;
}

leaper_round_accuracy_tracking_override() {
  players = getplayers();
  level.leaper_round_accurate_players = 0;

  for ( i = 0; i < players.size; i++ ) {
    players[i].total_shots_start_leaper_round = players[i] maps\mp\gametypes_zm\_globallogic_score::getpersstat( "total_shots" );
    players[i].total_hits_start_leaper_round = players[i] maps\mp\gametypes_zm\_globallogic_score::getpersstat( "hits" );
  }

  level waittill( "last_leaper_down" );
  players = getplayers();

  for ( i = 0; i < players.size; i++ ) {
    total_shots_end_leaper_round = players[i] maps\mp\gametypes_zm\_globallogic_score::getpersstat( "total_shots" ) - players[i].total_shots_start_leaper_round;
    total_hits_end_leaper_round = players[i] maps\mp\gametypes_zm\_globallogic_score::getpersstat( "hits" ) - players[i].total_hits_start_leaper_round;
    level.leaper_round_accurate_players++;
  }

  if ( level.leaper_round_accurate_players == players.size ) {
    for ( i = 0; i < players.size; i++ )
      players[i] maps\mp\zombies\_zm_score::add_to_player_score( 2000 );

    if ( isdefined( level.last_leaper_origin ) ) {
      trace = groundtrace( level.last_leaper_origin + vectorscale( ( 0, 0, 1 ), 10.0 ), level.last_leaper_origin + vectorscale( ( 0, 0, -1 ), 150.0 ), 0, undefined, 1 );
      power_up_origin = trace["position"];
      level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop( "free_perk", power_up_origin + vectorscale( ( 1, 1, 0 ), 30.0 ) );
    }
  }
}
