# PrintForge: original vision × current game

Date: 2026-09-08

Status: **PROPOSAL ONLY — not an approved implementation plan**

## Recommendation

**Keep the current steampunk workshop and dependable game systems. Restore the original emphasis on collecting, printing, and caring about a small team of living creatures. Simplify the battle around that team instead of expanding the current large-deck battler.**

This is not a recommendation to start over, revert to the old workshop illustration, or reproduce every feature in the PDF. The current physical UI, character family, blueprint artwork, print pipeline, and transaction protections are valuable. The biggest mismatch is the relationship between collecting a creature, printing it, building a team, and fighting with it.

My preferred direction is **one active creature plus two reserves, a small support-card hand, and automatic combat resolution**. That is a substantial gameplay proposal, not a cosmetic adjustment. Keep the existing game available as the comparison baseline until a separately approved prototype proves better.

The three biggest deliberate changes are **a three-companion team instead of a creature-copy deck; a 15-card support kit instead of the current 40-card minimum; and team-defeat victory instead of printer-health victory**. The last is my new recommendation, not a settled requirement recovered from the PDF.

### How choices are marked

- **KEEP CURRENT:** retain an existing strength.
- **RESTORE ORIGINAL:** recover an idea supported by the PDF.
- **HYBRID / NEW:** deliberately combine the two, or introduce a new rule to make the combination coherent. These are not claims about what the PDF already specified.
- **DEFER / REJECT:** consciously leave an original or current idea out of the proposed near-term direction.

## 1. What I compared

### Original source

Found in Google Drive at `H:\My Drive\AI Projects\PrintForge\Reboot\3D Print Battles .pdf`.

All 25 pages were read. A byte-identical, durable [source copy](../reference/reboot-original-20260908/3D-Print-Battles-original.pdf) is retained locally. Selected rendered pages were inspected to check tables, revision boundaries, missing sections, and the ending.

- Size: 378,492 bytes.
- SHA-256: `A4D8D4C48935EE3EF161DC1F507394E6940DF04753E59F22B173B81C031A5FFF`.
- Page references below are PDF page numbers, not invented section pagination.

**Important qualification:** this is a conversation and an evolving AI-generated design, not one consistent final specification. Earlier requests and later answers conflict; the section labeled “Claude Plan” begins on page 8. Pages 12 and 14–16 contain literal `Code` placeholders instead of several promised rules. Page 25 ends in the middle of an expense table. The contents list sections whose full text is not present. I have not filled those gaps in as if they were original instructions.

Where the PDF disagrees with itself, I favor its later explicit answers, subject to your still-later choices in this project. For example: no mandatory math, whimsical animals/fantasy creatures rather than humans or mechs, PrintForge rather than a new name, and portrait Android for the current delivery effort.

### Current baseline

- Branch: `spike/printforge-physical-ui`.
- Reviewed HEAD: `f9e5a5870e74ae376f257494f1602f0400509394`.
- Latest documented Android review release: `0.8.10-physical-ui-polish`, code `106`, built from `f699bcbf0a0a`.
- Current source, existing runtime captures, compiled-APK capture evidence, and recorded deterministic test results were compared. This review did **not** launch Godot or perform a new phone playtest.
- Gameplay designer and independent read-only UI reviewer contributed to the comparison. Their agreement on a direction is advice, not user approval.

The current release has meaningful working systems: 57 cards including 24 creatures; the Cinderpaw/Aquafin/Voltwig starters; permanent blueprint ownership and printed instances; a free first-print entitlement; three five-card Founder packs; a legal 40-card starter-deck path; bot battles; equipment; market/progression transactions; persistent print/reward receipts; Back handling; and illustrated physical navigation. Existing compiled-runtime checks exercised deck editing, saving, reloading, opening a bot battle, and the print/attack cycle.

It is **not** a finished gameplay or device-quality sign-off. Pacing fails the recorded benchmark; the complete facing-inward creature asset set and tutorial/deck-assistance work remain open. Physical Android touch, audio, safe-area, and full-match performance acceptance are not established by desktop APK-runtime tests. DriveFS delivery is documented; cloud synchronization was not independently confirmed.

## 2. The important choices

| Area | Original PDF | Current game | Proposed choice and why |
|---|---|---|---|
| Identity | Magical, warm, high-tech workshop; living plastic creatures; PrintForge Legends (pp. 9–11). | Illustrated navy/brass/wood physical workshop. | **KEEP CURRENT + RESTORE ORIGINAL:** keep this newer steampunk family; add warmth and creature life, not the superseded workshop scene. |
| Creature presentation | Animated sprites styled as printed figurines, with layer lines and material character (p. 11). | Existing 2D character/sprite library and layered print presentation. | **KEEP CURRENT:** finish facing, contact, shadows, awakening, and deployment. Actual 3D meshes are not necessary to fulfill the original battle direction. |
| Collection meaning | Buy a permanent blueprint, print the creature, then bring that print into battle (pp. 1, 6, 22–23). | Blueprints, card copies, printed models, decks, and preprints coexist, but the player-facing relationship is complicated. | **HYBRID:** make the printed companion the team member; cards in hand primarily support that team. Preserve existing ownership records. |
| Battlefield | Later version: one active Print and two bench Prints (pp. 8, 14). | Three combat slots, repeat creature cards, printer-health victory. | **RESTORE ORIGINAL + NEW:** prototype one active/two reserves with a bounded roster and explicit team-defeat rule. Do not silently change the released format. |
| Card/deck burden | Separate 15-card Filament/support deck, maximum four-card hand (pp. 15–16). | Minimum 40-card deck mixing creatures and five support types. | **HYBRID:** three team choices plus a recommended 15-card support kit; four visible cards. Keep collection depth, reduce preparation and hand complexity. |
| Turn handling | Detailed turn sections are partly missing; many manual abilities/support effects are proposed (pp. 14–19). | Plan → Run Cycle automatically resolves internal phases. | **KEEP CURRENT:** one understandable planning window; no return to a stack of manual phases. |
| Battle printing | Printing is central, but the early “already printed” requirement leaves in-battle deployment details ambiguous. | Printer queue and ordered print/awaken/deploy/attack receipts exist. | **HYBRID:** workshop printing unlocks the companion; the battlefield printer visibly fabricates its match incarnation. This reconciles the two meanings without deleting the collection print. |
| Armor/equipment | Printed armor permanently attaches to an individual print (pp. 19–20). | Equipment cards print and can be fitted through battle actions. | **KEEP CURRENT + HYBRID:** keep print-then-fit, but make collection loadouts understandable and reversible. Reject an expensive permanent attachment trap. |
| Discovery | Undiscovered → Glimpsed → Known → Owned → Printed (p. 23). | Ownership/printed tracking exists; full discovery ladder does not. | **RESTORE ORIGINAL:** use the current physical folio for a meaningful discovery ladder. |
| Print Yard | Living collection habitat/play space (pp. 2, 6, 11). | Current `yard` navigation redirects to Market; retained legacy Yard code is a daily-button activity. | **RESTORE ORIGINAL:** a small, real animated companion display, not another rewards menu. |
| Market/packs | Permanent licenses, rotating offers, rare discoveries; very aggressive scarcity in parts of the draft (pp. 20–23). | Seeded offers, packs, ownership checks, receipts, and starter entitlements. | **HYBRID:** keep reliable transactions and pack reveals; prioritize understandable blueprints/equipment and guaranteed starting playability. Reject server-exclusive or four-hour rarity pressure. |
| Progression | Spool XP, coins, armor, stronger starter upgrades; several incomplete formulas (pp. 12, 19, 24–25). | Coins, XP/progression, upgrades and additional legacy/scaffolding fields. | **HYBRID:** keep earned progress; favor new options and bounded upgrades over runaway numerical advantage. Do not copy missing formulas or old prices. |
| Platforms/monetization | Mobile-first changes to Steam-first; pay-upfront is discussed (pp. 6–10). | Portrait Android review APK, no AdMob. | **KEEP CURRENT for delivery:** finish portrait Android; Steam remains a later target. Do not change pricing, add ads, or infer authorization for IAP from this PDF. |
| Scope | Online trades, guild/social architecture, educational activities, large arena/roster ambitions. | Solo/bot path and backend/Steam adapter scaffolding. | **DEFER:** finish the solo collection/battle loop before online, broad content expansion, or new services. |

## 3. Proposed battle redesign — the largest approval decision

### Why I recommend a prototype rather than another small HP adjustment

The existing 30-case pacing matrix measured **41 minimum / 64 median / 98 p95 / 100 maximum rounds started**; none met the ≤30-round benchmark. First creature defeat was at median round 4, but the first legal printer strike was at median round 48. A defender blocks printer targeting under the current rule, so lower printer health does not remove that initial delay.

These are results for the current bot policy, not proof about every possible player tactic. The same traces contain zero spell plays and no Guard/switch decisions. Bot decision quality and battle rules both need evaluation. The previously considered Breakthrough rule was withdrawn; Guard-only blocking is not approved. [Recorded pacing analysis](m11-pacing-followup-v1.md)

### Preferred prototype contract

**RESTORE ORIGINAL:** one large active creature on each side, two reserves near each printer, and a four-card support hand. Creatures stand on the continuous floor; they are not displayed as combat cards. Friendly prints face toward the rival; rivals face toward the player, using the already approved directional concept.

**KEEP CURRENT:** the printer, visible queue, layer-by-layer fabrication, awakening, movement onto the floor, equipment fitting, automatic attacks, and receipt-safe animation sequencing.

**NEW HYBRID — explicitly not the current rule:**

1. Bring three eligible printed companions. Each roster member may be fabricated and deployed **once per match** in the initial prototype; a KO does not allow endless replacement copies.
2. Start by choosing which companion to print first. Reserve fabrication happens visibly through the printer; reserves wait in physical staging bays. The starter tutorial uses a clearly identified one-versus-one training format.
3. During Plan, choose the next fabrication and at most one tactical support or swap command. Equipment enters the queue and is fitted only after completion. Exact command costs and swap timing must be specified before implementation.
4. Run Cycle resolves queued work and combat automatically. A ready reserve replaces a defeated active creature according to a visible priority chosen by the player; an unavailable replacement produces a clear printing/waiting state, not a hidden turn prompt.
5. **Defeat the opponent’s three roster members to win.** An empty active position while a surviving reserve is still printing is not defeat. Simultaneous final defeat is a draw, settled exactly once. Collection prints and equipment are never destroyed by losing a match.
6. The printer remains the production station. **The existing 200-HP printer-damage win condition is not also retained in this prototype.** It remains intact in the legacy comparison mode. This deliberately prioritizes creatures fighting over racing printer health.

The final point is a real tradeoff: it gives the game a clearer creature-battle identity but removes direct printer destruction as the main objective. If printer-health victory is essential, do not approve this contract unchanged; design that variant separately rather than mixing two half-defined win systems.

### Resource and support-card simplification

- **HYBRID:** a small, whole-number filament budget with automatic replenishment and a clearly visible next-cycle forecast. The PDF proposes this general resource-growth idea, but its costs and half-unit bonuses are inconsistent. Exact values require a new balance table; this report does not invent one.
- **RESTORE ORIGINAL:** a 15-card support deck and hand cap of four. Provide a complete recommended kit and an immediate Reset to Recommended action.
- **KEEP CURRENT content where compatible:** spells act immediately; physical equipment must print first; automatic creature abilities remain automatic.
- **NEW prototype restriction:** finite support supply, no indefinite reshuffle, unlimited resurrection, or cost-free recovery loop. Review healing, passive regeneration, resource theft, queue denial, and swap behavior together. A finite roster alone does not prove that a battle cannot stall.
- Validate that surviving roster members can always eventually deploy, Guard cannot make both teams permanently harmless, and a exhausted hand does not prevent combat completion. No hidden fatigue damage, arbitrary global damage multiplier, or disguised timer win.

This is a mechanics change with content compatibility work. Do not claim that all 57 current cards automatically work under it. Keep incompatible cards and their ownership in the existing mode; show a clear prototype eligibility filter rather than deleting or silently rewriting purchases.

Concrete review items include Emergency Reprint, Blueprint Thief, and the extra-print upgrade; Reinforced Chassis and printer repair/damage effects lose their current purpose without printer-HP victory. Pre-Prints also need an explicit mapping into the roster. Preserve their ownership and legacy behavior; any replacement benefit or compensation requires a stated decision. Simultaneous-KO draws require a new outcome and reward contract because the current settlement path is victory/loss-oriented. Never encode a draw as an unfinished match or silently count it as a loss.

### Acceptance before adopting it

Use seeded, deterministic comparisons including aggressive spell use, equipment, healing, resource denial, swaps, empty hands, queued replacements, simultaneous KO, disconnect/reload, and reduced motion. Upgrade the bot to choose among its actual legal tactics rather than measuring an all-Attack/no-spell policy alone. Retain the existing median 12–22 / maximum 30-round pacing target as a proposed acceptance gate, not an achieved result.

Also measure real decision time and animation duration: fewer rounds can still feel slow. Reject the prototype if printing repeatedly interrupts play, most decisions are obvious, or creatures spend more time waiting than fighting.

## 4. Make the collection and first session coherent

### One vocabulary, one player-visible relationship

**HYBRID:**

`Discover blueprint → own permanent license → print companion → choose team → equip/support → battle → earn coins and XP → discover more`

- A **blueprint** is the permanent recipe/license.
- A **print** is the companion you made and can display or select for battle.
- A **team** is the chosen roster, not another stack of creature duplicates.
- A **support kit** contains match-use spells, equipment instructions, and printer aids. Playing one does not destroy its collection entitlement.
- Battle filament is a match resource; Forge Coins are the collection economy. Do not charge workshop coins every time an already-owned companion enters another battle.

This preserves the existing data distinctions while removing their burden from the main navigation. Keep old decks/preprints and all ownership records intact behind a versioned migration/compatibility boundary. Do not reset saves to make a new tutorial work.

### Proposed first-session path

1. Choose Cinderpaw, Aquafin, or Voltwig; inspect its coherent blueprint.
2. Receive its permanent blueprint, an explicitly granted recommended support kit, and the free first print. The bed begins empty; no fully assembled creature is visible from the start. The tutorial uses these real owned items, not an unexplained fake deck.
3. The print awakens; immediately enter a short one-versus-one bot lesson with a ready support hand. Teach printing and one meaningful decision before asking for deck construction.
4. Open the three guaranteed Founder packs with recoverable, exactly-once reveals. **NEW hybrid starter guarantee:** provide two usable common companions and any required first-print vouchers alongside the pack rewards; the initial support kit already satisfies its minimum. Define these entitlements explicitly instead of relying on random luck or issuing the kit twice.
5. Show a ready three-companion team and one clear Play action. Let the player edit it afterward.
6. Award coins and XP once, explain the reward, and highlight one relevant new blueprint or upgrade.

Existing players keep all earned cards, prints, coins, rewards and legal 40-card decks. A preview-mode grant must be idempotent and must not replay already consumed Founder-pack rewards. Historical ownership is not automatically equivalent to a new unpaid entitlement.

### Progression choices

**KEEP CURRENT:** battles reward XP and coins; printer upgrades and equipment provide useful goals; deterministic receipt and save protection remain authoritative.

**HYBRID:** XP advances progression and unlocks options; coins purchase explicit upgrades. If XP is also to be spent directly on individual cards, make that a separate, clearly named mastery currency rather than silently subtracting account-level XP. Show Before → After, cost, and a confirmation for permanent purchases. Prefer bounded or sidegrade printer mods; do not let an old account’s spool level make beginner matches unwinnable.

**DEFER / REJECT:** do not introduce more currencies, mandatory educational tasks, season passes, fake-store flows, or real-money transactions to support this redesign. Preserve existing save fields without advertising unfinished systems as live features. The PDF’s reintroduced math Academy conflicts with its later explicit “no math” answers.

## 5. Screen-by-screen changes

These are changes to the current approved visual family, not another art-direction restart. The independent UI review found the physical family worth keeping; the main remaining problem is hierarchy and explanation, not a need to replace every illustration.

| Screen | Proposed change | What stays / what deliberately changes |
|---|---|---|
| Title / Continue | Keep PrintForge and the current family. Put Continue/New Game on obvious, readable physical controls; make recovery and Back behavior unambiguous. | **KEEP CURRENT.** No renaming or unrelated new title-art commission. |
| Workshop | Keep the newer enclosed printer and physical destinations. Add gentle ambient life and warmer amber light. Make the next useful action clear. Introduce a Yard entrance only when it leads to an actual habitat. | **KEEP CURRENT + RESTORE ORIGINAL.** Do not revive the old workshop backdrop. Cyan means focus/fabrication; amber means ready/reward, with labels/icons so color is not the only signal. |
| Starter / First Print | Three familiar starters, clear selection/confirmation, readable print cost or Free state. Empty bed → partial layers → complete print → awakening. | **KEEP CURRENT assets and entitlement logic.** Finish the emotional payoff rather than add decorative assembly parts. |
| Active Forge | Keep persistent progress, native layer/ETA instruments, Back and Skip. Make the bottom area a concise instrument strip with one clear primary action. | **KEEP CURRENT + POLISH.** No finished figure baked into the background; no text floating over unrelated hardware. |
| Archive / Forgedex | Integrate Unknown/Glimpsed/Known/Owned/Printed states into the existing folio. Use consistent transparent blueprint ink on paper, finished creature art in the appropriate known/printed inspector. | **RESTORE ORIGINAL inside current UI.** Unknown entries do not expose full identities; existing owned entries migrate to at least Owned and printed entries retain Printed. |
| Team / Support Kit | Three companion selections, one compact support-kit summary, one Save Loadout action; advanced card editing is a second layer. Explain incomplete eligibility inline. | **HYBRID replacing current deck complexity only if approved.** The present catalog/list/preprints/two-save layout is functional but too dense. Until then, add plain-language help and Recommended/Fill assistance to the current format. |
| Battle | Larger active creatures, small physical reserve positions, clear opponent hand count, four readable player cards, visible print queue, one Run control. Keep critical actions away from decorative corners. | **RESTORE ORIGINAL staging + KEEP CURRENT animation pipeline.** No card-shaped deployed creatures. Approved facing direction still needs actual production assets. |
| Pack opening / Rewards | Show what was added and why it matters; distinguish a new license from a duplicate/support copy. Keep Continue/Back visible and recovery-safe. | **KEEP CURRENT transactions + HYBRID explanations.** A skipped animation never loses or duplicates a reward. |
| Market | Keep cabinet/offer hardware but make categories and prices more prominent. Distinguish blueprint, equipment and support offers; show rotation information without pressure tactics. | **HYBRID.** Rare reveals can feel magical without a human/mech vendor or a new marketplace backend. |
| Upgrades | Show printer identity, current benefit, next benefit and cost. Separate collection convenience from competitive combat power. | **KEEP CURRENT progression, simplify presentation.** Do not bury permanent consequences behind a decorative tap target. |
| Print Yard | A bounded group of owned, animated companions wander, idle, and react to taps. Selecting one opens its existing inspector/team action. | **RESTORE ORIGINAL.** Existing art can support this; the legacy drill buttons and Market redirect are not this feature. |
| Settings / Back / Recovery | Consistent Back position, Android native Back, readable states, text scaling, reduced motion, audio and save recovery. | **KEEP CURRENT protections + DEVICE VALIDATION.** Native accessibility controls remain authoritative; physical styling must not obscure function. |

### Art and readability rules

- Reuse the current 24 whimsical animals/fantasy creatures, card back, coherent blueprint family, printers, book and hardware wherever possible. Do not generate a replacement roster before proving the loop.
- Generate new bitmap resources only for a demonstrated gap: front/rear combat facings, missing animation views, equipment overlays, or a genuinely missing screen layer. The designer/UI reviewer should approve a text-free brief before production.
- Preserve native text, numbers, accessibility labels and hit targets. One visible action gets one hit owner and one label; passive decoration must not impersonate a button.
- Make blueprints look printed onto the page through proper alpha/material treatment. Do not paste opaque character rectangles or meaningless exploded parts over the folio.
- Use 2D sprites with layer-line material cues, contact shadows, perspective, bob/weight and readable attack motion. A literal 3D model/turntable library is a separate optional project, not a prerequisite or something the current assets already provide.
- Audit normal and pressed/disabled states at 576×1024 and 720×1280, a tall phone aspect, 150% text, high contrast and reduced motion. Then validate real Android insets/navigation; a tall screenshot is not notch-safe-area proof.

## 6. What I would not bring forward now

- **REJECT:** mandatory math/age-tiered learning as the main coin source. Keep any future side activities maker-themed and optional.
- **REJECT:** mechs, human characters, renamed old starters, or a Hearthstone-themed reskin. Those conflict with the current direction.
- **REJECT:** an arbitrary printer-damage multiplier, hidden fatigue, or silently approved Guard-only experiment as the supposed pacing solution.
- **REJECT:** irreversible equipment attachment, permanent loss of collection prints on defeat, and grind/payment gates before the first playable match.
- **DEFER:** real 3D turntables/models, 100 arenas, a larger creature roster, and deeper ability/cooldown layers until the existing roster plays well.
- **DEFER:** online trading, accounts, matchmaking and social systems. Current Steam/Nakama interfaces and local trade demonstrations are not deployed multiplayer. Keep authority boundaries; plan privacy/safety/security review before implementing a public service.
- **DEFER:** premium pricing, IAP, ads and additional platforms. Preserve this release’s no-AdMob portrait Android configuration. The source’s commercial suggestions are not authorization to change it.

## 7. Suggested work sequence after approval

### A. Lock the design and visual evidence

Have the gameplay designer produce the exact one-active battle contract, compatible support kit, first-session grants and migration rules. Have the UI reviewer compare a complete portrait screen/state atlas against the current family. Generate concepts only for changed screens/states, but maintain a full atlas for the workflow. Obtain approval for both the atlas and the simplified loop before runtime edits or builds, as required by the project process.

**Decision gate:** approve or reject the three-member roster/team-defeat model and 15-card support kit. Do not interpret “polish the UI” as approval for these rules.

### B. Prove the smallest playable battle

Use the three starters, a small compatible support set and a bot. Prove queue → print → awaken → enter → fight → replace → result, plus simultaneous defeat, denied actions, empty hands, recovery and exactly-once settlement. Compare pacing and decision quality with the untouched current mode. Do not expand the roster or export a milestone that only looks playable.

**Milestone review:** designer checks choices/failures/progression; UI reviewer checks actual captures; primary reviews maintainability and performance. If pacing fails, return to the rule decision rather than piling on hidden fixes.

### C. Connect collection, team building and discovery

Deliver the free first session, deterministic starter guarantees, Team/Support Kit editor, Forge-to-team ownership link and Forgedex discovery. Preserve old saves and decks; test fresh install, current-profile upgrade and interrupted rewards. Add the lightweight Print Yard only after this path is complete.

**Acceptance:** a new player reaches a bot battle without grinding, guessing at deck legality, or opening lucky packs; an existing player loses nothing. Every route has visible Back and functioning native Android Back.

### D. Polish and release against actual evidence

Finish approved facings and equipment compatibility, natural blueprint-page treatment, alignment/hit ownership, safe areas, text scaling, audio and real-device frame/memory checks. Run the full first-session and complete-match path in the exported build.

At each meaningful milestone, refactor only the touched responsibilities: the current `main.gd` is about 4,513 lines and still mixes unified routes with legacy screens. Separate route ownership, view models, team/support editing and battle presentation; keep one authority for transactions. Share geometry/text sizing, cache immutable art/catalog lookups, and avoid rebuilding large UI trees every frame. Do not replace the whole repository or rewrite backend scaffolding to make this UI change.

Only after acceptance, produce a signed, commit-qualified Android review APK and README. Deliver non-overwriting files to the established Drive release folder; verify size and SHA-256 and report cloud confirmation separately from DriveFS copying. Do not label an incomplete UI preview as a playable milestone.

## 8. Evidence and audit trail

- [Original PDF, preserved source](../reference/reboot-original-20260908/3D-Print-Battles-original.pdf) — identity/printed-sprite direction pp. 9–11; starter/element concepts pp. 12–14; active/reserve battle pp. 14–16; equipment pp. 19–20; discovery/market pp. 22–23; conflicting Academy/economy pp. 23–25.
- [Current approved gameplay baseline](printforge-screen-first-gameplay-v1.md) — useful design history; older values are superseded by M11/current source, not treated as current balance.
- [Current pacing evidence and limitations](m11-pacing-followup-v1.md).
- [Latest Android delivery and bounded validation](../checkpoints/m11-ui1-android-delivery-20260908.md).
- [Current full UI capture index](../../build/evidence/m11-ui1-20260908/index.html) — actual runtime, not a generated concept atlas; local ignored evidence may not accompany a repository clone.
- [Compiled-release battle capture](../../build/evidence/m11-ui1-release-20260908/apk-f699bcbf0a0a/shipped-assets/build/evidence/deck-export-input/deck-shipped-720x1280/qa-save/deck-export-bot-opening-hand-720x1280.png).
- [Catalog](../../data/v3/catalog.json), [profile state](../../scripts/core/v3_profile_state.gd), [collection/economy rules](../../scripts/core/unified_rules.gd), [battle rules](../../scripts/battle/unified_battle_rules.gd), [bot policy](../../scripts/battle/unified_ai_opponent.gd), and [route/Forgedex/Yard implementation](../../scripts/ui/main.gd).
- [Designer’s supporting gameplay audit](reboot-comparison-20260908/gameplay-audit.md).

**Bottom line:** retain the current game’s production work, restore the original creature-collection fantasy, and prove a smaller, clearer battle before doing another broad art/build push. This document changes no gameplay, assets, export settings, or files on Google Drive.
