# Technical Architecture

## Technology Lock

**Engine:** Godot 4.7  
**Language:** GDScript  
**Primary V1 platform:** Windows desktop  
**First Playable input:** keyboard + mouse  
**Controller support:** deferred until after V1  
**Web export:** deferred until after Windows V1

The stack is locked because the project prioritizes native-game robustness and several-hundred-enemy horde performance over browser-first deployment.

## Architecture Principles

1. **Fun before abstraction.** Build only enough architecture to support the locked systems cleanly.
2. **Data-driven tuning.** Health, damage, cooldowns, spawn rates, weapon ranks, milestone values, and similar tuning should live in editable Godot Resources rather than being buried in gameplay scripts.
3. **Shared contracts.** Character, weapon, enemy, and run-director systems must communicate through stable interfaces so parallel Codex work does not produce incompatible systems.
4. **Profile before low-level optimization.** Start with straightforward Godot 2D architecture. Use pooling/reuse. Only move toward lower-level servers/batched approaches if profiling demonstrates a real need.
5. **Frequent playable convergence.** Merge/integrate major system clusters into testable builds regularly rather than allowing long-running isolated branches.
6. **Windows first.** Do not constrain V1 architecture around browser limitations. Keep platform-neutral gameplay logic where practical so web export can be evaluated later.

## Recommended Project Structure

Exact folder names may evolve, but implementation should preserve these responsibilities:

```text
res://
  game/
    run/
    player/
    enemies/
    weapons/
    abilities/
    progression/
    pickups/
  data/
    characters/
    weapons/
    enemies/
    run_profiles/
  ui/
  art/
    characters/
    enemies/
    environment/
    vfx/
  audio/
  tests/
  dev/
```

Do not split into dozens of directories/classes before real complexity exists.

## Core Runtime Ownership

### Run Controller

Owns the lifecycle of one run:

- timer
- pause state
- victory/death termination
- current character reference
- boss transition
- run summary payload

It should not contain weapon-specific or enemy-specific logic.

### Player Controller

Owns:

- movement
- current aim mode
- manual aim vector
- auto-aim target/direction
- health/damage handling
- access to character kit runtime

Character-specific behavior should be configured/composed from character data and ability implementations, not implemented through a giant `if character == ...` script.

### Character Definition Resource

A custom Resource should describe stable character data such as:

- id
- display name
- base health
- move speed
- basic attack reference
- tactical reference
- ultimate reference
- milestone configuration
- portrait/sprite references
- unlock rule reference or metadata

Exact field names are implementation details.

### Weapon Definition Resource

Each shared weapon should be represented by data plus runtime behavior.

Data should include or reference:

- id/name
- icon
- rank definitions 1 through 5
- cadence/cooldown
- damage
- targeting mode
- projectile/effect scene
- rank-specific modifiers

Do not implement six weapons as one massive switch statement.

### Enemy Definition Resource

Normal enemy data should cover:

- archetype id
- health
- speed
- contact/attack damage
- collision size
- XP value
- visual scene/reference
- elite multipliers where appropriate

Normal enemy behavior should remain simple.

### Run Profile / Director Data

The standard 12-minute run should be data-driven enough that surge timing and composition can be tuned without rewriting spawn code.

Required major beats:

- 2:30 swarm emphasis
- 5:00 fast emphasis
- 7:30 tank emphasis
- 10:00 combined pressure
- 12:00 boss

The director should support continuous background spawning plus scheduled major surge modifiers/events.

## Input Contract

Use Godot Input Map actions rather than hardcoded physical key checks.

Minimum gameplay actions should represent concepts such as:

- move up/down/left/right
- tactical
- ultimate
- toggle aim mode
- pause

Mouse position/direction supplies Manual Aim.

Even though controller support is deferred, conceptual input actions should remain device-agnostic so later controller mapping does not require rewriting gameplay logic.

## Auto Aim Contract

Auto Aim must be centralized enough that character basics can request an aim solution rather than every weapon reinventing target search.

Requirements:

- predictable nearby target selection
- no visible rapid target flicker when several enemies are similar candidates
- efficient enough for dense hordes
- Manual Aim bypasses Auto Aim immediately

Do not prematurely build an elaborate threat-scoring system. Nearest-valid or similarly simple logic is acceptable if it feels good.

## Ability Contract

Tactical and ultimate implementations should expose a consistent runtime interface for:

- can_activate
- activate
- cooldown state
- cooldown completion
- HUD-readable remaining time/percentage
- milestone upgrade application

Specific abilities may instantiate projectiles, apply temporary modifiers, move the player, or create VFX.

Avoid hard-wiring UI directly into ability scripts.

## Weapon Runtime Contract

Shared weapon runtime should support:

- acquisition
- current rank
- rank-up
- automatic activation/cadence
- weapon-specific targeting
- clean cleanup at run end

Rank transitions must be deterministic. Rank 5 is terminal.

After four shared weapons are acquired, the upgrade-choice generator must only pull valid higher ranks for those owned weapons.

## XP and Upgrade Contract

XP system responsibilities:

- receive XP awards from kills
- attract/collect nearby XP entities or equivalent visual pickups
- track current level and threshold
- trigger full game pause on level-up

Upgrade-choice responsibilities:

- generate exactly three valid options
- respect four-weapon slot limit
- respect current ranks
- never offer Rank 6
- never offer an unowned fifth weapon after slots are full
- apply selected acquisition/rank upgrade
- resume run only after valid selection

No reroll state is required.

## Enemy and Horde Architecture

Initial target: several hundred active zombies late in a run on a normal gaming PC.

Recommended approach:

- simple pursuit behaviors
- avoid per-enemy expensive searches/pathfinding unless required
- reuse/pool frequently created entities where profiling justifies it
- keep collision layers/masks narrow
- avoid allocating unnecessary temporary objects every frame
- separate visual feedback from expensive simulation where possible

Do not set an arbitrary Prototype enemy-count gate. Prototype performance passes when density feels representative and remains smooth enough to judge combat.

## Collision Strategy

Keep collision categories explicit and minimal. Likely conceptual groups:

- player body
- enemies
- player projectiles/effects
- enemy/boss attacks
- pickups
- arena obstacles

Do not allow every Area2D/PhysicsBody2D to scan every other category.

Exact Godot node choices should be selected based on profiling and implementation simplicity.

## Damage Model

Use a shared damage/event payload rather than direct cross-script assumptions where practical.

Damage processing should be able to carry at least:

- source
- amount
- damage type/tag if needed later
- knockback vector/strength if applicable
- critical/status metadata only if those systems are actually introduced

Do not build a complex RPG resistance matrix for V1.

## Entity Reuse / Pooling

Pooling or reuse should be considered early for high-frequency entities:

- zombies
- projectiles
- XP visuals
- damage numbers
- frequently spawned VFX

However, implement the simplest reliable version first and profile. Do not spend the Prototype phase building a generalized pooling framework more complicated than the combat system.

## UI Architecture

HUD reads runtime state but does not own gameplay rules.

HUD needs access to:

- player health
- XP / level
- tactical cooldown
- ultimate cooldown
- timer
- four weapon slots + ranks

Upgrade screen owns presentation/selection only; choice validity comes from the progression system.

Core menus:

- title
- character select
- pause
- game over / run summary

## Save Data

Persist only lightweight meta state required by the current design.

Minimum save data:

- total naturally completed runs
- unlocked character ids
- any later V1 achievement/unlock flags that are explicitly added

Do not save:

- active run state
- current run position
- current weapons/ranks
- current health/XP

No permanent stat-upgrade data exists.

Save format should be versioned enough that future additions do not immediately invalidate old saves.

## Unlock Logic

On natural run end:

1. increment completed-run count
2. evaluate unlock conditions
3. unlock Ryan at 1 total completed run
4. unlock Cooper at 3 total completed runs
5. persist state
6. surface newly unlocked content in the game-over/menu flow

A quit/closed mid-run does not increment progression.

## Art Integration Contract

Character sprite scenes should use a consistent template established by Sterling's final sheet.

Runtime should not depend on character-specific hardcoded frame coordinates.

Animation names/conventions should be standardized, for example conceptually:

- run_<direction>
- idle_<direction>
- basic_<direction>
- hurt
- death_<direction or applicable form>

Exact naming can be chosen during scaffold work, but it must be documented before additional character sheets are integrated.

## Performance Validation

Profile at named convergence gates.

Track at minimum:

- frame time / FPS
- active enemy count
- projectile/effect counts
- physics cost
- script time
- spikes during spawn surges
- spikes during level-up pause/resume
- boss plus full-horde cost

If performance fails, optimize the measured bottleneck. Do not rewrite the entire architecture based on speculation.

## Test / Dev Utilities

Codex should create lightweight developer utilities that shorten tuning loops, such as:

- launch directly into a run
- force a character
- force/award XP
- spawn selected enemy types
- jump run timer to a surge/boss phase
- equip/rank selected weapons
- optionally display performance counters

These utilities must stay clearly separated from normal player-facing UI.

## Technical Definition of Done

A system is technically done when:

- it uses the shared data/contracts rather than bespoke cross-dependencies
- its tunable values are exposed appropriately
- it cleans itself up correctly between runs
- it can be exercised through a playable/test path
- it does not introduce known major performance regressions
- its required acceptance criteria in `MILESTONES.md` are satisfied

The architecture exists to accelerate playable iteration, not to become the project itself.
