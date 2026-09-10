# Cinderpaw ImageGen-only alpha recovery attempt

Built-in ImageGen, 2026-09-10; output exec-7b79278e-0c04-4078-8392-923b9cd91c27.png. Still RGB with baked checkerboard: rejected for runtime promotion. No programmatic image modification performed.

## Exact prompt

+Use case: background-extraction. The supplied image is the EDIT TARGET: a production PrintForge Cinderpaw 4x2 animation sheet. Remove ONLY the exterior gray-and-white checkerboard background and return an actual transparent RGBA PNG. Preserve all eight creatures exactly: their pixels, orange/cream/fire colors, poses, camera views, scale, cell locations, exact 1536x1024 canvas and four columns/two rows. Preserve solid interior cream paws and bright flame highlights fully opaque; those are not holes. Keep the two rows in the same places. This is a cutout operation, not a redesign or re-render. No checkerboard pattern in RGB, no white/black/colored matte, no shadows or new scene, no labels, no crop or rearrangement. Output must have a genuine transparent alpha channel in all empty space, including gaps inside each creature silhouette. Production PNG with transparency, not an illustration of transparency.
