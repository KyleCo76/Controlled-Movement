# Changelog

## 1.4.0 - 2026-10-21

- **Native Player animations.** CM no longer ships its own Player animation graph, which broke turns, releases and sprint. Fine pace control now goes through the game's own movement calculation.
- **Swimming profile.** Its own steps, True Steps, ten slots, favorites, Default preset and a 0.60 to 2.00 range, with a Speed after stopping reset after more than one idle second. Fast swimming, startup and damping stay native.
- Player and Roach favorites and step counts use simple choice lists, without changing saved values.
- Known issue, fixed in 1.4.1: a low swim pace started from idle moves quickly at first, then slows.

## Earlier versions

Versions before 1.4.0 (Player pace control, then Roach in 1.3.0, pace recovery in 1.3.1 and Alternate Horse Controls compatibility in 1.3.2) were released before this repository existed.
