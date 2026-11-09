#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include scripts\zm\zm_nuked\zm_nuked_util;

#include scripts\zm\_utils;

main() {
  if (tolower(getdvar("mapname")) != "zm_nuked")
    return;

  safe_replacefunc("maps/mp/zm_nuked_perks", "perks_from_the_sky", ::perks_fall_from_sky_override);
  safe_replacefunc("maps/mp/zm_nuked_perks", "init_nuked_perks", ::init_perks_setup_override);
}

init() {
  level notify("magic_door_power_up_grabbed");
}

perks_fall_from_sky_override() {
  level thread maps\mp\zm_nuked_perks::turn_perks_on();

  definitions = get_falling_perk_definitions();
  machines = [];
  triggers = [];

  for (i = 0; i < definitions.size; i++) {
    perk = prepare_falling_perk(definitions[i], 8000);

    if (!isdefined(perk))
      continue;

    machines[machines.size] = perk[0];
    triggers[triggers.size] = perk[1];
  }

  if (machines.size <= 0)
    return;

  level.machines_fallen = 0;
  level waittill("start_of_round");

  for (i = 0; i < machines.size; i++) {
    wait randomintrange(1, 4);
    bring_random_perk(machines, triggers);
  }
}

get_falling_perk_definitions() {
  definitions = [];

  definitions[definitions.size] = array(
    "vending_doubletap", "targetname",
    "vending_doubletap", "target"
  );

  definitions[definitions.size] = array(
    "p6_anim_zm_buildable_pap", "targetname",
    "specialty_weapupgrade", "script_noteworthy"
  );

  definitions[definitions.size] = array(
    "vending_revive", "targetname",
    "vending_revive", "target"
  );

  definitions[definitions.size] = array(
    "vending_sleight", "targetname",
    "vending_sleight", "target"
  );

  definitions[definitions.size] = array(
    "vending_jugg", "targetname",
    "vending_jugg", "target"
  );

  return definitions;
}

prepare_falling_perk(definition, top_height) {
  if (!isdefined(definition) || definition.size < 4)
    return undefined;

  machine = getent(definition[0], definition[1]);
  trigger = getent(definition[2], definition[3]);

  if (!isdefined(machine) || !isdefined(trigger))
    return undefined;

  move_perk(machine, top_height, 5, 0.001);
  trigger trigger_off();

  return array(machine, trigger);
}

bring_random_perk(machines, triggers) {
  if (!isdefined(level.machines_fallen))
    level.machines_fallen = 0;

  index = level.machines_fallen;

  if (
    !isdefined(machines) ||
    !isdefined(triggers) ||
    index < 0 ||
    index >= machines.size ||
    index >= triggers.size
  ) {
    return;
  }

  maps\mp\zm_nuked_perks::bring_perk(machines[index], triggers[index]);
  level.machines_fallen++;
}

init_perks_setup_override() {
  level.perk_arrival_vehicle = getent("perk_arrival_vehicle", "targetname");

  if (isdefined(level.perk_arrival_vehicle))
    level.perk_arrival_vehicle setmodel("tag_origin");

  flag_init("perk_vehicle_bringing_in_perk");
  delete_original_perk_structs();
  setup_nuked_perks();

  level.override_perk_targetname = "zm_perk_machine_override";
  ensure_override_struct_array();

  perk_structs = getstructarray("zm_random_machine", "script_noteworthy");

  if (!isdefined(perk_structs) || perk_structs.size <= 0)
    return;

  locations = randomize_array(array(8, 9, 3, 6));
  count = locations.size;

  if (count > level.nuked_perks.size)
    count = level.nuked_perks.size;

  level.random_perk_structs = [];

  for (i = 0; i < count; i++) {
    perk_struct = setup_random_perk_override(
      perk_structs,
      locations[i],
      level.nuked_perks[i]
    );

    if (!isdefined(perk_struct))
      continue;

    level.random_perk_structs[level.random_perk_structs.size] = perk_struct;
  }
}

delete_original_perk_structs() {
  structs = getstructarray("zm_perk_machine", "targetname");

  if (!isdefined(structs))
    return;

  for (i = 0; i < structs.size; i++) {
    if (isdefined(structs[i]))
      structs[i] structdelete();
  }
}

setup_nuked_perks() {
  level.nuked_perks = [];

  level.nuked_perks[0] = create_nuked_perk(
    "zombie_vending_doubletap2",
    "specialty_rof",
    "doubletap_on"
  );

  level.nuked_perks[1] = create_nuked_perk(
    "p6_anim_zm_buildable_pap",
    "specialty_weapupgrade",
    "Pack_A_Punch_on"
  );

  level.nuked_perks[2] = create_nuked_perk(
    "zombie_vending_revive",
    "specialty_quickrevive",
    "revive_on"
  );

  level.nuked_perks[3] = create_nuked_perk(
    "zombie_vending_sleight",
    "specialty_fastreload",
    "sleight_on"
  );

  level.nuked_perks[4] = create_nuked_perk(
    "zombie_vending_jugg",
    "specialty_armorvest",
    "juggernog_on"
  );
}

create_nuked_perk(model, script_noteworthy, turn_on_notify) {
  perk = spawnstruct();
  perk.model = model;
  perk.script_noteworthy = script_noteworthy;
  perk.turn_on_notify = turn_on_notify;

  return perk;
}

ensure_override_struct_array() {
  if (!isdefined(level.struct_class_names))
    level.struct_class_names = [];

  if (!isdefined(level.struct_class_names["targetname"]))
    level.struct_class_names["targetname"] = [];

  if (
    !isdefined(
      level.struct_class_names["targetname"][level.override_perk_targetname]
    )
  ) {
    level.struct_class_names["targetname"][level.override_perk_targetname] = [];
  }
}

setup_random_perk_override(perk_structs, location, perk) {
  if (
    !isdefined(perk_structs) ||
    !isdefined(perk) ||
    location < 0 ||
    location >= perk_structs.size ||
    !isdefined(perk_structs[location])
  ) {
    return undefined;
  }

  source = perk_structs[location];
  perk_struct = getstruct(source.target, "targetname");

  if (!isdefined(perk_struct))
    return undefined;

  perk_struct.targetname = level.override_perk_targetname;
  perk_struct.model = perk.model;
  perk_struct.blocker_model = getent(perk_struct.target, "targetname");
  perk_struct.script_noteworthy = perk.script_noteworthy;
  perk_struct.turn_on_notify = perk.turn_on_notify;

  index = level.struct_class_names["targetname"][
    level.override_perk_targetname
  ].size;

  level.struct_class_names["targetname"][
    level.override_perk_targetname
  ][index] = perk_struct;

  return perk_struct;
}

randomize_array(values) {
  if (!isdefined(values) || values.size <= 1)
    return values;

  for (i = values.size - 1; i > 0; i--) {
    j = randomint(i + 1);
    temp = values[i];
    values[i] = values[j];
    values[j] = temp;
  }

  return values;
}