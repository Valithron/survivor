# Milestones

This project uses four named product gates:

1. Prototype
2. First Playable
3. Vertical Slice
4. V1

These are not synonyms. Each gate exists to answer a different question.

# 1. Prototype

## Purpose

Prove that the core combat feel is worth building on.

The Prototype is intentionally short: approximately 3 to 5 minutes.

## Required Content

### Player

- Sterling only
- final production-quality Sterling sprite sheet
- movement
- persistent Auto Aim / Manual Aim toggle for basic attack
- dual-pistol unique basic attack
- movement speed affects Sterling basic fire rate

Sterling tactical and ultimate are not required for Prototype.

### Enemies

- one basic swarm zombie type
- one production-quality zombie sprite set
- simple pursuit/contact pressure
- death and XP award

### Progression

- XP collection
- level thresholds
- full game pause on level-up
- exactly 3 weapon choices
- 4-slot weapon inventory contract in place, even if only two weapons exist in this build
- weapon rank-up flow

### Shared Weapons

- Katana
- Molotov

They should be rankable through the same system intended for later weapons.

### Presentation

- Sterling final art required
- one real zombie required
- other arena/UI/weapon visuals may still be temporary
- enough hit feedback to judge combat

## Prototype Density Requirement

No fixed active-zombie number is locked.

The Prototype should become dense enough to **feel like the intended game** and remain smooth enough to judge movement, aiming, and shooting.

## Prototype Definition of Done

Prototype passes only if all are true:

- Sterling movement is responsive.
- Manual Aim clearly follows mouse aim.
- Auto Aim behaves predictably.
- Toggling aim mode works during continuous fire.
- Dual pistols have satisfying cadence and hit response.
- Moving faster produces a noticeable but controlled fire-rate increase.
- Basic zombie pressure creates real movement decisions.
- XP collection and level-up pause work without breaking combat state.
- Exactly three valid upgrade choices appear.
- Katana and Molotov can be acquired/ranked through the shared framework.
- Combat can reach representative density without obvious unacceptable slowdown.
- Most important: **moving, aiming, and shooting Sterling already feels fun.**

## Failure Loop

If Prototype combat is not fun, do not proceed directly into content expansion.

Return to:

- movement acceleration/speed
- aim behavior
- dual-pistol cadence
- hit feedback
- enemy speed/pressure
- camera/readability

The Prototype is a go/no-go gate for the combat foundation.

# 2. First Playable

## Purpose

Deliver a complete run that is recognizably the intended game, not merely a mechanics demo.

The First Playable centers on Sterling only, but it should contain the complete core run structure.

## Required Run

- 12:00 survival timer
- continuous spawning
- 2:30 swarm surge
- 5:00 fast-zombie surge
- 7:30 tank-zombie surge
- 10:00 combined surge
- 12:00 final boss arrival
- normal late-game spawning continues during boss
- guaranteed nearby health pickup at boss arrival
- boss victory ends run
- player death ends run
- boss fight typically adds roughly 1 to 2 minutes

## Required Sterling Kit

- dual-pistol unique basic
- Level 5 basic milestone
- tactical: instant reposition burst + short fire-rate buff
- Level 10 tactical milestone
- ultimate: rapid radial projectile bursts while mobile
- Level 15 ultimate milestone

Level 15 is not guaranteed to be reached.

## Required Shared Weapons

All six core weapons:

- Throwing Knives
- Katana
- Auto-Turret
- Molotov
- Chain Lightning
- Grenade Launcher

Each:

- supports acquisition
- supports five total ranks
- has a meaningful Rank 5 capstone
- integrates with the same three-choice level-up system

## Required Enemies

- basic swarm zombie
- fast fragile zombie
- slow tank zombie
- rare elite stat variants
- huge mutated zombie boss

## Required Arena Systems

- one large scrolling arena
- non-cramped layout
- simple obstacles/terrain
- fixed respawning health pickup locations
- boss-arrival guaranteed health pickup

## Required Presentation

Real game art required for:

- Sterling
- all 3 normal zombie types
- core arena terrain/props
- core pixel HUD/UI

Weapon VFX may still contain temporary elements if behavior and hit areas are readable.

Temporary audio is acceptable.

## Required HUD

- health
- XP / level
- tactical cooldown
- ultimate cooldown
- timer
- four weapon slots
- weapon ranks
- damage numbers
- elite health bars
- boss health bar

## Required Run End

- death or victory recognized correctly
- quick restart option
- character-select route available, even if only Sterling is currently usable in this milestone
- run summary

Unlock progression is not required to be complete yet.

## First Playable Definition of Done

A player can start as Sterling and complete or lose a full intended run without developer intervention.

The build passes if:

- all four surges occur at intended times
- enemy composition changes are perceptible
- combat escalates meaningfully across 12 minutes
- weapon choices produce materially different builds
- strong runs typically max only 1 to 2 weapons, not all four
- health feels valuable
- fixed healing locations matter
- boss telegraphs remain readable through full horde pressure
- boss + full horde remains technically stable enough to play
- the run already feels like Survivor rather than a scaffold

# 3. Vertical Slice

## Purpose

Prove the complete game model across all V1 characters, content pipelines, unlock progression, and production-quality visual language.

## Required Characters

- Sterling
- Ryan
- Cooper

All three must have:

- production-quality sprites
- unique basic attack
- tactical
- ultimate
- milestone progression
- small stat differentiation
- character-select integration

## Ryan Required Kit

- combat shotgun basic with small knockback cone
- armored charge in aimed direction that damages/shoves enemies
- escalating radial-impact ultimate with huge final shockwave

## Cooper Required Kit

- automatic-rifle continuous fire basic
- damage-overclock tactical with major damage boost and movement penalty
- ultimate that nearly roots Cooper for extreme sustained damage

## Unlock Progression

- Sterling unlocked immediately
- Ryan unlocks after 1 natural run end
- Cooper unlocks after 3 total natural run ends
- death or victory counts
- quitting mid-run does not count
- unlock state persists
- no permanent stat upgrades

## Content Baseline

- all 6 core shared weapons
- all 3 normal zombie types
- elites
- final boss
- 4 timed surges
- one arena
- healing locations
- full core UI

## Art Gate

Production-quality core art for:

- all 3 characters
- all 3 normal zombies
- boss core art
- arena visual language
- UI visual language
- six shared weapon effects
- tactical/ultimate effects

## Audio

Audio direction must be demonstrated, but final polish may remain incomplete.

## Vertical Slice Definition of Done

- each character produces a genuinely different combat rhythm
- shared weapons behave consistently across all characters
- no character requires bespoke progression code
- unlock track functions from fresh save
- full run is completable with each character
- real art and VFX demonstrate the intended final presentation
- performance remains acceptable under late-run horde + boss pressure
- remaining V1 work is expansion/polish rather than discovering the core game

# 4. V1

## Purpose

Ship a satisfying small game worth playing and showing to friends.

## Hard Scope Locks

V1 remains:

- exactly 3 playable characters
- exactly 1 arena
- Windows-first
- keyboard + mouse
- no permanent stat metaprogression
- no run resume
- no controller requirement
- no web requirement

## Content Expansion

After Vertical Slice, perform gap analysis and add roughly **30 to 50 percent more gameplay content** based on what actually feels thin.

Candidate expansion areas:

- additional shared weapons
- additional surge variants
- boss variants or additional boss content
- achievements/unlockable content

Do not lock the exact expansion package before the Vertical Slice is played.

## Core V1 Menus

Required:

- title
- character select
- pause
- game over / run summary

Additional menus should only be added if required by the selected V1 expansion content.

## V1 Polish Requirements

- final balance pass
- final performance pass
- final art/VFX consistency pass
- final audio pass
- bug fixing
- clean save behavior
- Windows packaging
- fresh-save testing
- repeated-run testing

## V1 Definition of Done

V1 should satisfy all of the following:

- all three characters are fun and differentiated
- a fresh player can understand the core loop without developer explanation
- unlock progression works
- at least several distinct viable four-weapon build combinations feel meaningful
- run pacing does not drag across 12 minutes
- surges are perceptible
- boss phase is readable and exciting
- health/healing pressure matters
- late-game combat feels dense and powerful
- no obvious placeholder art remains in core presentation
- audio is coherent
- menus and run transitions are complete
- no known progression/save blockers
- no known performance failure under intended V1 horde density
- project can be packaged and played on Windows without editor dependency

# Review Cadence

Do not wait only for named milestones to create playable builds.

Converge and test after major clusters such as:

- Sterling movement/basic
- XP + upgrades
- Prototype
- each weapon batch
- full enemy roster
- run director
- boss
- First Playable
- Ryan integration
- Cooper integration
- unlock progression
- Vertical Slice
- each V1 expansion cluster
- release candidate

The purpose of frequent convergence is to catch incompatible systems and bad feel early.
