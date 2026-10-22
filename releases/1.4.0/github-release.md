Native Player animations and a new Swimming profile for Controlled Movement.

### Which file do I need?

**`modControlledMovement-1.4.0-1048522.zip`**: the whole mod. Install it as described in the [README](https://github.com/KyleCo76/Controlled-Movement#installing) or in `INSTALL.md` and `INPUT-INSTALL.md` below. Requires Sharedutils Remastered for hover help. [1.4.1](https://github.com/KyleCo76/Controlled-Movement/releases/tag/v1.4.1) is newer and fixes the swim start.

### In this release

- **Native Player animations.** CM no longer replaces the Player animation graph, which broke turns, releases and sprint. Fine pace control now goes through the game's own movement calculation.
- **Swimming profile** with its own steps, True Steps, favorites, Default preset and a 0.60 to 2.00 range. Fast swimming, startup and damping stay native.
- Known issue, fixed in 1.4.1: a low swim pace started from idle moves quickly at first, then slows.

### Tested

On Windows with keyboard and mouse. Kyle accepted the test build whose game files are identical to this release; Ciri and underwater swimming were not covered. Details in `CALIBRATION.md` and `CONTROLLER-TEST-PLAN.md`; going back in `ROLLBACK.md`.

### Check a download

`Get-FileHash .\modControlledMovement-1.4.0-1048522.zip -Algorithm SHA256` in PowerShell must match its line in `SHA256SUMS`.
