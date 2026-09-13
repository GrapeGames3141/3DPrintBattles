# PrintForge solo team prototype — approval atlas

**M0 approved on 2026-09-12 (“yeah do it”), candidate `ae8ad71`; Battle Core authorized. This atlas is not a playable build.**

The candidate follows the [solo prototype design](../../design/team-prototype-20260912.md):
three unique printed companions, a 15-card Support Kit, one Active plus two Reserves,
automatic Run Cycles, and team-defeat results. No printer HP, ads, multiplayer, or
40-card deck route is included.

These are offline HTML compositions over ImageGen masters and existing creature art.
Names, values, cards, states, and controls remain separate native layers.
The [checkpoint](../../checkpoints/team-prototype-preproduction-20260912.md) and
[review record](REVIEW.md) document evidence and limitations.

## Start here

1. [Workshop navigation](captures/v24b-normal-registry/workshop-prototype-nav-576x1024.png)
2. [Choose a starter blueprint](captures/v24b-normal-registry/starter-choice-576x1024.png)
3. [First print at 60%](captures/v24b-normal-registry/starter-print-60-576x1024.png)
4. [Guaranteed companions → Team setup](captures/v25-receipt-final/guaranteedstarterreceipt-576x1024.png)
5. [Three-companion Team](captures/v24b-normal-registry/teamvalid-576x1024.png)
6. [Recommended 15-card Support Kit](captures/v24b-normal-registry/supportkit-576x1024.png)
7. [Fabrication + Support Plan](captures/v24b-normal-registry/combined-second-plan-576x1024.png)
8. [Battlefield printing](captures/v24b-normal-registry/print60-576x1024.png)
9. [Swap Plan](captures/v24b-normal-registry/swap-plan-576x1024.png)
10. [Team-defeat result](captures/v24b-normal-registry/win-result-m2-576x1024.png)

## What approval covers

The user approved this screen family and its physical control placement as the
implementation direction. The user-approved battle loop is unchanged. This does **not** claim
working gameplay, animation playback, save safety, Android Back, real-device touch,
or all-route native accessibility; those must be implemented and tested in M1–M3.

There are **58 canonical states × three portrait sizes**, plus **three representative
large-text/HC/reduced-motion states × three sizes**: 183 selected images.
Tall is uniformly fitted with a synthetic 24px safe top and inert aspect letterbox,
not an ad reserve or proof of one-handed reach. Voltwig uses its documented legacy
art exception in these unchanged historical compositions. Its new
[genuine front/rear derivative](voltwig-neutral-facing/README.md) passed offline
asset review on 2026-09-12; actual runtime integration remains an M3 gate. The equipment
draft now has a [reviewed transparent derivative](armor-alpha-v1/README.md) for M3;
do not ship its original RGB source. The approved atlas images are unchanged.

[Offline fixture viewer](atlas.html) · [Masters and provenance](README.md)

## Large-text battle examples

Nominal 150% text is shown as at least 24px at 576 and 30px at 720. Native full names,
effects, queue identity, and disabled reasons remain accessible when labels shorten.
These static examples do not establish animation/reduced-motion equivalence.

| State | 576×1024 | 720×1280 | 720×1600 |
|---|---|---|---|
| combined-second-plan | [View](captures/v23c-battle-accessibility/combined-second-plan-576x1024.png) | [View](captures/v23c-battle-accessibility/combined-second-plan-720x1280.png) | [View](captures/v23c-battle-accessibility/combined-second-plan-720x1600.png) |
| swap-plan | [View](captures/v23c-battle-accessibility/swap-plan-576x1024.png) | [View](captures/v23c-battle-accessibility/swap-plan-720x1280.png) | [View](captures/v23c-battle-accessibility/swap-plan-720x1600.png) |
| print60 | [View](captures/v26b-print-labels/print60-576x1024.png) | [View](captures/v26b-print-labels/print60-720x1280.png) | [View](captures/v26b-print-labels/print60-720x1600.png) |

## Complete normal workflow

Current normal evidence is v24b's 55 unchanged states plus v25's three corrected
receipts. Current large evidence is v23c Combined/Swap plus v26b Print60. Earlier
captures are historical and must not substitute for these selected versions.

### Starter and first print

| State | 576×1024 | 720×1280 | 720×1600 |
|---|---|---|---|
| starter-choice | [View](captures/v24b-normal-registry/starter-choice-576x1024.png) | [View](captures/v24b-normal-registry/starter-choice-720x1280.png) | [View](captures/v24b-normal-registry/starter-choice-720x1600.png) |
| starter-choice-aquafin | [View](captures/v24b-normal-registry/starter-choice-aquafin-576x1024.png) | [View](captures/v24b-normal-registry/starter-choice-aquafin-720x1280.png) | [View](captures/v24b-normal-registry/starter-choice-aquafin-720x1600.png) |
| starter-choice-voltwig | [View](captures/v24b-normal-registry/starter-choice-voltwig-576x1024.png) | [View](captures/v24b-normal-registry/starter-choice-voltwig-720x1280.png) | [View](captures/v24b-normal-registry/starter-choice-voltwig-720x1600.png) |
| starter-inspect | [View](captures/v24b-normal-registry/starter-inspect-576x1024.png) | [View](captures/v24b-normal-registry/starter-inspect-720x1280.png) | [View](captures/v24b-normal-registry/starter-inspect-720x1600.png) |
| starter-voucher | [View](captures/v24b-normal-registry/starter-voucher-576x1024.png) | [View](captures/v24b-normal-registry/starter-voucher-720x1280.png) | [View](captures/v24b-normal-registry/starter-voucher-720x1600.png) |
| starter-print-early | [View](captures/v24b-normal-registry/starter-print-early-576x1024.png) | [View](captures/v24b-normal-registry/starter-print-early-720x1280.png) | [View](captures/v24b-normal-registry/starter-print-early-720x1600.png) |
| starter-print-60 | [View](captures/v24b-normal-registry/starter-print-60-576x1024.png) | [View](captures/v24b-normal-registry/starter-print-60-720x1280.png) | [View](captures/v24b-normal-registry/starter-print-60-720x1600.png) |
| starter-rawcomplete | [View](captures/v24b-normal-registry/starter-rawcomplete-576x1024.png) | [View](captures/v24b-normal-registry/starter-rawcomplete-720x1280.png) | [View](captures/v24b-normal-registry/starter-rawcomplete-720x1600.png) |
| starter-awaken | [View](captures/v24b-normal-registry/starter-awaken-576x1024.png) | [View](captures/v24b-normal-registry/starter-awaken-720x1280.png) | [View](captures/v24b-normal-registry/starter-awaken-720x1600.png) |
| guaranteedstarterreceipt | [View](captures/v25-receipt-final/guaranteedstarterreceipt-576x1024.png) | [View](captures/v25-receipt-final/guaranteedstarterreceipt-720x1280.png) | [View](captures/v25-receipt-final/guaranteedstarterreceipt-720x1600.png) |
| receipt-aquafin | [View](captures/v25-receipt-final/receipt-aquafin-576x1024.png) | [View](captures/v25-receipt-final/receipt-aquafin-720x1280.png) | [View](captures/v25-receipt-final/receipt-aquafin-720x1600.png) |
| receipt-voltwig | [View](captures/v25-receipt-final/receipt-voltwig-576x1024.png) | [View](captures/v25-receipt-final/receipt-voltwig-720x1280.png) | [View](captures/v25-receipt-final/receipt-voltwig-720x1600.png) |

### Team and Support Kit

| State | 576×1024 | 720×1280 | 720×1600 |
|---|---|---|---|
| team-empty | [View](captures/v24b-normal-registry/team-empty-576x1024.png) | [View](captures/v24b-normal-registry/team-empty-720x1280.png) | [View](captures/v24b-normal-registry/team-empty-720x1600.png) |
| team-one | [View](captures/v24b-normal-registry/team-one-576x1024.png) | [View](captures/v24b-normal-registry/team-one-720x1280.png) | [View](captures/v24b-normal-registry/team-one-720x1600.png) |
| teaminvalid | [View](captures/v24b-normal-registry/teaminvalid-576x1024.png) | [View](captures/v24b-normal-registry/teaminvalid-720x1280.png) | [View](captures/v24b-normal-registry/teaminvalid-720x1600.png) |
| teamvalid | [View](captures/v24b-normal-registry/teamvalid-576x1024.png) | [View](captures/v24b-normal-registry/teamvalid-720x1280.png) | [View](captures/v24b-normal-registry/teamvalid-720x1600.png) |
| supportkit | [View](captures/v24b-normal-registry/supportkit-576x1024.png) | [View](captures/v24b-normal-registry/supportkit-720x1280.png) | [View](captures/v24b-normal-registry/supportkit-720x1600.png) |
| supportkit-excluded | [View](captures/v24b-normal-registry/supportkit-excluded-576x1024.png) | [View](captures/v24b-normal-registry/supportkit-excluded-720x1280.png) | [View](captures/v24b-normal-registry/supportkit-excluded-720x1600.png) |

### Workshop and system states

| State | 576×1024 | 720×1280 | 720×1600 |
|---|---|---|---|
| workshop-prototype-nav | [View](captures/v24b-normal-registry/workshop-prototype-nav-576x1024.png) | [View](captures/v24b-normal-registry/workshop-prototype-nav-720x1280.png) | [View](captures/v24b-normal-registry/workshop-prototype-nav-720x1600.png) |
| preflight-error | [View](captures/v24b-normal-registry/preflight-error-576x1024.png) | [View](captures/v24b-normal-registry/preflight-error-720x1280.png) | [View](captures/v24b-normal-registry/preflight-error-720x1600.png) |
| recovery | [View](captures/v24b-normal-registry/recovery-576x1024.png) | [View](captures/v24b-normal-registry/recovery-720x1280.png) | [View](captures/v24b-normal-registry/recovery-720x1600.png) |
| focus-sheet | [View](captures/v24b-normal-registry/focus-sheet-576x1024.png) | [View](captures/v24b-normal-registry/focus-sheet-720x1280.png) | [View](captures/v24b-normal-registry/focus-sheet-720x1600.png) |
| reduced-motion | [View](captures/v24b-normal-registry/reduced-motion-576x1024.png) | [View](captures/v24b-normal-registry/reduced-motion-720x1280.png) | [View](captures/v24b-normal-registry/reduced-motion-720x1600.png) |

### Battle and results

| State | 576×1024 | 720×1280 | 720×1600 |
|---|---|---|---|
| preflight-empty | [View](captures/v24b-normal-registry/preflight-empty-576x1024.png) | [View](captures/v24b-normal-registry/preflight-empty-720x1280.png) | [View](captures/v24b-normal-registry/preflight-empty-720x1600.png) |
| choosefirstprint | [View](captures/v24b-normal-registry/choosefirstprint-576x1024.png) | [View](captures/v24b-normal-registry/choosefirstprint-720x1280.png) | [View](captures/v24b-normal-registry/choosefirstprint-720x1600.png) |
| printEarly | [View](captures/v24b-normal-registry/printEarly-576x1024.png) | [View](captures/v24b-normal-registry/printEarly-720x1280.png) | [View](captures/v24b-normal-registry/printEarly-720x1600.png) |
| print60 | [View](captures/v24b-normal-registry/print60-576x1024.png) | [View](captures/v24b-normal-registry/print60-720x1280.png) | [View](captures/v24b-normal-registry/print60-720x1600.png) |
| rawcomplete | [View](captures/v24b-normal-registry/rawcomplete-576x1024.png) | [View](captures/v24b-normal-registry/rawcomplete-720x1280.png) | [View](captures/v24b-normal-registry/rawcomplete-720x1600.png) |
| awaken | [View](captures/v24b-normal-registry/awaken-576x1024.png) | [View](captures/v24b-normal-registry/awaken-720x1280.png) | [View](captures/v24b-normal-registry/awaken-720x1600.png) |
| first-entry-active | [View](captures/v24b-normal-registry/first-entry-active-576x1024.png) | [View](captures/v24b-normal-registry/first-entry-active-720x1280.png) | [View](captures/v24b-normal-registry/first-entry-active-720x1600.png) |
| combined-second-plan | [View](captures/v24b-normal-registry/combined-second-plan-576x1024.png) | [View](captures/v24b-normal-registry/combined-second-plan-720x1280.png) | [View](captures/v24b-normal-registry/combined-second-plan-720x1600.png) |
| second-print | [View](captures/v24b-normal-registry/second-print-576x1024.png) | [View](captures/v24b-normal-registry/second-print-720x1280.png) | [View](captures/v24b-normal-registry/second-print-720x1600.png) |
| reserve-1-entry | [View](captures/v24b-normal-registry/reserve-1-entry-576x1024.png) | [View](captures/v24b-normal-registry/reserve-1-entry-720x1280.png) | [View](captures/v24b-normal-registry/reserve-1-entry-720x1600.png) |
| third-plan-behind-gear | [View](captures/v24b-normal-registry/third-plan-behind-gear-576x1024.png) | [View](captures/v24b-normal-registry/third-plan-behind-gear-720x1280.png) | [View](captures/v24b-normal-registry/third-plan-behind-gear-720x1600.png) |
| queue-capacity-reject | [View](captures/v24b-normal-registry/queue-capacity-reject-576x1024.png) | [View](captures/v24b-normal-registry/queue-capacity-reject-720x1280.png) | [View](captures/v24b-normal-registry/queue-capacity-reject-720x1600.png) |
| equipment-auto-fit | [View](captures/v24b-normal-registry/equipment-auto-fit-576x1024.png) | [View](captures/v24b-normal-registry/equipment-auto-fit-720x1280.png) | [View](captures/v24b-normal-registry/equipment-auto-fit-720x1600.png) |
| equipment-fitted | [View](captures/v24b-normal-registry/equipment-fitted-576x1024.png) | [View](captures/v24b-normal-registry/equipment-fitted-720x1280.png) | [View](captures/v24b-normal-registry/equipment-fitted-720x1600.png) |
| printing-wait-plan | [View](captures/v24b-normal-registry/printing-wait-plan-576x1024.png) | [View](captures/v24b-normal-registry/printing-wait-plan-720x1280.png) | [View](captures/v24b-normal-registry/printing-wait-plan-720x1600.png) |
| third-print-awaken | [View](captures/v24b-normal-registry/third-print-awaken-576x1024.png) | [View](captures/v24b-normal-registry/third-print-awaken-720x1280.png) | [View](captures/v24b-normal-registry/third-print-awaken-720x1600.png) |
| reserve-2-entry | [View](captures/v24b-normal-registry/reserve-2-entry-576x1024.png) | [View](captures/v24b-normal-registry/reserve-2-entry-720x1280.png) | [View](captures/v24b-normal-registry/reserve-2-entry-720x1600.png) |
| swap-plan | [View](captures/v24b-normal-registry/swap-plan-576x1024.png) | [View](captures/v24b-normal-registry/swap-plan-720x1280.png) | [View](captures/v24b-normal-registry/swap-plan-720x1600.png) |
| swap-and-attack | [View](captures/v24b-normal-registry/swap-and-attack-576x1024.png) | [View](captures/v24b-normal-registry/swap-and-attack-720x1280.png) | [View](captures/v24b-normal-registry/swap-and-attack-720x1600.png) |
| swap-result | [View](captures/v24b-normal-registry/swap-result-576x1024.png) | [View](captures/v24b-normal-registry/swap-result-720x1280.png) | [View](captures/v24b-normal-registry/swap-result-720x1600.png) |
| replacement-risk-plan | [View](captures/v24b-normal-registry/replacement-risk-plan-576x1024.png) | [View](captures/v24b-normal-registry/replacement-risk-plan-720x1280.png) | [View](captures/v24b-normal-registry/replacement-risk-plan-720x1600.png) |
| replacement-attack | [View](captures/v24b-normal-registry/replacement-attack-576x1024.png) | [View](captures/v24b-normal-registry/replacement-attack-720x1280.png) | [View](captures/v24b-normal-registry/replacement-attack-720x1600.png) |
| auto-replacement | [View](captures/v24b-normal-registry/auto-replacement-576x1024.png) | [View](captures/v24b-normal-registry/auto-replacement-720x1280.png) | [View](captures/v24b-normal-registry/auto-replacement-720x1600.png) |
| empty-active-required | [View](captures/v24b-normal-registry/empty-active-required-576x1024.png) | [View](captures/v24b-normal-registry/empty-active-required-720x1280.png) | [View](captures/v24b-normal-registry/empty-active-required-720x1600.png) |
| last-member-printing | [View](captures/v24b-normal-registry/last-member-printing-576x1024.png) | [View](captures/v24b-normal-registry/last-member-printing-720x1280.png) | [View](captures/v24b-normal-registry/last-member-printing-720x1600.png) |
| last-member-active | [View](captures/v24b-normal-registry/last-member-active-576x1024.png) | [View](captures/v24b-normal-registry/last-member-active-720x1280.png) | [View](captures/v24b-normal-registry/last-member-active-720x1600.png) |
| empty-active-replenish | [View](captures/v24b-normal-registry/empty-active-replenish-576x1024.png) | [View](captures/v24b-normal-registry/empty-active-replenish-720x1280.png) | [View](captures/v24b-normal-registry/empty-active-replenish-720x1600.png) |
| replenish-run | [View](captures/v24b-normal-registry/replenish-run-576x1024.png) | [View](captures/v24b-normal-registry/replenish-run-720x1280.png) | [View](captures/v24b-normal-registry/replenish-run-720x1600.png) |
| replenish-next-plan | [View](captures/v24b-normal-registry/replenish-next-plan-576x1024.png) | [View](captures/v24b-normal-registry/replenish-next-plan-720x1280.png) | [View](captures/v24b-normal-registry/replenish-next-plan-720x1600.png) |
| replenish-last-printing | [View](captures/v24b-normal-registry/replenish-last-printing-576x1024.png) | [View](captures/v24b-normal-registry/replenish-last-printing-720x1280.png) | [View](captures/v24b-normal-registry/replenish-last-printing-720x1600.png) |
| replenish-last-active | [View](captures/v24b-normal-registry/replenish-last-active-576x1024.png) | [View](captures/v24b-normal-registry/replenish-last-active-720x1280.png) | [View](captures/v24b-normal-registry/replenish-last-active-720x1600.png) |
| hand-exhausted | [View](captures/v24b-normal-registry/hand-exhausted-576x1024.png) | [View](captures/v24b-normal-registry/hand-exhausted-720x1280.png) | [View](captures/v24b-normal-registry/hand-exhausted-720x1600.png) |
| win-result-m2 | [View](captures/v24b-normal-registry/win-result-m2-576x1024.png) | [View](captures/v24b-normal-registry/win-result-m2-720x1280.png) | [View](captures/v24b-normal-registry/win-result-m2-720x1600.png) |
| loss-result-m2 | [View](captures/v24b-normal-registry/loss-result-m2-576x1024.png) | [View](captures/v24b-normal-registry/loss-result-m2-720x1280.png) | [View](captures/v24b-normal-registry/loss-result-m2-720x1600.png) |
| draw-result-m2 | [View](captures/v24b-normal-registry/draw-result-m2-576x1024.png) | [View](captures/v24b-normal-registry/draw-result-m2-720x1280.png) | [View](captures/v24b-normal-registry/draw-result-m2-720x1600.png) |

## Verification records

- [Full 174-check normal ledger](captures/v24b-normal-registry/render-ledger.json)
- [Nine corrected receipt checks](captures/v25-receipt-final/render-ledger.json)
- [Large-text Combined/Swap ledger](captures/v23c-battle-accessibility/render-ledger.json) — its Print60 images are superseded by v26b.
- [Three final large Print60 checks](captures/v26b-print-labels/render-ledger.json)
- [Read-only review and exact supersessions](REVIEW.md)

[Historical capture archive](captures/) includes superseded and rejected diagnostics,
including earlier previews shown in chat. It is not current approval evidence.

No Godot, runtime, player-save, build, or Google Drive release action occurred in M0.
After atlas approval: deterministic Battle Core → Collection Link → native UI/Android
validation and a separately verified, non-overwriting review build.
