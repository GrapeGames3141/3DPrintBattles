# Move presentation audit

Checkpoint 0.5.21 keeps combat authority in `BattleRules`. These profiles are
deterministic presentation only: a unit rests on idle frame 0, then an accepted
event token starts a finite move, response, or impact sequence before returning
to static idle. Reduced Motion uses the same readable state with no processing.

The stage uses an inset source rectangle for every 384x512 sprite-sheet cell,
protecting the established 2px atlas gutter from neighboring-frame bleed. The
offline `tools/clean_sprite_atlas_edges.gd` pass preserves each cell's largest
alpha component (including an intentional edge touch), removes every other
edge-touching component, and leaves interior disconnected detail intact. Its
24-sheet before/after SHA-256 and removal counts are recorded in
`docs/SPRITE_ATLAS_EDGE_REPAIR.json`; runtime never repeats that component scan.
Generated optional atlases may enhance the same profiles at
`res://assets/vfx/elemental_projectiles_v1.png` and
`res://assets/vfx/status_accents_v1.png`; absent assets deliberately
fall back to the code-native beam, trail, ring, shard, and aura drawing.

| Creature | Signature | Element profile | Effect accents |
| --- | --- | --- | --- |
| Cinderpaw | Ember Pounce | Fire ember / flare | Debuff |
| Aquafin | Tidal Patch | Water droplet / ripple | Heal |
| Voltwig | Static Hop | Lightning bolt / spark | Filament |
| Mossmunk | Root Guard | Nature leaf / bloom | Shield, heal |
| Frostling | Cold Snap | Ice shard / crystal | Ability lock |
| Stoneback | Shell Brace | Stone rock / dust | Shield, cleanse |
| Galehopper | Gust Step | Wind ribbon / gust | Switch discount |
| Sparkotter | Charge Current | Lightning bolt / spark | Filament |
| Glassdrake | Molten Wing | Fire ember / flare | Attack buff |
| Coralisk | Reef Repair | Water droplet / ripple | Heal, shield |
| Runestag | Rune Burst | Arcane rune / nova | Debuff |
| Brambleowl | Thorn Volley | Nature leaf / bloom | Heal |
| Ironmaw | Forge Wall | Stone rock / dust | Shield, attack buff |
| Aurorawing | Aurora Chill | Ice shard / crystal | Ability lock |
| Thunderelk | Stampede Arc | Lightning bolt / spark | Switch discount |
| Coalgriffin | Cinder Crown | Fire ember / flare | Shield |
| Tidewhale | Deep Renewal | Water droplet / ripple | Heal, cleanse |
| Skyforge | Jetstream | Wind ribbon / gust | Filament |
| Pyraxis | Prism Nova | Arcane rune / nova | Debuff |
| Verdantitan | Ancient Bloom | Nature leaf / bloom | Heal, shield |
| Miragefox | Layer Shift | Ice shard / crystal | Cleanse, shield |
| Voidmanta | Void Weave | Arcane rune / nova | Ability lock |
| Worldcoil | Bedquake | Stone rock / dust | Shield |
| Starloom | First Print | Arcane rune / nova | Filament |

Basic attack is a restrained streak, lunge, and impact. Defend uses a guard
ring; support cards use a concise support pulse; switching uses a short arrival
line. These effects remain legible in high contrast through white outlines and
never communicate rules by color alone.
