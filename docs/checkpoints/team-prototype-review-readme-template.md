# PrintForge — Android Team prototype review

Release template only. Do not deliver this file with placeholders; populate from
the signed APK audit and verified transfer evidence after the build is complete.

## Build

- Version: 0.9.0-team-prototype (Android version code108).
- Package: com.tak.printforge.legends.playtest; launcher name PrintForge.
- Architecture: arm64; portrait. No ads, IAP or multiplayer backend integration.
- Source branch: codex/printforge-team-prototype.
- Source commit: [FULL VERIFIED COMMIT].
- APK filename / bytes / SHA-256: [VALUES FROM INDEPENDENT SIGNED APK AUDIT].

Install this APK as an update to the existing signed PrintForge review app. Do not
uninstall or clear app data just to install it. Existing collection fields are kept;
the Team prototype stores its own team, support and battle progress. A damaged,
newer, or recovered-backup save opens the blocking read-only Recovery screen with
Back/Leave; it is not reset or repaired automatically. Android may request permission
to install from the application used to open the APK.

## First session

1. Workshop → Forge. Browse and inspect Cinderpaw, Aquafin or Voltwig, then confirm
   one starter Blueprint. This choice grants one free first-print voucher and two
   guaranteed ready companions; no random pack or grind is required.
2. Start Free Print. The printer reveals raw layers, then the companion awakens and
   joins your collection. Skip shortens presentation without duplicating the grant.
3. Continue to Team. Review the3unique printed companions, their Print Order and the
   recommended15-card Support Kit. Apply explicitly to save it.
4. Workshop → Solo Battle → Start Battle. An active match offers Resume Battle.
   A settled result offers Resume Result; Continue must finish it before New Battle.

## Battle controls

Choose the next companion to fabricate, plus at most one Support card **or** a Ready
companion swap. Equipment asks for an eligible target. Tapping a selected choice
again clears it. The forecast shows available filament, total spend, remaining
filament and next-cycle amount. Run Cycle automatically handles printing, awakening,
entry, the simultaneous attack-or-HOLD beat and reserve replacement. Both sides HOLD
whenever either Active is absent. An empty field may require a legal Run
to replenish filament or advance its queued print; this is not a frozen battle.

Defeat all3opposing companions to win; simultaneous team defeat is a draw. Printers
are not health targets. Each roster member fabricates once per match; permanent
Blueprints, Prints and Support ownership are not destroyed by battle. Result shows
the already-saved reward. Continue finishes that result before a new battle begins.

Visible Back and Android Back close the current sheet first, then return to the
previous screen. Back from Team/Kit or Settings discards an unapplied local draft.
Battle Back preserves the match. Save failures show Retry without applying a second
transaction. Settings supports100%/150% text, high contrast and reduced motion.

## Verification and limitations

Populate this section with the exact final deterministic/native tests, capture
index, startup fixture evidence, package main-scene/feature identity, signing,
arm64/portrait and no-ad checks. Do not substitute old Main screenshots or its APK.

No physical Android device was available for this release check. Desktop native
input/captures and APK archive/signing checks do not prove phone performance,
touch comfort or Android lifecycle behavior. Please report device model, screen,
action and screenshot if a phone-only issue appears.

DriveFS destination: H:\My Drive\AI Projects\PrintForge\[APK FILENAME].
Local/DriveFS byte count and SHA-256: [MATCHED VALUES].
Cloud synchronization: [CONFIRMED CLOUD-VISIBLE EVIDENCE OR PENDING].

## Art and UI review references

Include durable E: links to accepted Voltwig front/rear art, the approved Battle
master and the final current-runtime screenshot index. Earlier rejected inspection
images are indexed in the Collection progress checkpoint and are not release art.
