# T6 First Room Patch

**A custom First Room challenge framework for Call of Duty: Black Ops II Zombies on Plutonium T6.**

T6 First Room Patch adds a streamlined timer HUD, run-integrity monitoring, network-frame checks, a regular power-up drop tracker, door-purchase restrictions, and a host-only endgame restart prompt. It is designed for players who want to practice and track First Room runs with useful information on screen and fewer interruptions between attempts.

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
| **Integrity monitor** | Reports selected suspicious game settings and player conditions with on-screen alerts. |
| **Animated warnings** | Shows a brief startup indicator and flashing alerts when a violation is reported. |
| **Door-buy restrictions** | Disables standard door and debris purchase triggers so First Room areas stay closed. |
| **Player notification queue** | Spaces out on-screen player messages to help prevent the four-line notification area from overflowing. |
| **Host-only restart** | Offers the local host an endgame restart shortcut with a larger animated HUD. |

## Upcoming Update — Custom Challenge Locations

A future update is planned to introduce **custom challenge locations**, allowing players to play restricted-area challenges beyond a map's default starting room.

For example, players will be able to use locations such as **the Warden's Office on Mob of the Dead**, with additional map-specific areas planned for future support.

This feature is **not available in the current release**. Supported locations and their area restrictions will be documented when the update is released.

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
- A custom patch does **not** automatically qualify a run for competitive leaderboards or official records.

## Development references

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