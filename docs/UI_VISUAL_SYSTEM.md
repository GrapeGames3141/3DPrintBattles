# Arcane Foundry UI Visual System

Runtime UI uses a family-friendly Arcane Foundry treatment: charcoal forged-steel
surfaces, aged-brass manufactured seams and rails, warm ivory functional text, sparse
cyan filament energy, and ember-orange pressed or active energy. The workshop artwork
remains the source of scene identity; UI surfaces frame it rather than replacing it.

## Hierarchy

- Panels are compact forged plates: dark neutral steel with only a restrained caller
  tint, a one-pixel brass/cyan/semantic seam, 4–6px corners, and a small shadow.
- Buttons are distinct keycaps, not miniature panels. Their normal face is dark steel;
  hover and focus expose cyan filament, pressed state uses a shallow inset ember/brass
  edge, and disabled state remains muted but legible.
- Headings use gold/cyan hierarchy where meaningful; body copy uses warm ivory or
  neutral gray. Semantic warning, success, and failure colors remain meaningful.
- Glow is reserved for focus, active controls, and explicitly Arcane moments. Static
  chrome, borders, and cards do not use heavy bloom, runes, or ornate fantasy clutter.

## Accessibility invariants

Text size, localized copy, controller focus, callbacks, and existing 44/48px touch
targets are retained. High-contrast mode replaces the regular plate palette with
near-black faces, white three-pixel outlines, and white text; it does not rely on
color alone. Support-card presentation remains governed by its separate card contract
and must remain compatible with these surrounding runtime plates.
