# Art brief: painted creatures for 3D Print Arena

## What we need

One sprite sheet per creature for the **279 creatures** listed in `prompts.md` (also in
`creatures.csv`). Each sheet shows the same creature in 8 poses. The game swaps between
the poses to animate it: idle, walk, attack and hurt.

These creatures are currently placeholder 3D models. They should look like the painted
starters in `style_targets/` (Cinderpaw, Aquafin, Voltwig, Frostling, Brambleowl).

| Group | Count | Notes |
|---|---|---|
| Hybrids from the reference pictures | 24 | Do these first. The concepts come from `references/`. |
| Cards (everything else you can open in a pack) | 239 | |
| Tokens (later evolution stages, never in packs) | 16 | Do these last. |

## The look: match the starters

Open `style_targets/voltwig_sprite_sheet.png` and `cinderpaw_sprite_sheet.png`. Every new
creature should look like it belongs next to them:

- **The toy:** a cute, chibi creature that looks like a glossy **3D-printed toy figure**.
- **Surface:** made of coloured PLA filament, with very fine print layer lines visible on the surface.
- **Shapes:** smooth, rounded and friendly, with big expressive eyes. It suits all ages: cute and cool, never scary or gory.
- **Lighting:** soft studio lighting.
- **Colour:** the creature's element sets it. Fire is red, orange and yellow. Water is blue, teal and pearl. Lightning is yellow and graphite. Nature is green, brown and pink. Ice is pale blue, white and lilac. Stone is grey, sandstone and amber. Wind is mint, white and sky blue. Arcane is violet, magenta and gold. Neutral is orange, white and blue.

## The ideas: be as creative as the references

`references/` holds the pictures that show the kind of creature we want. Each mixes two or
more legends into one printed figure:

- **01** a Medusa on a scarab.
- **02** a phoenix griffin.
- **03** a Scylla kraken.
- **04** an Anubis harpy.
- **05** a chimera raiju.
- **06** a sphinx wendigo stag.
- **07** a pegasus leviathan.
- **08** a cerberus foo dog.
- **09** a hydra quetzalcoatl.
- **10** a minotaur kitsune.
- **11** a set of space creatures.

Take the **creativity** from the references: the mixed legends, armour plates, brass gears
on the joints, glowing resin parts and two-tone silk filament. Draw them in the **starter
style** above, not as the realistic figurines in the photos. The photos are turnarounds on
a workbench. We need sprite poses on a black background, as below.

## Format (the game depends on this)

- **Layout:** one image with **8 poses in a 4 × 2 grid**, the same creature in every cell.
  `style_targets/layout_template.png` shows the grid and the ground line.
- **Pose order:**
  1. Standing idle.
  2. Crouching, ready.
  3. Walking, mid-stride.
  4. Proud, with the tail or crest raised.
  5. Winding up to attack.
  6. Lunging attack, mouth open.
  7. Low, sneaking crouch.
  8. Flinching, hurt, eyes squeezed shut.
- **Background:** a **plain solid black** background, with no shadows, floor, text or frame.
  A transparent background is even better.
- **View:** side three-quarter view, the creature **facing right**.
- **Size:** every pose the **same size**, standing on the **same ground line**, and not cut
  off at the cell edges.
- **Resolution:** any size works, but 1536 × 1024 or larger is ideal. The importer scales it.
- **Same creature:** it must be the same design in all 8 poses: colours, horns, wings and
  number of heads.

If the generator can't make a grid, make the 8 poses as 8 separate images instead. Keep
the same creature and seed, and name them `<id>_0.png` to `<id>_7.png` in the order above.

## Naming and delivery

- **Name:** save each file as **`<id>.png`**, using the id from `prompts.md` or
  `creatures.csv`, for example `scarab_medusa.png`.
- **Folder:** put the files in the repository's **`art_inbox/`** folder, which is kept out of Git.
- **Import:** run this to bring them into the game:

  ```
  uv run --with numpy --with pillow python tools/import_creature_art.py
  ```

  It removes the black background, lines the 8 poses up and writes the game's sprite sheet
  and the raw (unpainted) version used for cards you don't own yet.

## Files in this folder

- **`redo/`: the list of every creature to redo** (`redo/README.md` and `redo/redo_list.csv`), with
  each one's current code-made placeholder picture in `redo/current_placeholders/`.
- `README.md`: this brief.
- `prompts.md`: one ready-to-paste prompt per creature, with the style and format rules
  written in.
- `creatures.csv`: the same list as a spreadsheet (id, name, element, rarity, card or
  token, prompt), for batch tools.
- `references/`: the 11 concept pictures.
- `style_targets/`: the starters' finished sprite sheets (the look to match) and the
  layout template.

## Checklist for each image

- The 8 poses are in the right order, in a 4 × 2 grid.
- It's the same creature in every pose, facing right.
- The background is plain black (or transparent), with nothing else in the picture.
- Every pose is the same size and stands on the same line.
- It looks like a glossy, cute 3D-printed toy, like Voltwig and Cinderpaw.
- The file is named `<id>.png`.
