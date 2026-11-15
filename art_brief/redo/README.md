# Creatures to redo

Every creature here has a **placeholder picture made from code** (simple 3D shapes rendered in Godot),
not by an image generator. Each one needs a new painted sprite sheet in the style of the starters
(see `../style_targets/`) following the rules in `../README.md`.

- `redo_list.csv`: the same list as a spreadsheet, with each creature's prompt.
- `current_placeholders/<id>.png`: what the creature looks like now (its standing pose), so its
  body plan and colours can be kept or improved. Do **not** copy the placeholder's blocky style.

Save each new image as `art_inbox/<id>.png` and run `tools/import_creature_art.py`.

The **Test Bot** token (`test_bot`) also has a painted eight-pose sheet.
Tool and equipment pictures are outside this creature art list.

0 creatures.

All requested creature replacements are complete. See
[the delivered art manifest](../painted_art_manifest.json) and
[validation report](../painted_art_validation.json).
