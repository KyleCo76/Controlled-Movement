<div align="center">

# Controlled Movement

**Choose your pace on foot, on Roach and in the water, in The Witcher 3 Remastered.**

[![Latest release](https://img.shields.io/github/v/release/KyleCo76/Controlled-Movement?label=release)](https://github.com/KyleCo76/Controlled-Movement/releases/latest)
![The Witcher 3 Remastered 5.01](https://img.shields.io/badge/The%20Witcher%203-Remastered%205.01-8b0000)
![Keyboard and mouse](https://img.shields.io/badge/input-keyboard%20%26%20mouse-555)
[![Licence CC BY-NC 4.0](https://img.shields.io/badge/licence-CC%20BY--NC%204.0-lightgrey)](LICENSE)

[**Download on Nexus Mods**](https://www.nexusmods.com/witcher3/mods/14233) · [**GitHub Releases**](https://github.com/KyleCo76/Controlled-Movement/releases) · [**Every feature and setting**](docs/features.md) · [**Changelog**](CHANGELOG.md) · [**Report a problem**](#reporting-problems)

</div>

---

## What it does

Controlled Movement (CM) lets you pick the pace for the moment: an extra-slow walk for tight interiors, normal walking and running, a faster exploration pace, a gentle trot on Roach or a quieter swim. Hold Walk/Run and scroll to step the pace up or down, or tap Walk/Run to jump to one of two favorites.

- **Three independent profiles:** Player (Geralt and Ciri on foot), Roach and Swimming, each with its own settings and presets, sharing one set of remappable controls.
- **Native animations.** Player pace runs through the game's own movement calculation and animation graph, so turns, stops and sprint look as they do in vanilla.
- **Steps or True Steps.** A ladder of 3 to 10 editable steps, or fine numeric steps with your own increment, minimum and maximum.
- **Fluid Movement** for Player and Roach: smooth speed changes, starts and optional stop resets, with Linear, Smooth, Build-up, Surge and (Roach) Charge curves.
- **Fluid Controls** for Player: optionally enter the game's real sprint state above a pace you choose.
- **Smooth swim starts (1.4.1).** The push-off from a standstill follows your Swimming value, or a fixed Swim start speed of your choice.
- **Presets:** Player Default and K, Roach Default and K, Swimming Default. All editable after applying.

Native rules stay in charge: restrictions, collisions, stamina, sprint rules, scenes, combat and fast swimming all behave as in vanilla. CM never changes the game clock, forces velocity or teleports.

The full description of every setting, input row and limitation is in [docs/features.md](docs/features.md).

## What you need

- **The Witcher 3: Wild Hunt Remastered**, patch **5.01** (build 5.0.0.1048522), PC.
- **Keyboard and mouse.** Gamepad movement is not controlled.
- [**Sharedutils Remastered**](https://www.nexusmods.com/witcher3/mods/12997) with its menu-descriptor module, for the settings' hover help (CM's adapter is built against its 3.1.1 interface).
- Recommended: a Remastered-aware mod manager such as [Relapse's Mod Manager Redux](https://www.nexusmods.com/witcher3/mods/12584) (Remastered 2.2 or newer). Manual install works too.

## Installing

Download `modControlledMovement-<version>.zip` from the [Nexus Mods page](https://www.nexusmods.com/witcher3/mods/14233) or from [Releases](https://github.com/KyleCo76/Controlled-Movement/releases/latest).

**With a mod manager:** close the game, back up your CM folders and settings if you have an older version, install the ZIP and enable **both** modules, `modControlledMovement` and `modControlledMovement_Menu`. Keep your existing bindings when asked. Then check the four CM commands under **Options > Key Bindings**; the no-modifier pair starts unassigned on purpose.

<details>
<summary><b>Manual install</b></summary>

<br/>

Close the game and extract the ZIP. Back up any configuration file before you edit it.

1. **Mod folders:** copy both folders from the ZIP's `Mods` into `The Witcher 3\Mods`.
2. **Settings menu:** copy `bin\config\r4game\user_config_matrix\pc\modControlledMovement.xml` to the same folder in your game.
3. **Key bindings menu:** add the four `Var` lines from the ZIP's `bin\config\r4game\user_config_matrix\pc\input.xml` to the `PCInput` group's `VisibleVars` in the game's own `input.xml` at that path. The ZIP's file is a fragment; keep the rest of the game's file.
4. **Controls:** merge `Mods\modControlledMovement\input.settings.part.txt` into `Documents\The Witcher 3\input.settings` (use the real Documents folder if it is redirected). It has 26 rows in six sections: `Exploration`, `Exploration_Replacer_Ciri`, `Horse`, `Horse_Replacer_Ciri`, `Swimming` and `Diving`. Add the rows to the existing sections instead of duplicating them, keep the repeated `IK_MouseZ` and `IK_None` rows (they are separate actions), and keep your own remaps and cleared bindings.

</details>

<details>
<summary><b>Updating and removing</b></summary>

<br/>

**Updating:** close the game and replace **both complete CM folders and `modControlledMovement.xml` together**. Your saved settings stay; installing never applies a preset. From 1.4.0 to 1.4.1 nothing else changes. From a version before 1.4.0, see the update notes in [docs/features.md](docs/features.md#install-and-update).

**Going back:** each release's `rollback-notes.md` says which earlier ZIP to use. Remove both current CM folders before installing the older ones.

**Removing:** remove both CM folders and `modControlledMovement.xml`, the four CM `Var` lines in `input.xml`, and CM's four action rows in each of the six `input.settings` sections. Keep everything else.

</details>

## Controls

With **Require modifier key** on (the default):

| Input | Action |
| --- | --- |
| Hold Walk/Run (Left Ctrl) + scroll up | Increase pace |
| Hold Walk/Run + scroll down | Decrease pace |
| Quick single tap of Walk/Run | Favorite 1 |
| Quick double tap of Walk/Run | Favorite 2 |

The same commands work on foot, on Roach and in the water. Rebind them under **Options > Key Bindings**; turning the modifier off switches to the separate, unassigned "No-Modifier" pair. Settings are under **Mods > Controlled Movement**.

## Good to know

- **Behavior graph overrides.** CM replaces `horse_draft_exploration.w2beh` (Roach) and `pc_swimming.w2beh` (Swimming). Another mod that replaces either file conflicts, and Script Merger cannot merge them. There is no Player graph override.
- **Script hooks.** CM replaces `CR4Player.CanSprint` and `CR4LocomotionPlayerControllerScript.CalculateMoveSpeed`, and wraps `W3HorseComponentStateExploration.UpdateLogic`. Movement mods that replace the same methods need an explicit merge.
- **Alternate Horse Controls:** works alongside CM with CM's **Enable Roach control** off.
- **Values are requests, not measured speeds.** Player: walk 0.60, run 1.00, sprint 1.50. Roach: 0.40 to 8.00, with 4.00 the vanilla top speed. Swimming: 0.60 to 2.00 animation playback, with 1.00 vanilla.
- **Not tested yet:** Ciri, controllers, Steam Deck and Linux. Reports are welcome.
- **Known issue:** the menu cursor can occasionally stay attached to a slider as you leave the menu and move its value. If your pace changes unexpectedly, reopen the menu and check your values.

## Releases and checking a download

Each version has a [GitHub Release](https://github.com/KyleCo76/Controlled-Movement/releases) with the mod ZIP, `SHA256SUMS`, `test-notes.md` (how it was tested and what was not) and `rollback-notes.md` (going back to the previous version).

To check a download in PowerShell, in the folder with the ZIP:

```powershell
Get-FileHash .\modControlledMovement-1.4.1.zip -Algorithm SHA256
```

The result must equal that file's line in `SHA256SUMS`.

## Repository guide

<details>
<summary><b>What is where</b></summary>

<br/>

| Path | What |
| --- | --- |
| `mod/` | The mod exactly as it ships: the install tree inside each release ZIP |
| `mod/Mods/modControlledMovement/content/scripts/local/controlledMovement/` | CM's twelve WitcherScript modules |
| `mod/Mods/modControlledMovement_Menu/` | The hover-help adapter for Sharedutils, with its compiled `precompiled.rsblob` |
| `mod/bin/config/r4game/user_config_matrix/pc/` | The settings menu and the four key binding declarations |
| `docs/features.md` | Every feature, setting, input row and limitation |
| `releases/<version>/` | The notes published with each GitHub Release |

The behavior graph bundles, menu, string tables and presets are generated by tools in the private working repository, which also holds the game files they are built from. This repository carries their output exactly as shipped.

</details>

<details>
<summary><b>Branches</b></summary>

<br/>

- `main` holds published releases only, one tagged commit per version (`v1.4.0`, `v1.4.1`, ...).
- `develop` is where changes to this repository land; a release is a merge of `develop` into `main`.

</details>

## Reporting problems

Report bugs on the Nexus Mods page's **Bugs** tab, or [open an issue](https://github.com/KyleCo76/Controlled-Movement/issues) here. Please include your CM version, which profile (Player, Roach or Swimming), your preset or edited values, your bindings and modifier setting, other movement, horse, swimming, input or menu mods you use, and the steps that show the problem.

For a detailed log, launch the game with `-debugscripts`, run `CM_PlayerTrace(1)` or `CM_SwimTrace(true)` in the console, and attach the CM lines from `Documents\The Witcher 3\scriptslog.txt`.

## Credits and licence

Made by Kyle with the help of AI tools (ChatGPT and Claude). Kyle directed the work and tests every release in game.

Special thanks to **voidsmith**, author of [Natural Motion (Keys and Scroll Wheel Speed Control)](https://www.nexusmods.com/witcher3/mods/7714). Studying Natural Motion helped find the right movement functions, and voidsmith gave explicit permission to use the mod in developing Controlled Movement. Natural Motion is a credited reference, not a dependency. Please visit voidsmith's page and support that work.

Thanks to Aeltoth and the Sharedutils contributors for the hover-description tools.

Parts of CM's scripts are adapted from the game's own scripts, which remain the work of CD PROJEKT S.A.

**Licence:** [Creative Commons Attribution-NonCommercial 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (CC BY-NC 4.0), full text in [`LICENSE`](LICENSE). Anyone may copy, change and share Controlled Movement, including inside their own free mods, as long as they credit Kyle and do not sell it or use it commercially. The licence covers CM's own work, not the game material it adapts.

This is an unofficial fan work and is not approved or endorsed by CD PROJEKT RED.
