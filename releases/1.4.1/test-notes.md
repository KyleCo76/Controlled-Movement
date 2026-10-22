# 1.4.1 test notes

## In game

Kyle installed the 1.4.1 test build (ZIP SHA-256
84ca9f63d6ac7cacfb0545ea551280ec5c52082e50d80eb4687571d78397b00b, the same
bytes as this release) in The Witcher 3 Remastered 5.01 on Windows, keyboard and
mouse, and played it on 2026-10-21. His report: "It feels good."

Not checked in game for this release: the fixed Swim start speed with Start
matches pace off, diving, Ciri, controllers, Steam Deck and Linux.

## Before release

- The hover-help adapter was rebuilt with the REDkit compiler and all thirteen
  script modules compiled with no CM errors.
- The source tests passed: script logic run against a simulated engine, the
  graph edits for all 11 push-off animations, the generated menu and strings,
  and the exact contents of the ZIP. These prove logic and file contents, not
  how the game moves.
