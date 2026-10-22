Controlled Movement 1.4.1

Independent Player, Roach and Swimming controls for The Witcher 3 Remastered
5.0.0.1048522. Install Sharedutils Remastered separately (menu-descriptor API
3.1.1). Both modControlledMovement and modControlledMovement_Menu are required.

Read INSTALL.md, INPUT-INSTALL.md, ROLLBACK.md, CALIBRATION.md and the controller
test plan supplied beside the ZIP. The ZIP contains forty product files plus
this README. The external manifest records every member and its hash.

New in 1.4.1: starting to swim from a standstill no longer bursts forward at
vanilla speed before settling to a slower pace. The push-off animation now
follows the Swimming value. Two settings on the Swimming Speeds page control it:
Start matches pace (on by default) plays the push-off at the chosen value, and
Swim start speed (0.60 to 2.00, default 1.00) sets a fixed push-off speed when
Start matches pace is off. Player and Roach behavior is unchanged from 1.4.0,
including the native Player animation path.

Replace both ENTIRE owned CM folders on upgrade. Keep the matching Horse/Swim
bundles and index together. Merge the four input.xml declarations into the
existing full input.xml. Merge input.settings.fragment across all six contexts,
preserving custom/unbound CM commands, native WalkToggle and dive controls.
Use the actual Documents location when redirected. No executable setup helper
is included. Installing does not apply a preset.

Player, Roach and Swimming retain independent settings and presets. Swimming
selections range from 0.60 (60) to 2.00 (200); 1.00 (100) is neutral playback,
not a measured physical base speed. Chosen values transfer between land/water
within destination bounds, without a claim of equal physical speed. Native
fast swimming takes temporary priority. Speed after stopping resets the chosen
value after strictly more than one continuously eligible idle second.

Exact package rollback: modControlledMovement-1.4.0-1048522.zip
SHA-256 306a981fb241b6eeca123fe6bafc849e7dd6619c09cf158ad75eb866acdf50fa
Separate pre-Swimming fallback: 1.3.2; follow ROLLBACK.md.

Natural Motion by voidsmith (https://www.nexusmods.com/witcher3/mods/7714) helped
identify Player movement functions. Kyle reports explicit author permission.
It is a development reference, not a dependency. Native code retains
CD PROJEKT S.A. attribution. Sharedutils remains external. Unofficial fan work;
not affiliated with or endorsed by CD PROJEKT RED.
