# Survivor

**Working title:** Survivor  
**Status:** Planning complete enough for implementation packaging. No production game code should be added until the implementation handoff is read.

Survivor is a small, Windows-first, anime-influenced pixel-art bullet-heaven game built in **Godot 4.7 with GDScript**. The player controls stylized versions of members of the Commune while fighting escalating zombie hordes, assembling a four-weapon build, using character-specific tactical and ultimate abilities, and surviving a 12-minute run that culminates in a final boss.

The V1 playable roster is intentionally scoped to:

- Sterling
- Ryan
- Cooper

Cydney, Gabi, Kenly, and Ashley are deferred to a later version.

## Start Here

A fresh implementation agent should begin with:

- [`docs/IMPLEMENTATION_HANDOFF.md`](docs/IMPLEMENTATION_HANDOFF.md) - primary Codex entry point
- [`docs/PROJECT_GRAPH.md`](docs/PROJECT_GRAPH.md) - design and production dependency graphs
- [`docs/MILESTONES.md`](docs/MILESTONES.md) - Prototype, First Playable, Vertical Slice, and V1 gates

Deeper specifications:

- [`docs/GAME_VISION.md`](docs/GAME_VISION.md)
- [`docs/GAMEPLAY_SYSTEMS.md`](docs/GAMEPLAY_SYSTEMS.md)
- [`docs/CHARACTERS_AND_CONTENT.md`](docs/CHARACTERS_AND_CONTENT.md)
- [`docs/ART_AND_ANIMATION.md`](docs/ART_AND_ANIMATION.md)
- [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md)
- [`docs/DECISION_STATUS.md`](docs/DECISION_STATUS.md)

## Core Identity

The intended fantasy is **Commune personality plus extreme power growth**. The tone is cool anime action with real personality and humor, not parody and not grim survival horror.

The core run loop is:

1. Choose an unlocked character.
2. Enter one large scrolling arena.
3. Move manually while the unique basic attack auto-fires.
4. Toggle the basic attack between Auto Aim and Manual Aim.
5. Use a tactical ability and a longer-cooldown ultimate.
6. Kill pursuing zombies and automatically collect nearby XP.
7. Level up and pause combat to choose one of three shared-weapon options.
8. Fill up to four shared weapon slots and rank chosen weapons toward powerful Rank 5 capstones.
9. Survive hand-authored enemy surges at 2:30, 5:00, 7:30, and 10:00.
10. At 12:00, fight a huge mutated zombie boss while the late-game horde continues spawning.
11. Win or die, then restart quickly and continue lightweight unlock progression.

## Scope Rules

The project should produce recognizable, playable results quickly, but the named milestone gates are intentionally stronger than a circles-and-boxes technical demo.

Important scope constraints:

- One arena through V1.
- Three playable characters through V1.
- Three regular zombie archetypes.
- Six core shared weapons for the Vertical Slice baseline.
- V1 may add roughly 30 to 50 percent more gameplay content after the Vertical Slice reveals what is actually missing, but character count and arena count remain fixed.
- No permanent stat metaprogression.
- No ammo or reload system.
- No rerolls on level-up choices.
- No run resume after closing the game.
- Controller support is post-V1.
- Web export is post-V1.

## Implementation Principle

Do not optimize the project around hypothetical future scale before the combat is fun. Build data-driven systems, profile the straightforward Godot implementation, use pooling/reuse where appropriate, and only move to lower-level optimization if profiling shows a real problem.

The project should be built as a graph of independent workstreams with explicit contracts and frequent playable convergence points. Do not hand one implementation agent the entire game as a single undifferentiated task.
