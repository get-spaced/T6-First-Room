#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_perks;
#include scripts\zm\zm_prison\zm_prison_util;

#include scripts\zm\_utils;

main() {
  if (tolower(getdvar("mapname")) != "zm_prison")
    return;

  safe_replacefunc("maps/mp/zm_alcatraz_classic", "afterlife_powerups", ::afterlife_powerups_override);
  safe_replacefunc("maps/mp/zombies/_zm_ai_brutus", "brutus_spawn_prologue", ::warden_spawn_prologue_override);
}

init() {
  level.afterlife_laststand_override = ::start_afterlife_override;

  level thread set_player_lives_mob();
}

set_player_lives_mob() {
  level endon("end_game");

  flag_wait("initial_players_connected");

  for (;;) {
    level waittill("start_of_round");

    if (level.players.size == 1)
      continue;

    foreach (player in level.players) {
      player.lives = 1;
      player playsoundtoplayer( "zmb_afterlife_add", player );
      player setclientfieldtoplayer( "player_lives", player.lives );
    }
  }
}

warden_spawn_prologue_override(spawn_pos) {
  playsoundatposition("zmb_ai_brutus_prespawn", spawn_pos.origin);

  for (i = 5; i > 0; i--) {
    players = get_players();

    foreach (player in players) {
      if (!isdefined(player))
        continue;

      player iprintlnbold("^1WARDEN ^7spawning in ^1" + i);
    }

    wait 1;
  }

  players = get_players();

  foreach (player in players) {
    if (!isdefined(player))
      continue;

    player iprintlnbold("^1WARDEN SPAWNING NOW!");
  }
}

start_afterlife_override(b_electric_chair) {
  if(!isDefined(self.activate_afterlife_after_spawn)) {   
    self.activate_afterlife_after_spawn = 1;
    self.afterlife = 0;
    return;
  }
    
  self.dontspeak = 1;
  self.health = 1000;
  b_has_electric_cherry = 0;
    
  if ( self hasperk( "specialty_grenadepulldeath" ) )
    b_has_electric_cherry = 1;

  if (!flag("afterlife_start_over")) {
    self.afterlife = 0;
    self.dontspeak = 0;
    self.health = self.maxhealth;

    self show();
    self disableafterlife();

    self setclientfieldtoplayer("player_in_afterlife", 0);
    self setclientfield("player_afterlife_fx", 0);
    self setclientfieldtoplayer("clientfield_afterlife_audio", 0);

    if (!isDefined(self.initial_afterlife_freeze_started)) {
      self.initial_afterlife_freeze_started = 1;
      self thread initial_afterlife_freeze();
    }

    return;
  }
    
  self [[ level.afterlife_save_loadout ]]();
  self maps\mp\zombies\_zm_afterlife::afterlife_fake_death();
  
  if ( isDefined( b_electric_chair ) && !b_electric_chair )
    wait 1;
    
  if ( isDefined( b_has_electric_cherry ) && b_has_electric_cherry && isDefined( b_electric_chair ) && !b_electric_chair ) {
    self maps\mp\zombies\_zm_perk_electric_cherry::electric_cherry_laststand();
    wait 2;
  }
    
  self setclientfieldtoplayer( "clientfield_afterlife_audio", 1 );
  
  if ( flag( "afterlife_start_over" ) ) {
    self clientnotify( "al_t" );
    wait 1;
    self thread maps\mp\gametypes_zm\_hud::fadetoblackforxsec( 0, 1, 0.5, 0.5, "white" );
    wait 0.5;
  }
   
  self ghost();
  self.e_afterlife_corpse = self maps\mp\zombies\_zm_afterlife::afterlife_spawn_corpse();
  self thread maps\mp\zombies\_zm_afterlife::afterlife_clean_up_on_disconnect();
  self freezecontrols( 0 );

  self maps\mp\zombies\_zm_afterlife::afterlife_fake_revive();

  self maps\mp\zombies\_zm_afterlife::afterlife_enter();
  self.e_afterlife_corpse setclientfield( "player_corpse_id", self getentitynumber() + 1 );
  wait 0.5;
  self show();

  if ( isDefined( self.hostmigrationcontrolsfrozen ) && !self.hostmigrationcontrolsfrozen )
    self freezecontrols( 0 );
    
  self disableinvulnerability();
  self.e_afterlife_corpse waittill( "player_revived", e_reviver );
  self notify( "player_revived" );
  self seteverhadweaponall( 1 );
  self enableinvulnerability();
  self.afterlife_revived = 1;
  playsoundatposition( "zmb_afterlife_spawn_leave", self.e_afterlife_corpse.origin );
  self maps\mp\zombies\_zm_afterlife::afterlife_leave();
  self thread maps\mp\zombies\_zm_afterlife::afterlife_revive_invincible();
  self playsound( "zmb_afterlife_revived_gasp" );
}

initial_afterlife_freeze() {
  self endon("disconnect");
  level endon("end_game");

  self freezecontrols(1);
  self disableweapons();
  self enableinvulnerability();
  self setvelocity((0, 0, 0));

  flag_wait( "initial_blackscreen_passed" );

  if (!isDefined(self))
    return;

  self freezecontrols(0);

  if (self.sessionstate == "playing")
    self enableweapons();

  self disableinvulnerability();
}

afterlife_powerups_override() {
  return;
}