# Team prototype — entry and final source validation

2026-09-13. This records source and desktop validation, not a physical Android
device result. Signed APK and DriveFS receipts are produced separately after commit.

## Normal entry

The default scene is `res://scenes/team_prototype.tscn`, owned by the dedicated
`TeamPrototypeEntry` subclass. Tests retain explicit Runtime injection into Shell;
normal entry opens and closes only its own Runtime. The Android feature is
`team_prototype`; engine capability metadata remains `4.7`, `Forward Plus`.
The application data namespace remains **PrintForge Legends**. Android identity is
`com.tak.printforge.legends.playtest`, launcher **PrintForge**, version
**0.9.0-team-prototype**, code **108**, arm64 portrait, without ads or IAP.

Prototype startup selects a quiet read-only loader before legacy normalization.
Missing files and valid empty dictionaries are distinct from malformed JSON.
Present top-level schema values are type/bounds checked before conversion.
Recovered, invalid and future saves enter read-only Recovery. A failed Runtime
open uses presentation-only Recovery, never a fabricated writable Runtime.
No grant, repair, reset, migration or file write occurs during these startup tests.

All evidence directories below are relative to `build/evidence/team-battle/`.
These 13 default-main launches use no scene override and no `--team-prototype`
selector. Each has `TEAM_PROTOTYPE_ENTRY failures=0`, exit 0, empty stderr,
unchanged isolated QA bytes and no owned process survivor. Back/Stay checks invoke
visible native button callbacks; they are not physical-pointer or phone tests.

| Fixture | Expected route | Evidence directory | PID |
| --- | --- | --- | --- |
| Missing | Workshop | `20260913-071038-ceb3dc5e6b3a4fa088bc29a95eac4ede` |176088|
| Empty object | Workshop | `20260913-071042-9c313373fde146158c217bda4e84dc32` |171156|
| Valid Collection | Workshop | `20260913-071046-985709d213634573ba2ae444872b0fe7` |128324|
| Future schema | Recovery | `20260913-071050-176af65958854884b2654a97fd031781` |122864|
| Recovered backup | Recovery | `20260913-071053-0c905a1b71564dd695c5c793b3408924` |175800|
| String schema | Recovery | `20260913-071057-d6de12b9158145868a749d8b08f7059f` |162080|
| Array schema | Recovery | `20260913-071101-d0d274c28d184d70924376a1562c5763` |173224|
| Null schema | Recovery | `20260913-071105-62953121e5e14ca3b8c6811511824958` |160272|
| Zero schema | Recovery | `20260913-071108-fbdec4d4a16e42e091379c04f882bc65` |96208|
| Negative schema | Recovery | `20260913-071112-eb8a962ab8a846f48f3a021d198a86ca` |138552|
| Fractional schema | Recovery | `20260913-071115-11e8aa42f6bb4a998cfa5b01ade35c5a` |168140|
| Huge schema | Recovery | `20260913-071119-78cec1e27afc4a25ac7fcc94d64263a1` |137016|
| Malformed JSON | Recovery | `20260913-071123-13654e41634547d588c0120a20b1a056` |162208|

The initial `071010-5928ffc9f7f84bf8ad754b727a7803d3` parse failure is retained
as rejected evidence. Its duplicate inherited Runtime constant was removed before
the passing matrix; it is not counted as a successful launch.

## Final deterministic and native regressions

| Suite | Assertions / result | Evidence directory |
| --- | --- | --- |
| State |60|`20260913-071153-336655b168ef46a69ce8cb5a3a35f273`|
| Startup invalid deck |60|`20260913-071207-ddf81ed5498046b8ae3c744877d14f03`|
| Startup future schema |60|`20260913-071210-ae9ac4a25763400caf70881ae8f6f3a5`|
| Startup recovered backup |60|`20260913-071213-6066861c41aa4e59bd19ca9d6dba8c29`|
| Startup corrupt backup |60|`20260913-071215-34f717691a214b93b95f175f8feedd61`|
| Battle core |84|`20260913-071230-4a2f5f64ee294eab81e230169ca4a6f9`|
| Bot |40|`20260913-071243-408c797d7fae46b884af91c87d9090f3`|
| Pacing |2279; 45 matches, median16, p95 18, max19|`20260913-071257-e0333cf02d3a4cda977f78d51ebf97c7`|
| Coordinator |70|`20260913-071317-5e345179db3d4790a843334e6f6c3d60`|
| Collection rules |176|`20260913-071359-53c41220f8dd4a419d7df229c5b25e89`|
| Match session |66|`20260913-071416-541022f3594a4e69bd5b51959f8d0f6e`|
| Runtime / Store adapter |66|`20260913-071511-2b8d4b69b2624513a01a909f76aca527`|
| Collection native UI |469|`20260913-072309-c8805528200840fc82087587def60320`|
| Facing cache |All24 species|`20260913-071715-e437e2bdf1374b95a21e017f1155642f`|
| Facing lifecycle |All24, both seats|`20260913-071721-9de15e7ae45a4532aa62d86844545b1e`|
| Battle preflight |6|`20260913-071739-992e05d68d6a4f9e8f86c98d50a3a26b`|
| Battle foundation |40|`20260913-071743-9356a721a4a64c78be17562eae7eaa43`|
| Battle native interactions |32|`20260913-071748-ea79fafbafb34627979b5460ece18a30`|
| Battle playback |10|`20260913-071807-dd6f658a3def4792aa6d4db278ea5b2d`|
| Battle progression |26|`20260913-071810-02c89d2e5d864fbba3c5526b5d2f510b`|
| Battle HOLD |4|`20260913-071829-d9b00305da874c15912a39eb4ea1b112`|
| Battle Draw |8|`20260913-072130-4a5875d2bd4f41819e83d15ef42c99ba`|
| Battle Win repetition1 |12|`20260913-072933-a03ed6ee334748b386e6e19844841311`|
| Battle Win repetition2 |12|`20260913-073036-ebc7dd2b92e249048aa8494f13f06202`|
| Battle Loss |8|`20260913-073217-026087d5bc584cd1b15a9899d7680bea`|

All listed runs have exact suite markers, no test failure, exit 0, empty stderr,
unchanged isolated QA bytes, and no owned survivors. Core/controller tests are
not labeled as pointer input. The final Win repetitions reuse the same clean
`072329-e102d2663a9c4fb288c61b972f7ae111` source; Loss uses clean preparation
`073145-ffc5553c569b499a88a2acc5e2e01495`. All three setup primaries are verified
unchanged by each selected terminal case. Exact final process IDs are170432,
188084 and181892; Loss setup PID181716. The sole writer froze source and handed
engine ownership back to primary after confirming no Godot/WerFault survivors.

### Run isolation correction

The writer accidentally repeated Entry after a metadata-only configuration cleanup;
that second set overlapped the initial Collection UI run `071656`. The original
13 Entry runs remain authoritative, and Collection was repeated serially at
`072309`. A still-running aggregate Battle command also overlapped a separately
started Win follow-up. Win/Loss roots `071911`, `071935`, `071948`, `072008` and
`072021` are retained but excluded from the final serial release matrix. Clean
Battle cases through HOLD and the later `072101` Draw preparation / `072130` Draw
run have non-overlapping recorded lifetimes.

### Known limitation: isolated native Windows failure

A clean serial Win retry `20260913-072404-dd79196e5c95405fbfa4f45344feae4a`
(PID176688) failed with native exit `0xC0000374`, allocator null errors in
`Memory::realloc_static` / `CowData::_realloc_exact`, and a GDScript stack through
Store `_canonical_json` (`JSON.stringify`) during a ledger post-promotion read.
No test marker was emitted. The raw logs, 331,514-byte ledger and process ledger
are retained. The owned process and its recorded crash-report children exited;
the final ledger shows no survivor, no modal window and unchanged isolated QA.

The native-crash skill required diagnosis before another export or speculative
runtime change. Exact engine: Godot4.7.1 `a13da4feb`, Windows x86_64 editor EXE,
SHA-256 `323F9C4CC5DB674E98815CDD8E69DA007D5EFC779ABEDC8C0E42883B7FDEA12A`.
This is not an Android APK crash. There are no native PC addresses/minidump in the
retained output, so additional symbol resolution is unavailable from this stack.
Post-failure host inspection found roughly15GB physical /20GB virtual memory free
and no Godot process. Previous successful Win ledgers exceeded983KB; no file-size
ceiling, bad JSON shape, open-handle error or application race was established.

Primary compared the named allocator with the official
[4.7.1 memory implementation](https://raw.githubusercontent.com/godotengine/godot/4.7.1-stable/core/os/memory.cpp)
and [CowData implementation](https://raw.githubusercontent.com/godotengine/godot/4.7.1-stable/core/templates/cowdata.h).
These identify allocation as the detection site, not the origin of heap corruption.
The known [headless rendering issue](https://github.com/godotengine/godot/issues/121949)
uses multithreaded meshes and different RID failures; this project's current
single-threaded JSON stack does **not** establish that issue as its cause.
No memory limit, engine version, gameplay rule or save logic is changed to mask it.
Two independent serial Win repetitions from the same prepared source passed all
12 assertions, followed by a clean Loss setup and8-assertion selected case. The
allocator error did not recur in those checks. Its cause remains unestablished;
this is a disclosed Windows headless QA limitation, **not** a proven crash fix.
The limited Android review build may proceed with the complete passing final
matrix and this note. No physical Android device was available; phone stability
and performance are not certified.

## Accepted visual and maintenance boundary

See [Battle validation](team-prototype-native-battle-validation-20260913.md),
[Collection validation](team-prototype-collection-ui-validation-20260913.md), and
[first Forge validation](team-prototype-first-forge-validation-20260913.md).
Design and read-only UI reviewers found no remaining release-blocking deviation.
No additional market, multiplayer, ad or catalog expansion is part of this build.
The prototype's four launch companions and five Support types are an intentional
bounded playable loop, not a claim that all historical systems were migrated.
