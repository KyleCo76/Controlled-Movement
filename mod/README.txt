Controlled Movement 1.4.0

Independent Player, Roach and Swimming controls for The Witcher 3 Remastered
5.0.0.1048522. Install Sharedutils Remastered separately (menu-descriptor API
3.1.1). Both modControlledMovement and modControlledMovement_Menu are required.

Read INSTALL.md, INPUT-INSTALL.md, ROLLBACK.md, CALIBRATION.md and the controller
test plan supplied beside the ZIP. The ZIP contains forty product files plus
this README. The external manifest records every member and its hash.

Kyle accepted preview.2 for release to deliver the Player animation fix and
Swimming controls. This release preserves that exact runtime. Only the two
version tokens and this README differ. Native Player animation is retained;
the owned graph resources cover Horse and Swimming, with no Player graph.

Known accepted issue: leaving idle for a low Swimming pace starts quick then
slows. Native startup remains unchanged. Configurable swim-start speed and
the startup fix are deferred to 1.4.1; neither is implemented in 1.4.0.

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

The unchanged thirteen WitcherScript modules reuse preview.2's independently
qualified SDK serialization/export evidence. That SDK process was terminated
after a teardown hang (exit 1); clean compiler completion is not claimed.
Kyle's preview acceptance is separate from this packaging validation. No new
SDK run, final-archive retail compilation or gameplay test was performed here.
The diagnostic modules retain their earlier labels; identify 1.4.0 by ZIP hash.

Exact package rollback: modControlledMovement-1.4.0-preview-2.zip
SHA-256 2c8e6fab8bba2da11ce0dace4bec7c06d3a79018544ebbb6094b0d612048dd12
Separate pre-Swimming fallback: 1.3.2; follow ROLLBACK.md.

Natural Motion by voidsmith (https://www.nexusmods.com/witcher3/mods/7714) helped
identify Player movement functions. Kyle reports explicit author permission.
It is a development reference, not a dependency. Native code retains
CD PROJEKT S.A. attribution. Sharedutils remains external. Unofficial fan work;
not affiliated with or endorsed by CD PROJEKT RED.
