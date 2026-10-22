# Controlled Movement features and settings

This is the full description of what Controlled Movement does for players, as of
1.4.1. The [README](../README.md) and the [Nexus page](https://www.nexusmods.com/witcher3/mods/14233) are shorter versions of it.

Choose your pace on foot, on Roach and in the water. Player pace runs through the native Player graph and motion extraction, so native animations stay intact. Player, Roach and Swimming each have their own settings, and Roach keeps the 1.3.2 Alternate Horse Controls compatibility fix.

Target: The Witcher 3 Remastered build 5.0.0.1048522, keyboard/mouse. Ciri and underwater swimming have not been tested in game yet.

## Install and update

Close the game and back up both CM folders, menu XML and configuration files. Install the release ZIP through a Remastered-compatible mod manager. Enable both `modControlledMovement` and `modControlledMovement_Menu`. Install Sharedutils Remastered and its menu-descriptor module separately; the owned hover adapter targets its 3.1.1 interface.

Replace both **complete** CM folders and `modControlledMovement.xml` together on upgrade. This removes the old CM Player graph and obsolete diagnostic swimming files. Keep the Horse/Swim bundles and their metadata index together. Existing Player/Roach settings, presets and bindings remain; installing does not apply a preset automatically. Swimming adds its own settings. Add only missing input rows, preserving custom and deliberately unbound actions.

The product has two mod folders, twelve loose WitcherScript modules and one compiled hover adapter. There are 80 saved settings, 13 menu leaves, 81 hover registrations, 119 localization entries per language and five presets. Only the Horse and Swim graph overrides remain; there is no CM `pc_gameplay.w2beh` override.

## Fully manual installation

Extract the ZIP and install Sharedutils separately.

- Place both complete folders from `Mods` in `The Witcher 3\Mods`.
- Place `modControlledMovement.xml` from `bin\config\r4game\user_config_matrix\pc` at that same path in the game installation.
- Add the supplied `input.xml` fragment's four `Var` entries to the existing `PCInput/VisibleVars`. Preserve the rest of the game's complete `input.xml`.
- Merge `Mods\modControlledMovement\input.settings.part.txt` into `Documents\The Witcher 3\input.settings`, using the actual redirected Documents location where applicable. Merge into existing sections; do not duplicate them.

The fragment has 26 rows in six contexts: `Exploration`, `Exploration_Replacer_Ciri`, `Horse`, `Horse_Replacer_Ciri`, `Swimming` and `Diving`. Each has the four shared CM commands; Swimming and Diving also have native `WalkToggle`. The repeated `IK_MouseZ` and `IK_None` rows are separate actions. Preserve CM remaps, ToggleSigns, other wheel actions and all native dive controls. An existing remapped or deliberately unbound water WalkToggle stays that way; the supplied Left Ctrl row is a fallback for a missing action.

Upgrading from a complete Player/Roach installation adds eight CM water-context rows and the two native WalkToggle rows only if missing. An older on-foot-only installation also needs the eight Horse-context rows. The four shared keybinding UI declarations stay unchanged. Refresh affected script merges and review resource conflicts.

## Shared controls and independent profiles

Options > Key Bindings exposes four shared CM actions. The modifier pair defaults to wheel up/down, while the direct pair starts unassigned. Require modifier key selects which pair is active. Native Walk/Run supplies the modifier and single/double-tap favorites; its binding carries through to eligible water input. Each adjustment advances once per press. A favorite tap lasts at most 300 ms, with a 300 ms second-tap window. Remap the native action and shared commands rather than adding profile-specific commands.

Player has General, Steps, True Steps, Fluid Controls and Fluid Movement pages; Roach has General, Steps, True Steps and Fluid Movement; Swimming has General, Speeds and True Steps. Controls is shared. Player Default/K apply all 28 Player settings, Roach Default/K apply all 29 Roach settings, and Swimming Default applies its 22 settings. Presets preserve the other profiles, shared modifier and bindings. They update all relevant cached values before the native visible refresh and remain editable afterward.

Player retains its .11–1.49 range, eight editable slots, 3–8 active steps, zero-aligned True Steps, favorites and independent smoothing switches. Player/Roach favorites and active counts now use discrete menu choices without changing their saved identities or preset values. Temporary unavailable-sprint capping limits applied Player pace to 1.00 while preserving the selected destination; recovery uses the latest choice and existing Increase curve/time. New commands and stop resets retain priority. Manual sprint and native restrictions remain authoritative. Native graph, gait, overlay, IK and sprint presentation follow the native path.

Roach retains .40–8.00 requests, ten editable slots, 3–10 active steps, True Steps minimum/maximum, separate starting speed and Charge Increase curve. Values above 6.00 are extreme; 4.00 is the vanilla horse top-speed reference. Genuine starts strictly above 2.50 bypass the Starting and residual-speed ramp for that start, subject to native limits. Lower starts retain Starting when enabled. Ordinary eligible release resets selection only after more than 1.00 second when Stopping is on; renewed movement, newer commands and suspension cancel the pending reset. Explicit Stop and dismount retain their deliberate-stop rules. Physical braking remains native.

Player/Roach keep Linear, Smooth, Build-up and Surge curves; Charge is Roach Increase only. Total uninterrupted transition duration is abs(target-start) * timeMs / 10 seconds. Retargeting uses applied pace and preserves same-direction buildup. Suspension consumes no transition time. Both profiles keep their Default/K preset values; the Nexus page lists them in full.

## Swimming

Swimming uses independent .60–2.00 requests, shown as 60–200. Choose 3–10 active static slots from ten editable values, or True Steps with its own increment, minimum and maximum. Favorites work in both modes. Native fast swimming has temporary priority; releasing it resumes the selected destination. Eligible ordinary water movement uses the shared controls while native vertical/dive input and restrictions remain authoritative.

Swimming Default enables control and True Steps, with eight active slots, favorites 4/8 and Show speed changes off. Its ten slots are .60/.60/.60/.60/.80/1.00/1.25/1.49/2.00/2.00. True Steps uses increment 10, minimum .60 and maximum 1.49. Speed after stopping is .60. Start matches pace is on and Swim start speed is 1.00.

**Speed after stopping** resets the chosen Swimming value after strictly more than one continuously eligible idle second. Native vertical input, movement, newer commands and suspension prevent or cancel the reset. It is a selected-value reset, not a startup control. Swimming keeps native damping, without custom transition curves.

**Swim start.** Starting from a standstill plays a short push-off animation before the swim loop. Since 1.4.1 its playback follows CM too. With **Start matches pace** on (the default), the push-off plays at the chosen Swimming value, so a slow pace starts slow. With it off, **Swim start speed** (.60–2.00, default 1.00, the vanilla push-off) sets a fixed push-off speed whatever the chosen value is. Starting while already moving does not use the push-off. Both settings sit at the end of the Speeds page.

Eligible shore transitions transfer the chosen numeric value between enabled Player and Swimming profiles, clamped to the destination bounds. Newer commands win. Values do not establish equal physical land/water speed. Vanilla swim playback 1.00 (100) is a neutral playback reference, not measured meters per second.

In 1.4.0, starting from idle toward a low Swimming speed moved quickly at first and then slowed, because the push-off always played at vanilla speed. 1.4.1 fixes this with the swim-start settings above.

## Compatibility and rollback

The binary resource conflicts are `gameplay/behaviors/animals/behaviorgraph/horse_draft_exploration.w2beh` and `gameplay/behaviors/pc/behaviorgraph/pc_swimming.w2beh`. Script Merger cannot merge these binary graphs. Keep each matching bundle and metadata together; other replacements need an explicit asset integration.

CM replaces `CR4Player.CanSprint` and `CR4LocomotionPlayerControllerScript.CalculateMoveSpeed`. Other replacements need explicit integration. `W3HorseComponentStateExploration.UpdateLogic` is wrapped: enabled Roach control uses CM's scoped native-based body; disabled Roach control releases only CM-owned state and calls the effective original once. This retains the 1.3.2 AHC compatibility path; use Alternate Horse Controls with Enable Roach control OFF. Simultaneous pace ownership is not established by load order.

Player output remains scoped to eligible Geralt/Ciri exploration; Ciri coverage remains unreported. Roach requires the manually controlled current mount; NPC horses, carts, scripted control and non-simple stamina modes stay native. Scenes, menus, combat actions, airborne movement, vehicles and other scope losses suspend the relevant output. Native restrictions, collisions, stamina, steering, roads, slopes and safety corrections remain authoritative. No actor/world clock, teleport or forced-velocity feature is added.

To roll back, remove both complete current folders before installing the older release's folders and its matching menu XML. 1.3.2 is the last release without Swimming. Keep your saved-setting backup and refresh affected merges.

When reverting to a release without Swimming, remove only CM's four action rows in Swimming/Diving. Remove native WalkToggle only if it was added for CM and you want to undo that addition. An on-foot-only rollback also removes CM's Horse-context rows; keep the Player contexts and four shared UI declarations. For complete removal, remove both folders, menu XML, four CM declarations and CM's four actions in all six contexts. Keep unrelated files, settings and native actions.

## Credit and testing

[Natural Motion by voidsmith](https://www.nexusmods.com/witcher3/mods/7714) helped identify Player movement functions. voidsmith gave explicit permission to use it in developing CM. It is a development reference, not a dependency. Native code retains CD PROJEKT S.A. attribution. Sharedutils remains external.

Each release is tested in game by Kyle; its `test-notes.md` says what was and was not covered.
