Smooth swim starts for Controlled Movement. Player and Roach are unchanged from [1.4.0](https://github.com/KyleCo76/Controlled-Movement/releases/tag/v1.4.0).

### Which file do I need?

**`modControlledMovement-1.4.1.zip`**: the whole mod. Install it as described in the [README](https://github.com/KyleCo76/Controlled-Movement#installing). Requires Sharedutils Remastered for hover help.

**Upgrading from 1.4.0:** replace both mod folders (`modControlledMovement` and `modControlledMovement_Menu`) and `modControlledMovement.xml`. `input.xml` and `input.settings` need no change, your settings are kept, and the two new settings start at their defaults.

### In this release

- **Smooth swim starts.** The push-off from a standstill now follows your Swimming value, so a slow pace starts slow instead of bursting forward and then slowing down.
- **New Swimming > Speeds settings:** **Start matches pace** (on by default) and **Swim start speed** (0.60 to 2.00, default 1.00, the vanilla push-off) for a fixed push-off while matching is off.
- `CM_SwimTrace(true)` logs the first 1.5 seconds of a start from idle.

### Tested

On Windows with keyboard and mouse, in The Witcher 3 Remastered 5.01. Not tested: Ciri, diving, controllers, Steam Deck, Linux. Details in `test-notes.md`; going back in `rollback-notes.md`.

### Check a download

`Get-FileHash .\modControlledMovement-1.4.1.zip -Algorithm SHA256` in PowerShell must match its line in `SHA256SUMS`.
