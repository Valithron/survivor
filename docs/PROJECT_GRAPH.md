# Project Graph

This project must be reasoned about as two related graphs:

1. **Game Design Graph** - how the player's experience and systems influence each other.
2. **Production / Implementation Graph** - how the game is built, which nodes can run in parallel, and where they must converge.

Do not reduce either graph to a single chronological checklist.

# 1. Game Design Graph

## Core Survival Loop

```text
manual movement
    -> positioning
    -> exposure to zombie pressure
    -> health loss / survival

unique basic + shared weapons + actives
    -> enemy kills
    -> XP
    -> level up
    -> paused 3-choice weapon decision
    -> stronger build
    -> higher kill rate

run timer
    -> continuous spawn escalation
    -> timed surge composition changes
    -> greater positioning pressure
    -> stronger build requirement

12:00
    -> boss arrival
    + full late-game horde continues
    -> final build test
    -> victory or death
```

## Character Identity Loop

```text
character selection
    -> base stats
    + unique basic
    + tactical
    + ultimate
    -> combat rhythm
    -> preferred positioning
    -> perceived character identity
```

Shared weapons intentionally sit beside, not inside, this graph:

```text
shared weapon pool
    -> run-specific build choices
    -> variation across repeated runs
```

This separation is important. Character identity should survive even if two characters roll similar shared weapons.

## Aiming Loop

```text
Auto Aim / Manual Aim toggle
    -> unique basic direction
    -> player attention split
    -> movement freedom vs precision
```

Manual Aim lets the player control basic direction. Auto Aim reduces attention cost. The toggle affects only the unique basic.

## Sterling Loop

```text
move faster
    -> dual-pistol fire rate increases
    -> more mobile damage output

tactical reposition burst
    -> escape/reposition
    -> short fire-rate buff
    -> offensive tempo spike

ultimate
    -> radial bursts while mobile
    -> screen-wide crisis response without losing movement identity
```

## Ryan Loop

```text
shotgun cone
    -> close pressure + modest knockback
    -> space creation

armored charge
    -> break through congestion
    -> damage + shove enemies aside

ultimate
    -> escalating radial impacts
    -> large final shockwave
    -> major crowd reset
```

## Cooper Loop

```text
automatic rifle
    -> high sustained DPS

low survivability
    -> positioning risk

tactical overclock
    -> huge damage boost
    -> movement penalty
    -> commitment decision

ultimate
    -> near-rooted state
    -> extreme sustained damage
    -> maximum risk/reward
```

## Weapon Progression Loop

```text
level up
    -> 3 choices
    -> acquire weapon or rank owned weapon
    -> stronger/changed behavior

4 slots filled
    -> no new weapons offered
    -> choices only rank existing weapons

Rank 5
    -> capstone behavior/power
```

Expected end state:

```text
strong run
    -> only 1-2 weapons usually reach Rank 5
    -> unfinished build remains
    -> replay motivation
```

## Health / Map Loop

```text
rare healing
    + fixed respawning health locations
    -> map landmarks
    -> route/positioning decisions
    -> recovery opportunity
```

The arena is not an exploration system. Health pickup locations create light spatial strategy without turning the map into an objective hunt.

## Surge Loop

```text
0:00-2:30 continuous pressure
2:30 swarm emphasis
5:00 fast emphasis
7:30 tank emphasis
10:00 combined pressure
12:00 boss + full late-game horde
```

Each surge changes composition enough to be felt without creating separate wave-transition downtime.

# 2. Production / Implementation Graph

## Root Decisions

Already locked:

```text
Godot 4.7 + GDScript
Windows-first
keyboard + mouse
one arena
three V1 characters
three normal zombie types
```

These enable all implementation branches.

## Foundation Node

```text
TECH FOUNDATION
    -> project scaffold
    -> Input Map
    -> game/run lifecycle
    -> data Resource contracts
    -> common damage/health interfaces
    -> developer test hooks
```

Foundation is a prerequisite for clean integration, but it should remain thin. It should not attempt to pre-build every future system.

## Prototype Parallel Branches

After foundation contracts are defined, work can split aggressively:

```text
A. PLAYER/COMBAT
    Sterling movement
    aim mode toggle
    dual pistols
    health/damage

B. PROGRESSION
    XP
    level thresholds
    full-pause upgrade screen
    3-choice generator
    weapon inventory/ranks

C. ENEMY/HORDE
    basic swarm enemy
    simple pursuit/contact pressure
    spawning
    death/XP award

D. WEAPON BATCH 0
    Katana
    Molotov

E. ART PIPELINE
    canonical sprite template
    final Sterling sprite sheet
    one production zombie sheet
```

### Prototype Convergence

All five branches converge at:

```text
PROTOTYPE BUILD
```

Prototype cannot pass unless:

- Sterling final art is integrated
- one real zombie is integrated
- movement/basic aiming feels fun
- Katana + Molotov function through the upgrade loop
- horde density feels representative enough to judge combat

If combat is not fun:

```text
Prototype fail
    -> loop back to movement / aiming / firing cadence / hit feedback / enemy pressure
```

Do not continue content expansion just because the code technically works.

# 3. Post-Prototype Expansion Graph

After Prototype passes, work branches again.

## Character/System Branch

```text
complete Sterling tactical + ultimate
    -> cooldown HUD
    -> Level 10/15 milestone integration
```

## Enemy Branch

```text
basic zombie contract
    -> fast zombie
    -> tank zombie
    -> elite stat variants
```

## Weapon Branch

Prototype weapons already present:

- Katana
- Molotov

Remaining four enter in two batches.

Recommended implementation grouping:

```text
Batch 1
    Throwing Knives
    Auto-Turret

Batch 2
    Chain Lightning
    Grenade Launcher
```

This grouping is a production recommendation, not a game-design requirement. Change it if profiling or implementation dependencies make another pairing clearly better.

Each batch must integrate into the same acquisition/rank contract before the next batch begins.

## Run Director Branch

```text
continuous spawn baseline
    -> timed surge scheduler
    -> swarm emphasis at 2:30
    -> fast emphasis at 5:00
    -> tank emphasis at 7:30
    -> combined pressure at 10:00
```

## Arena Branch

```text
large scrolling arena
    -> terrain/obstacle layout
    -> fixed respawning health pickup points
    -> readable landmarks
```

## Boss Branch

Depends on:

```text
enemy damage framework
+ VFX/telegraph framework
+ run timer/director
+ health bar UI
```

Then:

```text
huge mutant boss
    -> slow durable movement
    -> telegraphed area attacks
    -> 12:00 spawn
    -> full horde continues
    -> guaranteed nearby health pickup
    -> victory trigger
```

## First Playable Convergence

Branches converge at a complete Sterling run:

```text
Sterling full kit
+ 6 core weapons
+ 3 normal zombies
+ elites
+ full 12-minute surge schedule
+ boss
+ arena/healing
+ real Sterling/zombie/arena/UI art baseline
+ run end flow
    -> FIRST PLAYABLE
```

# 4. Vertical Slice Expansion Graph

After First Playable, three major branches can run in parallel.

## Ryan Branch

```text
character Resource
-> combat shotgun
-> armored charge
-> escalating impact ultimate
-> milestone behavior
-> final sprite/VFX integration
```

## Cooper Branch

```text
character Resource
-> automatic rifle
-> damage overclock
-> anchored sustained-fire ultimate
-> milestone behavior
-> final sprite/VFX integration
```

## Meta / Unlock Branch

```text
save version/state
-> natural run completion tracking
-> Ryan unlock at 1 run
-> Cooper unlock at 3 runs
-> character-select locked/unlocked presentation
```

These converge with the existing Sterling game at:

```text
VERTICAL SLICE
```

Vertical Slice proves:

- all 3 characters
- all 6 core weapons
- all 3 zombie types
- boss
- surges
- unlock progression
- production-quality core art

Audio/final polish may still be incomplete.

# 5. V1 Expansion Graph

Do not predefine all V1 expansion content before Vertical Slice playtesting.

After Vertical Slice:

```text
playtest + gap analysis
    -> identify thin areas
    -> select 30-50% content expansion
```

Possible independent branches:

```text
additional shared weapons
additional surge variants
boss variants/additional boss content
achievements/unlockable content
```

Hard gates:

- remain at 3 playable characters
- remain at 1 arena
- no permanent stat metaprogression

Then all selected branches converge into:

```text
balance
+ performance
+ final VFX/art/audio
+ menus/run summary
+ bugs
+ Windows packaging
    -> V1
```

# 6. Critical Path

The current critical path to Prototype is:

```text
Godot scaffold + shared contracts
    -> Sterling runtime integration

Sterling art specification
    -> final Sterling sprite sheet

basic zombie runtime
    + one real zombie sheet

XP/upgrade framework
    + Katana
    + Molotov

all converge
    -> Prototype fun gate
```

The art branch is intentionally on the critical path because the Prototype is required to use final Sterling art.

Critical path from Prototype to First Playable:

```text
Prototype fun gate passes
    -> complete Sterling kit
    -> complete weapon pool + enemy roster + run director
    -> boss + arena/healing + UI integration
    -> First Playable full-run gate
```

# 7. Shared Contracts Between Work Packets

Parallel agents must not invent incompatible private interfaces.

Before parallel implementation expands, agree/document contracts for:

- CharacterDefinition Resource
- WeaponDefinition / weapon runtime
- EnemyDefinition / enemy runtime
- damage events
- XP award/death event
- run timer/director events
- ability cooldown interface
- HUD-readable player/ability state
- save/unlock state
- animation naming/pivots

If a work packet needs a contract change, update the relevant documentation and dependent interfaces before silently diverging.

# 8. Validation Gates

Every convergence point should produce a playable build.

Recommended review points:

- movement + dual pistols integrated
- XP + first weapon choices integrated
- Prototype full convergence
- each post-Prototype weapon batch
- full three-enemy horde
- complete 12-minute director without boss
- boss integration
- First Playable
- each new character integrated
- unlock progression integrated
- Vertical Slice
- each V1 content expansion cluster
- V1 release candidate

The user should be able to judge the game frequently. Do not let independent branches remain unintegrated for long periods.
