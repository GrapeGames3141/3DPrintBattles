# M1 Rules and Bot verified checkpoint

This is a deterministic core checkpoint, not a playable UI or Android release.
M0 approval remains valid. Team/Collection integration and native screen work are
subsequent milestones; the shipped APK has not changed.

## Accepted implementation

- Pure integer Run resolves both opening Plans atomically through Queue, Print,
  Awaken, Enter/Fit, Swap, Spell, AttackLock, Damage, Traits, Defeat, Replace,
  Result and the next Plan when nonterminal. No printer HP or manual turn stack.
- One-use roster identities, FIFO/no carry, finite Support copies, four-card hand,
  target-bound equipment, simultaneous combat and replacement pass exact fixtures.
- Intermediate snapshots preserve the printer chamber/head for animation;
  Result precedes next-Plan replenishment and draw. Only settled states restore.
- A separate projection module uses known nested field schemas to protect the
  rival hand/draw order/seed and reject unknown fields. Public gear is Suit/Gem.
- The bot uses only its checked view, never the seed or the other pending Plan.
  Primary review corrected tactical fallback, highest-priority reserve selection,
  and the known completing-fabrication Surge forecast, with regressions.

## Evidence

All paths below are under `build/evidence/team-battle/` in this E: repository.
Each run has started/process ledgers, clean engine/stdout/stderr logs, isolated
E-based OS user/cache/temp and QA-save roots, byte-unchanged save manifests,
actual exit zero and no task survivors. Primary also checked recorded PIDs after
the runs; no task processes remained and no unrelated process was stopped.

| Suite | Evidence folder | Root PID | Result |
| --- | --- | ---: | --- |
| State independent | `20260912-180522-918d72c69ea84a57b22535ffa6ea7ccd` | 67516 | 60 assertions, 6/6 groups |
| Core independent | `20260912-180456-2305ced2e57743729b4db6f79035eec4` | 47644 | 84 assertions, 7/7 groups |
| Core after Bot changes | `20260912-181620-ff342b02f4f24bdab7c3d2d234c69557` | 66608 | 84 assertions, 7/7 groups |
| Bot independent | `20260912-181713-d14a405132a1450ba77665cb8ac2f1af` | 65036 | 40 assertions, 5/5 groups |
| Pacing independent | `20260912-181737-476076abf81a49b485ffbdf763a67e21` | 119456 | 45/45 completed, 2,279 checks |

Pacing uses the nine ordered starter-team pairings and seeds 0–44. Actual median
is 16 cycles, nearest-rank p95 18, maximum 19. First print/contact medians are both
cycle 1. Across the batch: 161 replacements, 826 Supports, 437 swaps, 10 Draws,
15 player Wins and 20 player Losses. There are no 500-cycle harness stops. These
are descriptive bot-vs-bot measures, not evidence of player enjoyment or a target
pass: the source “12–2” pacing wording remains unresolved.

## Review and next boundary

Primary reviewed source and test assertions, checked the actual logs and reran
the Bot and 45-match harness. Earlier passing simulations did not prevent three
policy mistakes; those were fixed before this acceptance. Independent gameplay
review found no remaining Bot policy/legality blocker. It identified one evidence
gap, not a mechanics failure: replacement counts lack cycle timing. The sole
writer will add per-match replacement cycles for final M1 pacing evidence. No
visual or device pass is claimed.

State owns settled invariants; Rules owns transitions; Projection owns private/
public schema conversion; Bot owns deterministic choices. The next session layer
must not duplicate those mechanics. Its decision-complete interface is
[session plan](team-prototype-m1-session-interface-20260912.md): callback-before-
publication, request deduplication, ordered durable cursor, JSON round-trip restore
without rerunning combat, and projected animation receipts. Coordinator remains
unaccepted until its own tests and review pass.
