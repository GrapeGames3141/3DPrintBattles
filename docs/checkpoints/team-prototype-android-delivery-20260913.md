# PrintForge Team prototype — verified Android review delivery

Delivered 2026-09-13 to the established studio Google DriveFS release folder:
`H:\My Drive\AI Projects\PrintForge`. Existing releases were not overwritten.

## Immutable build identity

- Version **0.9.0-team-prototype**, code **108**, launcher **PrintForge**.
- Package `com.tak.printforge.legends.playtest`, arm64 only, portrait, no ads/IAP.
- Runtime source commit `f695faca1bd2ee5df06b6a6d6e6b5f3874667617` on
  `codex/printforge-team-prototype`.
- Configured origin was verified read-only to redirect to the existing private
  `GrapeGames3141/3DPrintBattles` repository; the current account has WRITE access.
  The existing remote branch matched local tracking before the authorized
  fast-forward. Remote `ls-remote` then returned the full source commit above.
- This delivery-only checkpoint does not change the APK's source attribution.

| Artifact | Bytes | SHA-256 |
| --- | --- | --- |
| `PrintForge-Legends-0.9.0-team-prototype-arm64-f695faca1bd2.apk` |287985406|`0923C9A7BB2DADEDD75720026C2E338A28C2CFD7C0393A7EA1CF6D884EE4BC2E`|
| `README-0.9.0-team-prototype-f695faca1bd2.md` |7536|`228139E60D2F703DC5C5F704DDAFF3C3B416C7A54421B5492BB32AEA48CCF8F8`|

Each artifact exists locally under `build/android/` and beside the other review
releases on DriveFS. The delivery skill's non-overwriting copier verified both
source/destination byte counts and SHA-256 values. **Cloud synchronization remains
pending/unconfirmed**; no cloud-visible API/browser observation was available.

## Export and package audit

The clean committed source passed `export_team_android.ps1`. Exact engine PID173376
ran 07:35:56–07:36:49 in isolated E:-based user-data/cache/temp paths. Its ledger at
`build/evidence/team-battle/20260913-073556-35634e8720a9471386e546ffb499a4d5`
records exit0, empty stderr, unchanged QA bytes, no modal window, no forced stop
and no owned survivor. No pointer capture or window-control tool was used.

Independent signed APK audit passed at
`build/evidence/team-release-tooling/20260913-f695faca1bd2-apk-audit/`:

- Compiled default main is `res://scenes/team_prototype.tscn` with
  `team_prototype` feature, not legacy Main.
- Correct package/version/launcher, portrait activity and arm64 payload.
- 16KB ZIP alignment, valid v2/v3 signatures, same review certificate SHA-256
  `c26373b2320fa530be93f5b6d255a4c8e10e6aa4476e430dedb6106a4de865dc`.
- Required compiled Entry, Shell, Battle, Forge, front/rear Voltwig and all other
  facing resources present. Rejected humanoid armor and non-runtime evidence absent.
- 537 non-media entries scanned with no ad identifier hit; all15 executable
  dependencies match the stock Godot template.

## Scope and disclosed limitations

Voltwig's approved cleanup is integrated: genuine front/rear views, transparent
background, safe ear padding, and runtime inward-facing print/awaken/deploy motion.
The release contains the approved playable 3-companion Team /15-card Support Kit
prototype, first-session guarantee, native physical Collection/Battle UI, Back,
automatic Run Cycle, durable Resume and exactly-once results.

[Final source validation](team-prototype-entry-release-validation-20260913.md)
records the clean startup, core, Collection, facing and Battle matrix. It also
preserves one Windows headless allocator crash which did not reproduce in two
fresh serial Win repetitions. Its cause is unknown and it is not claimed fixed.
The release README discloses that limitation. No physical Android device was
available; signing/archive/desktop checks do not certify phone stability or comfort.

## Durable deliverables and complete image indexes

- [Local APK](<E:/AI Projects/games/3d print battler/build/android/PrintForge-Legends-0.9.0-team-prototype-arm64-f695faca1bd2.apk>)
- [DriveFS APK](<H:/My Drive/AI Projects/PrintForge/PrintForge-Legends-0.9.0-team-prototype-arm64-f695faca1bd2.apk>)
- [Release instructions, QA limitations and art links](<E:/AI Projects/games/3d print battler/build/android/README-0.9.0-team-prototype-f695faca1bd2.md>)
- [Battle image review index](team-prototype-native-battle-progress-20260913.md)
- [Collection and earlier art image index](team-prototype-collection-ui-progress-20260913.md)
