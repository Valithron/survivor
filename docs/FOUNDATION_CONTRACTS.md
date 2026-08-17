# F0 Foundation Contracts

This document records the contracts established by Packet F0. They are intentionally narrow so P1, E1, X1, W0, and A1 can converge without inheriting a speculative framework.

## Runtime Ownership

- `RunController` owns the lifecycle of one run: character/profile references, elapsed time, user pause, level-up pause, and natural terminal outcome. It does not own player combat, spawning, weapon logic, XP rules, or UI.
- `GameplayEvents` carries cross-branch game events. An enemy reports its defeat with an `XpAward`; progression decides how to collect and spend it.
- `HealthComponent` owns current/max health. Damage arrives only through `apply_damage(DamageEvent)` and consumers observe `health_changed`, `damage_received`, and `died` signals.
- `DevTools` is signal-only. It is for test scenes and developer workflows, never player UI.

## Data Resources

The canonical resource types are:

- `CharacterDefinition`: identity, base stats, basic/tactical/ultimate descriptors, level milestones, optional sprite/portrait references.
- `WeaponDefinition`: shared-weapon identity, targeting mode, runtime scene reference, and exactly five `WeaponRankDefinition` records. Its `tuning` dictionary is deliberately empty until a weapon branch owns real behavior.
- `EnemyDefinition`: simple health, speed, contact damage per second, collision radius, XP value, visual scene, and elite multipliers.
- `RunProfile`: run duration and ordered data-only phase markers. F0 does not implement a director.

The starting `Sterling`, swarm zombie, Katana, Molotov, and five-minute Prototype profile resources demonstrate loadable contracts. Their values are temporary editable starting points, not approved final balance. The two ability descriptors that are not part of the Prototype are data references only; they do not implement tactical or ultimate behavior.

## Damage and XP Events

`DamageEvent` is a small payload: source, amount, lightweight tag, knockback vector, and optional metadata. There is no resistance matrix, status system, or critical-hit taxonomy in F0.

`XpAward` is a small payload: source, integer amount, and world position. E1 reports it through `GameplayEvents.report_enemy_defeated(enemy, award)`; X1 later listens to `GameplayEvents.xp_awarded` and owns collection/leveling.

## Animation and Pivot Convention

Directions are screen-space: `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`. The canonical helper is `AnimationConvention.direction_id()`.

Player animation names:

- `idle_<direction>` — 2 to 3 frames
- `run_<direction>` — 6 frames
- `basic_<direction>` — 2 firing/recoil frames
- `hurt` — 1 frame
- `death_<direction>` — 4 frames

Zombie animation names:

- `run_<direction>`
- `attack_<direction>`
- `death_<direction>`

The entity root position is the ground/feet anchor. Every source frame uses a fixed canvas and places its ground anchor at `(frame_width / 2, frame_height - 2)`. For a non-centered `Sprite2D`, set its local position to the negative of that anchor. This keeps feet aligned across every frame and facing; mirroring compatible source facings is allowed at import/setup time without changing runtime animation names.

No final Sterling or production zombie sprite sheet is present in this repository at F0. The test scene uses no art placeholder that could be mistaken for final art.

## Test Entry Point

Run `res://tests/f0_test_scene.tscn` (the current main scene). It validates the Input Map and sample Resources, exercises `HealthComponent` + `DamageEvent`, starts the thin run lifecycle, and exposes three signal-only developer hooks:

- `1`: XP award event
- `2`: swarm spawn request
- `3`: timer jump request

It is an F0 contract test, not a player-facing game scene.

For CI or terminal validation, run `godot --headless --path . --script res://tests/f0_headless_validation.gd`. It exits non-zero on a contract failure. Prototype branch validation scenes use `--scene` so project autoloads are initialized.
