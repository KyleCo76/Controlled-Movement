# 1.4.1 rollback

To go back to 1.4.0, remove both CM mod folders and install both folders and
`modControlledMovement.xml` from `modControlledMovement-1.4.0-1048522.zip` in the
[1.4.0 release](https://github.com/KyleCo76/Controlled-Movement/releases/tag/v1.4.0)
(SHA-256 306a981fb241b6eeca123fe6bafc849e7dd6619c09cf158ad75eb866acdf50fa).
`input.xml` and `input.settings` are the same in both versions.

The two 1.4.1 settings (Start matches pace and Swim start speed) stay in your
settings file. 1.4.0 ignores them, and 1.4.1 reads them again if you upgrade
later. 1.4.0 brings back the quick-then-slow swim start from idle.
