# T6 First Room Patch

**A custom First Room challenge framework for Call of Duty: Black Ops II Zombies on Plutonium T6.**

T6 First Room Patch adds a streamlined timer HUD, run-integrity monitoring, network-frame checks, a regular power-up drop tracker, an integrated zombie counter, map-specific changes for Origins, Mob of the Dead, Nuketown Zombies and Die Rise, door-purchase restrictions, buildable removal (except on Origins), full disabling of persistent upgrades (perma-perks), and a host-only endgame restart prompt. It is designed for players who want to practice and track First Room runs with useful information on screen and fewer interruptions between attempts.

> [!IMPORTANT]
> This is an independent community project and a **work in progress**. It is **not** the official B2FR patch, is not affiliated with Plutonium, and should not be assumed to meet any leaderboard or world-record submission rules.

## Features

| Feature | Description |
| --- | --- |
| **Game timer** | Tracks elapsed time from the beginning of the run. |
| **Round timer** | Resets each round and records the elapsed round time. |
| **Split timer** | Displays the latest completed-round split and its round number. |
| **Colored timer HUD** | Compact `GAME`, `ROUND`, and `SPLIT` labels at the top-left of the screen. |
| **Network-frame verification** | Checks for a 100 ms solo or 50 ms co-op frame and reports the measured value each round. |
| **Power-up drop monitor** | Reports regular power-up pickups, remaining round drops, and the remaining randomized power-up cycle through each player's notification queue. |
| **Integrated zombie counter** | Zombie-counting functionality from [T6 Zombie Counters](https://github.com/get-spaced/T6-Zombie-Counters) is built into the existing patch files; no separate counter script is required. |
| **Origins headshot tracker** | On Origins, shows progress toward 115 headshots and displays the Mystery Box reward prompt when the goal is reached. |
| **Origins challenge setup** | On Origins, sets the zone-capture and points-spent challenge stats, with in-session handling for completed headshot goals when a player reconnects. |
| **Mob of the Dead — co-op lives** | On Mob of the Dead, resets each player to one Afterlife life at the start of each round when more than one player is present. |
| **Mob of the Dead — Warden warning** | Adds a five-second on-screen Warden spawn countdown and announcement. |
| **Mob of the Dead — Afterlife changes** | Overrides parts of Afterlife startup/revival and disables the original `afterlife_powerups()` routine. |
| **Nuketown Zombies — perk drops** | Customizes falling perk-machine behavior, with a **Double Tap II + Pack-a-Punch-only** setup intended for the release. |
| **Die Rise — restricted perks** | Limits the map-specific random-perk pool to Juggernog, Speed Cola, Double Tap II and Quick Revive. |
| **Die Rise — elevator behavior** | Changes the escape-pod/elevator script so it does not proceed with its travel sequence while players occupy it. |
| **Die Rise — leaper rewards** | Removes the shot-accuracy requirement from the special leaper-round reward logic. |
| **Buildable removal** | Removes buildables on supported maps **except Origins** (`zm_tomb`). |
| **Perma-perk disabling** | Disables all persistent upgrades (perma-perks), including their effects and the ability to earn, acquire, or lose them. |
| **Integrity monitor** | Reports selected suspicious game settings and player conditions with on-screen alerts. |
| **Animated warnings** | Shows a brief startup indicator and flashing alerts when a violation is reported. |
| **Door-buy restrictions** | Disables standard door and debris purchase triggers so First Room areas stay closed. |
| **Player notification queue** | Spaces out on-screen player messages to help prevent the four-line notification area from overflowing. |
| **Host-only restart** | Offers the local host an endgame restart shortcut with a larger animated HUD. |

## Upcoming Update — Custom Challenge Locations

A future update is planned to introduce **custom challenge locations**, allowing players to take on restricted-area challenges beyond a map's default starting room.

Planned examples include:

- **Warden's Office** — Mob of the Dead.
- **Diner** — TranZit.
- **Yellow House** — Nuketown Zombies.
- **Additional locations** — more map-specific challenge areas to be added over time.

These are **planned examples, not currently supported locations**. The final list of maps, areas, and their boundaries will be documented as each location becomes available.

## Timer HUD

The timer HUD is displayed in the **top-left corner**:

```text
GAME    00:24:37
ROUND   00:01:42
SPLIT   R15 - 00:22:18
```

- **GAME** — total elapsed game time, starting with the first round.
- **ROUND** — time elapsed in the current round; the finished round's duration is retained until the next round begins.
- **SPLIT** — total game time recorded when the most recent round ends.

The labels use distinct colors for quick recognition while the time values remain easy to read. These are in-game timers, not a guarantee of compatibility with official speedrun timing rules.

## Integrated zombie counter

The zombie counter from my [T6 Zombie Counters](https://github.com/get-spaced/T6-Zombie-Counters) project has been **merged into the existing First Room Patch source files**. It is part of the patch, not an extra script that users need to install.

- **Included with the patch:** There is **no separate `_zmcounter.gsc` file** in this project's file set.
- **Original implementation (reference only):** [T6 Zombie Counters source on GitHub](https://github.com/get-spaced/T6-Zombie-Counters/blob/main/_zmcounter.gsc).

The integrated zombie counter is an **existing feature**. The custom challenge locations described above are planned for a future update.

## Origins challenge features

The patch also includes map-specific challenge behavior for **Origins** (`zm_tomb`). These features run **only on Origins** and are initialized for each player when they connect.

### Headshot challenge HUD

- Displays an individual **headshot-progress counter** near the top-center of the screen.
- Reads progress from Origins' built-in `zc_headshots` challenge, targeting **115 headshots**.
- Updates the display approximately every **0.1 seconds** as the challenge value changes.
- On reaching the goal, shows **"Claim your free weapon at the box!"** for about **10 seconds**, then removes the message.

Example displays:

```text
Headshots: 72/115
```

```text
Claim your free weapon at the box!
```

### Origins challenge initialization

Once Origins' challenge data becomes available, the script sets these per-player challenge stats:

| Challenge stat | Value set |
| --- | ---: |
| `zc_zone_captures` | `6` |
| `zc_points_spent` | `30000` |

These are **challenge-stat updates**; the script is not physically activating generators or deducting 30,000 points from a player's balance.

### Completion and reconnect handling

- Records a completed 115-headshot goal against the player's GUID **for the current game session**.
- If that player reconnects during the same session after completing the goal, the script restores the completed headshot value and marks the corresponding reward as claimed, including the character-specific rewarded flag when available.
- Prevents the headshot-progress HUD from restarting for a player already marked complete in that session.

> [!NOTE]
> The provided code **displays a free-weapon message** and changes Origins challenge/reward flags; it does **not** itself contain a separate function that grants a weapon. The completion tracking shown here uses `level.completed_headshot_guids`, which is **session-scoped**, not a persistent cross-game save.

## Mob of the Dead features

The patch also includes **Mob of the Dead** (`zm_prison`) changes covering co-op Afterlife lives, Warden announcements, and selected Afterlife behaviors. These are **existing map-specific changes**, not part of the planned custom-location update.

### Co-op Afterlife lives

- At the start of each round, checks how many players are connected.
- **Co-op (2 or more players):** sets each player's `lives` value to **1**, plays the Afterlife-add sound, and updates the `player_lives` client field.
- **Solo:** skips the round-start lives reset.

This changes the round-start life allowance in co-op; it does not implement a general life-saving or persistent-life system.

### Warden spawn countdown

The patch replaces the Warden/Brutus prologue callback with a visible countdown for connected players:

```text
WARDEN spawning in 5
WARDEN spawning in 4
WARDEN spawning in 3
WARDEN spawning in 2
WARDEN spawning in 1
WARDEN SPAWNING NOW!
```

- Plays the Warden pre-spawn sound at the supplied spawn position.
- Displays a **five-second bold on-screen countdown** to each connected player.
- Displays **WARDEN SPAWNING NOW!** after the countdown.

> [!NOTE]
> The provided override handles **pre-spawn sound and announcements**. The function shown does not itself create or spawn a Warden; the actual spawn behavior depends on the surrounding map scripts.

### Afterlife flow adjustments

The patch assigns a custom Afterlife start handler (`level.afterlife_laststand_override`) and replaces the map's `afterlife_powerups()` function with a no-op.

- **Initial activation:** records a first-use flag and prevents the custom handler from immediately entering the regular Afterlife sequence.
- **Before `afterlife_start_over` is set:** clears Afterlife state, restores normal health and visibility, disables Afterlife, and starts the `initial_afterlife_freeze()` helper once per player.
- **When `afterlife_start_over` is set:** uses the existing Afterlife functions for loadout restoration, fake death, corpse creation, entry, revival, visual/audio effects, and post-revival invulnerability.
- **Afterlife power-up routine:** the replacement for `afterlife_powerups()` immediately returns, suppressing that original routine's behavior.

> [!IMPORTANT]
> In the provided source, `main()` restricts the function replacements to `zm_prison`, but `init()` does **not** contain its own map-name check. Ensure this map-specific `init()` is only called on Mob of the Dead (or add the same map guard), so it does not assign the Afterlife override on unrelated maps. The custom flow also relies on helpers and map flags from the rest of the patch.

## Nuketown Zombies features

The optional **Nuketown Zombies** (`zm_nuked`) adjustments customize how the map initializes and drops perk machines.

### Falling perk-machine setup

- Replaces the map's `perks_from_the_sky()` and `init_nuked_perks()` routines.
- Prepares the selected perk-machine models high above the map, disables their purchase triggers until they arrive, and brings them down after a round starts with short randomized delays.
- Rebuilds the map's randomized perk-machine location data, including the Pack-a-Punch machine.
- **Intended release behavior:** only **Double Tap II** and **Pack-a-Punch** fall into the map. Other machines should not be part of the falling-machine selection.

> [!IMPORTANT]
> The supplied `get_falling_perk_definitions()` code still defines **five** machines: Double Tap II, Pack-a-Punch, Quick Revive, Speed Cola and Juggernog. As written, that function does **not** enforce the two-machine-only description above. Before releasing, restrict the definition and initialization logic to the two intended machines. This README describes the requested setup, not a guarantee that the pasted code already enforces it.

## Die Rise features

The optional **Die Rise** (`zm_highrise`) adjustments affect random perk rewards, the escape-pod/elevator sequence, and leaper-round rewards.

### Restricted random-perk pool

Random perk rewards are selected from these **four perks only**:

| Available perk | Internal identifier |
| --- | --- |
| **Juggernog** | `specialty_armorvest` |
| **Speed Cola** | `specialty_fastreload` |
| **Double Tap II** | `specialty_rof` |
| **Quick Revive** | `specialty_quickrevive` |

The override skips perks the player already has or that are otherwise unavailable. If no eligible perk remains, it tells the player that all available perks are owned.

### Elevator movement restriction

The custom `escape_pod()` logic checks whether living players are inside the escape pod. The supplied loop **does not advance to the movement sequence while players are detected inside**, preventing occupied elevator travel in this implementation.

> [!NOTE]
> The provided `escape_pod_override()` contains a continuous inner loop with no exit to the travel code. This achieves the occupied-elevator restriction but may also prevent normal elevator travel altogether. Test the intended map progression before using this override in a public release.

### Leaper-round reward without an accuracy requirement

- The leaper-round override records player shot/hit counts but **does not compare them to determine eligibility**.
- When the last leaper is defeated, it awards **2,000 points** to each counted player.
- It also attempts to spawn a **free perk** near the last leaper's position when `level.last_leaper_origin` is available.
- **Missing shots does not disqualify players** from the bonus in this implementation.

## Buildable removal

The patch is configured to **remove buildables across the maps, with Origins (`zm_tomb`) as the exception**. Origins buildables remain available. This is a core gameplay restriction separate from the optional map-specific perk, Afterlife and challenge adjustments.

> [!NOTE]
> The buildable-removal implementation was not included in the code excerpts used for this README update. Verify its behavior on each supported map, particularly where a map relies on a buildable for progression.

## Persistent upgrades (perma-perks)

The patch **fully disables all persistent upgrades (commonly called perma-perks)**. Players cannot gain or unlock them, lose them through gameplay, or benefit from their effects while the patch is active.

This restriction is separate from the normal perk-machine system (for example, Juggernog or Speed Cola) and from the optional map-specific changes. It is part of the **core First Room Patch** and remains in effect even when the optional map folders are not installed.

## Network-frame verification

The network checker runs once per round and displays a **GOOD** or **BAD** result for the measured frame length:

| Players | Expected frame |
| --- | --- |
| 1 | **100 ms** |
| 2 or more | **50 ms** |

Example messages:

```text
Network frame: 100ms (GOOD)
Network frame: 50ms (GOOD)
Network frame: 100ms (expected: 50ms) (BAD)
```

The check uses exact millisecond comparisons. Individual measurements can be affected by timing variation; a BAD reading is not, by itself, proof of cheating.

## Power-up drop monitor

The **power-up monitor** provides a short notification whenever a player collects a **regular round power-up**. It uses the existing per-player `queue_print_client()` system, so **it does not add another HUD panel**. Notifications are sent to all connected players through their individual queues.

Example notifications:

```text
[POWERUP] Max Ammo | Drops left: 3/4
[CYCLE] Nuke, Insta-Kill, Double Points
```

### How the drop count works

- **Four regular drops per round** is the normal limit. The monitor reads `level.zombie_vars["zombie_powerup_drop_max_per_round"]` when available rather than assuming every configuration uses four.
- A regular drop uses up its allowance **when it spawns**, not when someone collects it. Picking it up displays the remaining count; it does **not** deduct another drop.
- The counter resets with the game's round-drop logic. An uncollected or expired regular drop can still use up one of the four allowances.
- Boss rewards and scripted power-ups created through `specific_powerup_drop()` are intended to be **excluded**; they don't increment the usual regular-drop counter.
- The **CYCLE** message lists eligible power-ups remaining in the current randomized power-up selection cycle. It is not a prediction of guaranteed future drops and may change with map-specific conditions.

### Example

After a regular **Max Ammo** is collected, the queue might show:

```text
[POWERUP] Max Ammo | Drops left: 3/4
[CYCLE] Nuke, Insta-Kill, Double Points
```

If three other regular drops have already spawned this round, the display instead shows **0/4**, even if one or more power-ups are still sitting on the map.

### Enabling the monitor

If you are integrating the monitor source into a custom GSC entry point, initialize it once during startup:

```c
level thread init_powerup_monitor();
```

The monitor requires the `init_powerup_monitor()` functions to be included in your build, alongside the existing `queue_print_client()` helper. If using a packaged release, check whether the release includes the module and has it enabled.

> [!NOTE]
> The event-based version associates pickup entities with changes in the regular drop counter. If a scripted/boss drop and a regular drop spawn almost simultaneously, it may associate the wrong pickup with the counter increase. Custom boss scripts that call the standard regular `powerup_drop()` function may also count toward the round limit. These cases need an explicit spawn-source hook for guaranteed exclusion. **Test the behavior on each map before relying on it for competitive runs.**

## Run-integrity monitor

The monitor is intended to make suspicious or altered game conditions visible during a First Room run.

### Built-in checks

Depending on the version of the script being used, these include:

- **Cheats enabled** — checks whether `sv_cheats` is enabled.
- **Movement settings** — watches for a change in `g_speed` after initialization.
- **Gravity settings** — watches for a change in `g_gravity` after initialization.
- **Abnormal health** — reports health that exceeds the script's configured safety rules.
- **God Mode script flags** — recognizes God Mode when another cooperating script sets a supported flag.

### Additional integration points

The framework also provides reporting hooks for **Mystery Box manipulation**, **door openings**, **NoClip**, and other custom rules. These events require the relevant detection code or map-specific hooks to be connected; they are **not all automatically detected** by the simplified monitor.

### HUD alerts

At startup, **INTEGRITY MONITOR ACTIVE** briefly flashes in green and fades away after approximately five seconds. When a violation is reported:

1. The status changes to **RUN INVALIDATED**.
2. A large warning identifies the reported issue.
3. The warning flashes and fades; the invalid-run status remains visible.
4. Repeated reports with the same identifier are suppressed to reduce spam.

The monitor is a diagnostic aid and can produce false positives if other mods intentionally change gameplay values. It does not reliably detect every engine-level cheat.

## First Room restrictions

The door restriction feature attempts to disable standard **door** and **debris** purchase triggers while leaving the physical doors and barriers in place. That makes it easier to practice without accidentally opening a standard purchasable route.

The patch also removes **buildable objects on maps other than Origins**, as described in [Buildable removal](#buildable-removal).

> [!NOTE]
> Some maps use custom doors, switches, scripted paths, or triggers that can be created or re-enabled later. Those may need additional map-specific restrictions. Test each map before relying on it for a restricted run.

## Endgame restart

In a **local or private hosted game**, only the host receives the restart prompt on the game-over screen. Other players do not see it or gain the restart shortcut.

```text
FIRST ROOM / HOST CONTROL

RESTART AVAILABLE

AIM + MELEE
PRESS BOTH TO RESTART THE GAME
```

- **Shortcut:** Hold **AIM + MELEE** together (default PC controls may vary).
- **Availability:** Approximately **17 seconds** after the prompt appears.
- **Visuals:** Large text, a dark panel, turquoise accent, and a subtle pulse animation.
- **Action:** Attempts to restart the current map with `map_restart`.
- **Dedicated servers:** The host-only prompt is disabled; **there is no restart vote in this version**.

> [!WARNING]
> Game-over screens may suppress normal gameplay-button input, depending on the game state. If the combo does not register, the host can use Plutonium's console command `map_restart` or configure a local keybind such as `bind P "map_restart"`.

## Installation

### Requirements

- Call of Duty: Black Ops II Zombies running through **Plutonium T6**.
- The project's `.gsc` script file(s), downloaded from the repository or its releases.
- A private game or server where you are allowed to load custom GSC scripts.

### Install as a Zombies script (Windows)

1. Download the `.gsc` file(s) included with the project.
2. Press `Win + R` and open:

   ```text
   %localappdata%\Plutonium\storage\t6\scripts\zm
   ```

3. Create the `scripts` or `zm` directories if they do not exist.
4. Place the GSC file(s) in the `zm` directory, preserving any included subfolder structure.
5. Start Plutonium T6 Zombies and launch a new game.

### Optional map folders — core-only installation

The map-specific folders are **optional**. If you want the standard First Room Patch **without the additional per-map changes**, leave those map folders out of your installation and keep the required shared/core patch files.

| Optional map folder / map | Additional features omitted if not installed |
| --- | --- |
| **Origins** (`zm_tomb`) | Headshot HUD, challenge-stat presets and session completion handling |
| **Mob of the Dead** (`zm_prison`) | Co-op Afterlife life reset, Warden countdown and Afterlife overrides |
| **Nuketown Zombies** (`zm_nuked`) | Falling-perk machine and perk-location overrides |
| **Die Rise** (`zm_highrise`) | Restricted random perks, escape-pod/elevator behavior and leaper-round reward changes |

**Leaving out the optional map folders is supported as a core-only setup**; you do not need the extra map features to use the regular patch. Preserve any shared utilities or files explicitly required by the main patch. Follow the actual folder layout of the release rather than treating the map IDs in the table as guaranteed on-disk directory names.

The core patch's buildable restrictions and **perma-perk disabling** are separate from these optional map scripts; **Origins remains the exception** to buildable removal.

Plutonium supports loading source and compiled GSC scripts from its script directories. If you update a file, start a new game or restart the map to reload the script:

```text
map_restart
```

For official installation details, see [Plutonium — Loading Mods](https://plutonium.pw/docs/modding/loading-mods/).

### Using a selectable mod

If the project is distributed as a full selectable mod rather than loose `.gsc` scripts, follow the folder layout in that release. Do not combine different installation layouts unless the release explicitly supports it.

## Configuration and customization

The project is written in **GSC**, using **2-space indentation**. Its settings are currently adjusted in the source code rather than through a configuration menu.

Common customization points include:

| Setting | Default / behavior |
| --- | --- |
| Timer position | Top-left |
| Timer labels | `GAME`, `ROUND`, `SPLIT` |
| Solo network frame | 100 ms |
| Co-op network frame | 50 ms |
| Network checks | Once per round |
| Integrity monitor startup | Flashes green, then fades after ~5 seconds |
| Restart shortcut | AIM + MELEE |
| Host restart window | 17 seconds |
| Restart availability | Local host only |
| Message queue | Per-player, with spaced notifications |
| Power-up monitor output | Two queued messages on a regular power-up pickup; no custom HUD |
| Regular drop limit | Normally 4 per round; reads the map's configured limit when available |
| Boss/scripted drops | Excluded when using the stock scripted power-up spawning path |
| Origins headshot target | 115 headshots (`zc_headshots`) |
| Origins preset challenge stats | 6 zone captures and 30,000 points spent |
| Origins challenge map | `zm_tomb` only |
| Mob of the Dead changes | `zm_prison` (map-specific) |
| Mob co-op round-start Afterlife lives | 1 per player when 2+ players are present |
| Warden warning | 5-second countdown, then spawn announcement |
| Mob Afterlife power-up routine | Replaced with an immediate return |
| Nuketown map | `zm_nuked` (optional map-specific changes) |
| Nuketown falling machines | Intended: Double Tap II and Pack-a-Punch only; check machine definitions before release |
| Die Rise map | `zm_highrise` (optional map-specific changes) |
| Die Rise random-perk pool | Juggernog, Speed Cola, Double Tap II, Quick Revive |
| Die Rise escape pod | Occupied travel inhibited by the supplied override |
| Die Rise leaper bonus | Shot accuracy not checked; 2,000 points and conditional free-perk drop |
| Buildable removal | All maps except Origins (`zm_tomb`) |
| Persistent upgrades (perma-perks) | All disabled: effects, earning/unlocking, and loss/removal through gameplay |
| Optional map folders | May be omitted for a core-only install |

If you are editing the source, make changes carefully: HUD layouts, player flags, map events, and the available GSC functions can vary by map or by game state.

## Troubleshooting

**The script doesn't load**

- Check that the file really ends in `.gsc`, not `.gsc.txt`.
- Confirm it is in the correct Plutonium T6 `scripts\zm` directory.
- Verify the script has an `init()` or `main()` entry point, or that its functions are called by another entry-point script.
- Start a new game after replacing script files.

**The timer text doesn't appear**

- Ensure timer initialization runs before the match begins.
- Check whether another HUD script is covering or replacing the same screen area.
- Verify HUD elements and labels are created successfully.

**Network frames show BAD in co-op**

- Check the actual player count and measured frame length.
- Confirm the current script compares co-op against **50 ms**, not a previously set framework value.
- Remember that a single measurement can fluctuate.

**Power-up messages don't appear**

- Confirm the power-up monitor functions are included in the loaded script and `init_powerup_monitor()` is called once.
- Confirm `queue_print_client()` is available and the player message queue isn't backed up with earlier messages.
- Only regular-drop pickups are intended to trigger messages; scripted rewards may be excluded.
- Check whether another mod replaces the stock drop/pickup handling or introduces custom power-up entities.

**Power-up drop counts look wrong**

- Remember that the four-drop allowance is consumed on **spawn**, not on pickup.
- Check whether other scripts alter `zombie_powerup_drop_max_per_round` or use the regular drop function for boss rewards.
- Simultaneous regular and special spawns can confuse the event-based association; a spawn-source hook is needed for exact classification.

**The Origins headshot HUD doesn't appear**

- Check that you are playing **Origins** (`zm_tomb`); the feature deliberately does not run on other maps.
- Ensure the map's challenge system has initialized and `zc_headshots` exists.
- A player already marked as complete in the current session will not see the progress HUD again after reconnecting.

**Mob of the Dead lives or Warden countdown do not appear**

- Confirm the map is **Mob of the Dead** (`zm_prison`).
- Check that the map-specific hooks and the `init()` function are actually loaded and called.
- The lives change runs **only in co-op**, at the start of each round; it is intentionally skipped in solo.
- Check whether another script replaces the same Brutus or Afterlife callbacks.

**Nuketown shows more than Double Tap and Pack-a-Punch falling**

- Check the `get_falling_perk_definitions()` array and `setup_nuked_perks()` mapping. The supplied example lists five machines, so it must be adjusted to match the intended two-machine setup.
- Ensure the Nuketown map-specific script is included only when those gameplay overrides are desired.

**Die Rise elevator or leaper rewards behave unexpectedly**

- Confirm the `zm_highrise` map-specific override is installed and its function replacements initialize on the correct map.
- The pasted elevator override loops while monitoring occupancy and may block movement rather than merely delay it.
- The free-perk drop after the leaper round requires a valid last-leaper position; the points reward is not tied to shot accuracy.

**Map-specific changes are unwanted**

- Omit the optional map folders and use only the required core files as described under [Optional map folders](#optional-map-folders--core-only-installation).
- Do not remove shared utility files that the core patch depends on.

**The restart HUD appears, but the shortcut doesn't work**

- Confirm you are the **local host**, not a dedicated-server client.
- The game-over sequence may stop reporting normal button input.
- Try `map_restart` in the host's console to distinguish an input issue from a restart issue.

**A violation appears incorrectly**

- Check for conflicting mods that change health, speed, gravity, or weapon availability.
- Revisit map-specific exceptions and any custom detection hooks.
- Treat warnings as diagnostic until the condition is independently confirmed.

## Compatibility and known limitations

- Intended for **Plutonium T6 Zombies**; not tested for every map, game mode, or other mod combination.
- Standard door restrictions may not cover every custom map interaction.
- The simplified integrity monitor does not detect all cheats or all Mystery Box changes automatically.
- The event-based power-up monitor can misattribute simultaneous regular and scripted drops and should be tested before relying on its classification.
- The endgame restart shortcut depends on gameplay input being available after game over.
- Some HUD elements may overlap with other scripts that use the same screen positions.
- Origins-specific challenge changes apply only on `zm_tomb`. The shown completion flags are session-scoped, and the free-weapon message does not itself grant a weapon.
- Mob of the Dead hooks target `zm_prison`. The supplied `init()` must be called only for that map, because it has no internal map check.
- Mob Afterlife overrides replace existing map routines and may conflict with other scripts that patch Brutus, life counts, or Afterlife handling. Test solo and co-op separately.
- Nuketown (`zm_nuked`) function replacements affect perk-machine initialization. The pasted machine-definition list must be reduced if the release should drop only Double Tap II and Pack-a-Punch.
- Die Rise (`zm_highrise`) changes affect random-perk selection and replace the escape-pod and leaper-round logic; the supplied occupied-pod loop can stop the elevator from completing normal travel.
- Die Rise free-perk spawning after a leaper round depends on a known final leaper position, even though missed shots do not prevent the reward calculation.
- Optional map folders may be omitted for a core-only installation; all shared script dependencies must still be present.
- Buildable removal is intended to apply everywhere except Origins. Test map progression with buildables disabled.
- All persistent upgrades (perma-perks) are intended to be disabled, including gaining, losing, and using their effects. This does not disable ordinary purchasable perks.
- A custom patch does **not** automatically qualify a run for competitive leaderboards or official records.

## Development references

- [T6 Zombie Counters — original counter implementation (reference only)](https://github.com/get-spaced/T6-Zombie-Counters/blob/main/_zmcounter.gsc)
- [Plutonium T6 script sources](https://github.com/plutoniummod/t6-scripts)
- [Plutonium mod-loading documentation](https://plutonium.pw/docs/modding/loading-mods/)
- [Plutonium GSC scripting features](https://plutonium.pw/docs/modding/gsc/new-scripting-features/)

This project draws on publicly available T6 scripting resources and First Room gameplay concepts. It is independently developed and is **not an official B2FR release**.

## Feedback and contributions

Bug reports, map-specific findings, and suggestions are welcome through GitHub Issues. When reporting a problem, include the **map**, **solo or co-op player count**, **Plutonium version**, any **other installed scripts**, and the steps needed to reproduce it.

## Disclaimer

This is an unofficial community modification for personal and private-server use. **Call of Duty**, **Black Ops II**, and related trademarks belong to their respective owners. **Plutonium** and **B2FR** are separate projects and are not responsible for this mod.

---

**Built for First Room practice, clearer run feedback, and faster retries.**
