# Blueprint V2 Family Generation Brief

Status: preproduction guard list. This file does not approve the visual grammar,
authorize full-family generation, or authorize runtime promotion.

## Global contract

- Generate one complete, assembled creature in one side/profile or shallow three-quarter
  profile view.
- Use transparent sepia/umber technical ink that remains legible at 160 px and sits
  naturally on parchment.
- Use only sparse, physically contacting print supports when the silhouette genuinely
  needs them.
- Never add exploded parts, detached callouts, duplicate views/models, bases, plinths,
  baked text, paper rectangles, colored sprites, or opaque backgrounds.
- Preserve the canonical silhouette before interior hatching detail.
- Validate real RGBA alpha; a baked checkerboard is a rejected opaque background.

## Identity guards

| ID | Silhouette and pose | Required identity | Avoid |
| --- | --- | --- | --- |
| `aquafin` | Stout baby aquatic lizard/axolotl, alert side-standing profile | Swept head/cheek fins, dorsal finlets, broad split leaflike tail fin, four rounded three-toed feet | Detached leaf-like fins; Coralisk confusion; unnecessary supports beyond the tail |
| `voltwig` | Slim electric jackrabbit, upright alert side profile | Huge lightning-bolt ears with inner zigzags, angular cheek tufts, short faceted bolt/leaf tail, long rabbit legs | Cropped or detached ears; floating lightning shards |
| `mossmunk` | Compact chipmunk/squirrel, gentle standing profile | Round ears, leafy forehead crest, layered leaf chest/back accents, huge continuous spiral leaf-bush tail | Scattered leaves or a disconnected tail; use the sprite sheet over the raw image's magenta-background silhouette |
| `frostling` | Small ice fox/cat, alert standing side profile | Tall crystalline inner ears, short ice forehead crest, cheek spikes, broad icy leaf/fan tail | Added wings, extra tails, or floating ice |
| `stoneback` | Low heavy tortoise/armadillo beast, side profile | Continuous domed polygon-rock shell, armored brow/face cap, squat pillar legs with pale claws, short plated tail | A pile of separated rocks; Verdantitan confusion |
| `galehopper` | Tall slim wind hare, poised side profile | Very long leaf-shaped ears, slim deer/rabbit body, spiral shoulder/hip motifs, turbine-like curled tail | Cropped ears/tail or disconnected decorative swirls |
| `sparkotter` | Low playful otter, standing side profile | Round otter head/ears, six long whiskers, lightning-bolt body mark, broad paddle/leaf tail with central bolt | Floating whiskers; loose lightning icon instead of one attached tail |
| `glassdrake` | Low prowling faceted drake-cat, side profile | Obsidian polygon armor, red crystal ear/horn pair, small red dorsal/shoulder fins, segmented up-curled tail with red tip | Invented glass transparency, wings, or floating crystals |
| `coralisk` | Stout aquatic salamander/lizard, alert side profile | Attached branched coral gill crown, coral dorsal spikes, large reef tail, sturdy four-legged body | Detached coral debris; Aquafin confusion |
| `runestag` | Upright stag, clean side profile | Attached forked rune-carved antlers, long pointed ears, cloven hooves, rune plates at shoulder and haunch | Floating rune glyphs; antlers separated from skull; excessive antler supports |
| `brambleowl` | Round owl, planted shallow three-quarter profile | Huge circular eye/brow disks, hooked beak, branch-antler ear tufts, layered leaf wings, leaf tail fan | Quadruped anatomy; detached branches/leaves or exploded nest parts |
| `ironmaw` | Broad low armored mastiff-like hybrid, side crouch | Massive square jaw, paired lower tusks, heavy brow/head armor, bulky segmented limbs, short plated tail | Crocodile or humanoid-mech redesign; detached armor plates |
| `thunderelk` | Tall athletic elk, proud side profile | Two branching lightning antlers, long ears, cloven hooves, sharp layered chest/shoulder plating | Floating bolt symbols; unreadable/cropped antlers; excessive supports |
| `coalgriffin` | Compact griffin, standing shallow three-quarter side profile | Eagle beak/head, feathered ear/crest, feline quadruped body, folded attached wings, feather-fan tail | Separate bird and cat components; detached wings or scattered feathers |
| `tidewhale` | Round chibi whale, clean side-hover profile | Bulbous whale body/head, dorsal fin, two pectoral flippers, split fluke, curved wave brow/cheek motif | Legs, water splash, duplicate whale; use only deliberate belly/flipper supports |
| `skyforge` | Plated animal griffin, shallow three-quarter side profile | Hooked beak, horned/feathered crest, attached tall segmented feather-wing with circular hub, taloned quadruped stance, segmented feather tail | Humanoid mech, cockpit, guns, engines, or detached panels |
| `pyraxis` | Alert crystal feline, side-standing profile | Integrated crystal crown/ear mane, angular cheek crystals, shoulder/foreleg crystal plates, tall segmented tail ending in one crystal fan | Floating gems or a second crystal display cluster |
| `verdantitan` | Massive rhino/titan, planted three-quarter side profile | Huge single nose horn, thick rhino body, attached leaf mantle across back, leaf crown, broad plated chest | Turtle-shell redesign, detached foliage, Stoneback confusion |
| `miragefox` | Elegant long-eared fox, standing side profile | Huge upright ears, forehead diamond crest, sharp cheek tufts, one attached multi-lobed crystalline leaf-fan tail | Detached tail lobes/shards or cropped extremities |
| `voidmanta` | Shallow top/side three-quarter manta profile | Two readable wide rounded wings, compact smiling face, layered dorsal plates, attached segmented tail with arrowhead tip | Flat true-side silhouette, detached arrow tip, excessive wing supports |
| `starloom` | Fairy-cat, shallow three-quarter side profile | Feline ears, paired attached featherlike antennae, four attached celestial wing lobes, segmented tail with attached star tip | Floating stars, duplicate wings, detached antennae, or a separate fairy figure |

## Source reliability

Every catalog ID above resolves to both a current raw-print reference and a 1536x1024
sprite-sheet reference. Mossmunk's raw image has a baked magenta background, so its
sprite sheet is authoritative for silhouette. Ironmaw's species label is visually
hybrid, but its feature construction is stable. Skyforge remains an animal griffin
despite plated/mechanical surface language and must never be escalated into a mech.

Each generated asset still requires individual identity, extremity, alpha, parchment,
and 160 px thumbnail review before any runtime integration.
