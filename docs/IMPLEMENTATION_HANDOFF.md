# Implementation Handoff

**Read this file first in a fresh Codex implementation session.**

This is the operational entry point for building Survivor. Deeper specifications are linked at the end.

# 1. Project Identity

Survivor is a Windows-first, anime-influenced pixel-art bullet-heaven / horde-survival game built in **Godot 4.7 + GDScript**.

The V1 game stars three members of the Commune:

- Sterling
- Ryan
- Cooper

The player moves manually, uses a unique auto-firing basic attack with an Auto Aim / Manual Aim toggle, activates a tactical and ultimate ability, kills escalating zombie hordes, gains XP, pauses on level-up to choose shared weapon upgrades, survives four timed surges, and fights a huge mutant zombie boss at 12:00 while the late-game horde continues.

The intended fantasy is **Commune personality plus extreme power growth**. The tone is cool anime action with real personality and humor.

# 2. Immediate Implementation Objective

**Do not try to build V1 in one task.**

The first implementation objective is the **Prototype**.

Prototype target:

- 3 to 5 minute combat test
- Sterling only
- final Sterling sprite sheet
- one real basic zombie sprite set
- responsive movement
- Sterling dual pistols
- persistent Auto Aim / Manual Aim toggle
- one basic swarm zombie
- XP + level-up
- full pause on level-up
- exactly three weapon choices
- Katana + Molotov using the real shared-weapon rank framework
- horde density high enough to resemble the intended game

The Prototype passes only if **moving, aiming, and shooting Sterling already feels fun**.

If that fails, loop back into combat feel. Do not continue expanding content simply because the code works.

# 3. Technology and Runtime Rules

Locked:

- Godot 4.7
- GDScript
- Windows-first V1
- keyboard + mouse
- controller deferred until after V1
- web export deferred until after V1
- several-hundred-zombie late-run target class

Engineering rules:

- use Godot Input Map actions, not hardcoded key checks
- expose balance/tuning values through custom Resources where practical
- keep gameplay systems independent of UI presentation
- profile before replacing straightforward Godot architecture with low-level optimization
- use pooling/reuse where it provides measured value, especially for frequent entities
- avoid giant character/weapon switch statements
- keep developer test utilities separate from player-facing UI

# 4. Core Gameplay Contract

## Basic Combat

Every character has a unique basic attack that auto-fires continuously.

Persistent aim modes:

- Auto Aim: game chooses basic attack direction/target
- Manual Aim: basic follows mouse aim

The toggle applies only to the unique basic.

There is no ammo/reload system and no universal dodge.

## Actives

Each character has:

- tactical, roughly frequent-use cadence
- ultimate, longer cooldown

Exact cooldowns remain tunable data.

Milestones:

- Level 5 improves basic
- Level 10 improves tactical
- Level 15 improves ultimate

## Shared Weapons

Maximum 4 shared weapon slots.

Core six:

- Throwing Knives
- Katana
- Auto-Turret
- Molotov
- Chain Lightning
- Grenade Launcher

Each has exactly 5 ranks. Rank 5 is the capstone.

Level-up:

- fully pause game
- show exactly 3 valid choices
- choices are weapon acquisition or rank-up
- no rerolls
- after four slots are full, only upgrades to owned weapons may appear

# 5. Character Contracts

## Sterling - Speedster

Basic:

- dual pistols
- twin alternating rapid shots
- current movement speed increases basic fire rate

Tactical:

- instant reposition burst
- followed by short fire-rate buff

Ultimate:

- rapid radial projectile bursts
- Sterling remains mobile

## Ryan - Bruiser

Basic:

- combat shotgun
- short cone
- small knockback

Tactical:

- armored charge in aimed direction
- damages and shoves enemies aside

Ultimate:

- escalating radial impacts
- ends with one huge final shockwave

## Cooper - Glass Cannon

Basic:

- automatic rifle
- continuous rapid projectile stream

Tactical:

- huge damage boost
- movement-speed penalty while active

Ultimate:

- nearly roots Cooper
- extreme sustained damage

# 6. Enemy and Run Contract

Normal zombies:

- basic swarm
- fast fragile
- slow tank

Keep ordinary AI simple. Rare elites are stat-boosted variants only.

Run structure:

- continuous spawning
- 2:30 swarm surge
- 5:00 fast surge
- 7:30 tank surge
- 10:00 combined surge
- 12:00 boss

Boss:

- huge mutated zombie
- slow
- durable
- several readable telegraphed area attacks
- normal late-game zombies continue spawning at full intensity during boss
- guaranteed health pickup appears nearby at boss arrival

Health:

- mistakes matter
- healing uncommon
- static health pickups respawn at fixed map locations

XP:

- kills focus on XP
- nearby XP flies automatically to player
- no general run currency

# 7. Art / Animation Contract

Target character scale: roughly 48 to 64 pixels tall.

Perspective:

- mostly top-down gameplay
- loose 3/4 character/environment read
- 8-direction presentation
- author about 5 facings and mirror when acceptable

Player sheet:

- idle: 2 to 3 frames
- run: 6 frames
- unique basic firing/recoil: 2 frames
- hurt: 1 frame
- death: 4 frames

Tactical/ultimate/shared weapon effects are primarily separate VFX.

Zombies use lean:

- run
- attack
- death

AI-assisted art must be normalized strictly to one project scale, perspective, palette logic, outline/shading language, pivot, and animation template.

**Prototype art gate:** final Sterling sprite sheet + one real zombie sheet are mandatory.

# 8. Save / Unlock Contract

Runs are disposable. No active-run resume.

Persist:

- total naturally completed runs
- unlocked characters
- later explicitly added V1 unlock/achievement flags

Natural run end means death or victory.

Unlock order:

- Sterling immediately
- Ryan after 1 natural run end
- Cooper after 3 total natural run ends

No permanent stat boosts.

# 9. Production Graph and Work Packets

## Packet F0 - Foundation / Runtime Contracts

**This is the first implementation node.**

### Prerequisites

- none beyond this documentation

### Outputs

- Godot 4.7 project scaffold
- Input Map actions
- thin run lifecycle
- custom Resource contracts for characters, weapons, enemies, run profile
- shared health/damage event conventions
- basic developer test entrypoint/hooks
- documented animation naming/pivot convention

### Interfaces

Must support later player, enemy, progression, weapon, UI, and art branches without character-specific switch logic.

### Definition of Done

- project opens/runs cleanly in Godot 4.7
- minimal test scene launches
- Resources can be created/loaded
- input concepts are mapped
- no speculative large framework has been built
- contracts are documented in code/comments or a small developer doc if needed

After F0, parallelize aggressively.

## Packet P1 - Sterling Player / Basic Combat

### Prerequisites

- F0 contracts

### Outputs

- movement
- manual aim vector
- Auto/Manual basic aim toggle
- Sterling dual pistols
- speed-to-fire-rate relationship
- player health/damage

### Interfaces

- reads Sterling Resource
- emits/uses shared damage contract
- exposes HUD-readable state later
- accepts canonical sprite animation contract

### Definition of Done

- responsive movement
- predictable aim behavior
- continuous firing survives aim-mode toggles
- movement/fire-rate relationship is noticeable and bounded

## Packet E1 - Basic Enemy / Spawn Loop

### Prerequisites

- F0 damage/enemy contracts

### Outputs

- basic swarm zombie
- pursuit/contact pressure
- enemy health/death
- XP award event
- repeatable spawning sufficient for Prototype density

### Interfaces

- uses EnemyDefinition
- reports death/XP without directly owning player progression

### Definition of Done

- stable pursuit
- clean death/removal/reuse
- spawning can create representative horde pressure
- no expensive bespoke AI

## Packet X1 - XP / Level-Up / Upgrade Framework

### Prerequisites

- F0
- enemy death/XP event contract agreed

### Outputs

- XP tracking
- XP attraction/collection presentation
- level thresholds
- full-pause level-up state
- three-choice generator
- four-slot shared weapon inventory
- five-rank contract

### Interfaces

- consumes XP awards
- owns valid upgrade-choice rules
- activates weapon acquisition/rank-up through weapon runtime interface
- UI presents choices but does not decide validity

### Definition of Done

- exactly 3 valid choices
- no illegal fifth weapon after slots full
- no Rank 6
- pause/resume clean

## Packet W0 - Prototype Weapons

### Prerequisites

- F0 weapon contract
- X1 acquisition/rank interface agreed

### Outputs

- Katana
- Molotov
- Rank 1 through 5 data/behavior path for each

### Definition of Done

- both acquire/rank through the shared system
- behaviors remain distinct
- Rank 5 is a meaningful capstone

## Packet A1 - Prototype Art Pipeline

This may involve tooling outside Codex, but implementation must support it.

### Outputs

- canonical player sheet template
- final Sterling sprite sheet
- canonical lean zombie template
- one real swarm-zombie sheet

### Definition of Done

- strict style consistency
- correct pivots/alignment
- no distracting frame jitter
- imports/animates correctly in Godot

## Prototype Integration Gate

Merge/integrate P1 + E1 + X1 + W0 + A1.

Build a 3 to 5 minute playable combat test.

**Stop and ask the user to play it.**

Do not start full content expansion until the user judges Sterling movement/aiming/shooting fun enough to proceed.

# 10. Post-Prototype Work Packets

After Prototype approval, split into parallel branches.

## P2 - Complete Sterling Kit

- tactical reposition + fire-rate buff
- ultimate radial bursts while mobile
- Level 5/10/15 milestone behavior
- cooldown state

## E2 - Enemy Roster

- fast zombie
- tank zombie
- elite stat variants

## W1 - Weapon Batch 1

Recommended:

- Throwing Knives
- Auto-Turret

Integrate and playtest before next batch.

## W2 - Weapon Batch 2

Recommended:

- Chain Lightning
- Grenade Launcher

Then balance all six as a pool.

## R1 - Run Director

- continuous baseline spawning
- fixed surge schedule at 2:30 / 5:00 / 7:30 / 10:00
- composition emphasis changes
- 12:00 boss event hook

## M1 - Arena / Healing

- large scrolling arena
- simple obstacles/props
- fixed respawning health pickups
- readable landmarks

Exact environment theme is still OPEN and should be approved before final arena art commits to a strong setting.

## B1 - Boss

- huge mutant boss runtime
- telegraphed area attacks
- boss health bar contract
- horde continues during fight
- guaranteed nearby health pickup at spawn
- victory termination

## U1 - Core HUD / Run Flow

- health
- XP/level
- cooldowns
- timer
- weapon slots/ranks
- damage numbers
- elite/boss bars
- title/select/pause/game-over/run-summary shell as needed for milestone

# 11. First Playable Gate

Converge all post-Prototype branches into a complete Sterling run.

Must contain:

- complete Sterling kit
- six core weapons
- three normal zombie types + elites
- 12-minute run director
- boss
- arena/healing
- core HUD
- real Sterling/zombie/arena/UI baseline art

Temporary audio and some weapon-effect polish are acceptable.

Do not call a shorter systems build First Playable.

# 12. Vertical Slice Work Packets

After First Playable:

## C-RYAN

Implement Ryan against existing contracts. Do not fork core systems.

## C-COOPER

Implement Cooper against existing contracts. Do not fork core systems.

## META-1

Implement save/unlock track:

- completed run counter
- Ryan at 1
- Cooper at 3
- locked/unlocked character-select state

## ART-ROSTER

Finish Ryan, Cooper, boss, abilities, and six-weapon production art/VFX.

All converge into Vertical Slice.

# 13. V1 Scope

Do not invent the final V1 expansion package before Vertical Slice playtesting.

After Vertical Slice, perform gap analysis and select roughly 30 to 50 percent additional gameplay content from areas such as:

- more shared weapons
- more surge variants
- boss variants/additional boss content
- achievements/unlockable content

Hard V1 limits remain:

- 3 characters
- 1 arena

Then complete balance, performance, final art/VFX/audio, menus, bugs, save validation, and Windows packaging.

# 14. Critical Path

To Prototype:

```text
F0 Foundation
    -> P1 / E1 / X1 / W0 in parallel

art specification
    -> A1 final Sterling + one zombie

P1 + E1 + X1 + W0 + A1
    -> Prototype integration
    -> user fun gate
```

To First Playable:

```text
Prototype approved
    -> P2 + E2 + W1/W2 + R1 + M1 + B1 + U1
    -> frequent playable convergence
    -> First Playable
```

To Vertical Slice:

```text
First Playable
    -> Ryan + Cooper + unlock progression + roster art/VFX
    -> Vertical Slice
```

# 15. Non-Goals for Implementation Agents

Do not add these unless the documentation is explicitly changed:

- additional V1 playable characters
- second arena
- controller support
- web-release blockers
- permanent stat progression
- ammo/reload economy
- rerolls
- universal dodge
- run resume
- complicated normal-zombie AI
- deep RPG damage/resistance taxonomy
- elaborate dynamic spawn director replacing the fixed surge structure
- proprietary copied assets/content

# 16. How to Handle Ambiguity

Before asking the user an implementation-trivia question, prefer the simplest reversible engineering choice consistent with these docs.

Ask the user when an unresolved choice materially changes:

- player experience
- art identity
- content scope
- progression
- milestone definition

Current meaningful OPEN items are tracked in [`DECISION_STATUS.md`](DECISION_STATUS.md).

# 17. Source Documents

Read these when working on the relevant packet:

- [`GAME_VISION.md`](GAME_VISION.md) - intent, tone, experience, non-goals
- [`GAMEPLAY_SYSTEMS.md`](GAMEPLAY_SYSTEMS.md) - gameplay behavior and system acceptance rules
- [`CHARACTERS_AND_CONTENT.md`](CHARACTERS_AND_CONTENT.md) - character kits, weapons, enemies, boss, unlocks
- [`ART_AND_ANIMATION.md`](ART_AND_ANIMATION.md) - sprite/VFX/UI pipeline
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) - runtime contracts and technical principles
- [`PROJECT_GRAPH.md`](PROJECT_GRAPH.md) - dependency/parallelization graph
- [`MILESTONES.md`](MILESTONES.md) - named release gates
- [`DECISION_STATUS.md`](DECISION_STATUS.md) - locked/open/inferred/deferred ledger

# 18. Instruction to the First Codex Session

Begin with **Packet F0 - Foundation / Runtime Contracts**.

Do not implement the complete game in the first pass.

Once F0 is clean enough to support the Prototype branches, split work according to the graph, integrate frequently, and target the Prototype acceptance gate above.
