# Prototype Sprite Template

Sterling and the Prototype swarm zombie establish the first production-facing
sprite contract for Survivor. Both are actual raster pixel-art sheets, loaded
through the existing `CharacterDefinition.sprite_scene` and
`EnemyDefinition.visual_scene` references. Gameplay code never draws a fallback
body for these entities.

## Shared Cell and Pivot Contract

- One animation cell is **64 x 64 pixels**.
- The sheet columns are the 8 screen-space facings, in this order:
  `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`.
- Each normalized source is placed with its feet at source pixel y=62.
- The visual `Sprite2D` is centered on a 64 px cell and positioned at `(0, -30)`.
  This puts the feet/ground anchor at the entity origin without frame jitter.
- Matching left/right-compatible facings may mirror. New character art can
  replace individual cells without changing the visual-scene API.
- `AnimationConvention.player_animation(action, direction)` remains the naming
  authority for player names such as `run_ne` and `basic_w`.

## Sterling Sheet

`art/characters/sterling/sterling_sheet.png` is 8 columns by 16 rows.

| Rows | State | Frames |
| --- | --- | --- |
| 0-2 | idle | 3 |
| 3-8 | run | 6 |
| 9-10 | basic pistol firing/recoil | 2 |
| 11 | hurt | 1 |
| 12-15 | death | 4 |

The source concept is `art/source/sterling_concept_sheet_v1.png`; it was created
from the canonical Sterling art bible. The approved five-facing source atlas is
`art/source/sterling_five_facing_atlas_chromakey.png`; the remaining three
directions mirror the compatible northeast/east/southeast masters. The source
and sheet use the locked
long wavy dark-brown hair, full mustache, warm adult face, cobalt split-tail
speedster coat, crimson lining, ivory shirt, silver hoop/Tree-of-Life pendant,
and paired fantasy semi-auto pistols.

## Swarm Zombie Sheet

`art/enemies/swarm_zombie/swarm_zombie_sheet.png` is 8 columns by 9 rows.

| Rows | State | Frames |
| --- | --- | --- |
| 0-3 | run | 4 |
| 4-5 | attack/contact lunge | 2 |
| 6-8 | death | 3 |

The source is `art/source/swarm_zombie_source_chromakey.png`. Its olive,
grey-green, rust, charcoal, and amber palette is deliberately restrained so a
dense swarm reads under Sterling's cobalt/crimson silhouette.

## Regeneration

`tools/assemble_prototype_sprite_sheets.py` removes the chroma key, applies
nearest-neighbour normalization and a bounded palette, then writes both sheets.
It is intentionally small and deterministic so a later art revision can retain
the same frame contract. Run it with the bundled workspace Python from the
repository root after replacing either approved source file.

## Player-Sheet Assembly Safety

Sterling and Cooper are assembled from trusted full-pose directional sources.
Do not composite broad rectangular masks from a flattened concept atlas, or use
an entire concept panel without removing disconnected debris: either shortcut
can place a second body, stray limbs, or unrelated effects inside one gameplay
cell. `tests/prototype_art_validation.tscn` enforces the 8 x 16 / 64 px grid,
non-empty cells, grounded live frames, non-duplicate run frames, and a single
primary opaque silhouette per Sterling/Cooper cell (with a narrowly allowed
small muzzle-flash exception on basic rows). Run the full headless validation
script after regenerating either sheet.
