# Gameplay Systems

## 1. Core Run Loop

1. Select an unlocked character.
2. Enter the single large scrolling arena.
3. Move manually with keyboard input.
4. Unique basic attack auto-fires continuously.
5. Toggle the basic attack between Auto Aim and Manual Aim.
6. Use character tactical and ultimate abilities manually.
7. Kill zombies.
8. Nearby XP flies automatically to the player.
9. At each level-up, pause the game completely and present three weapon choices.
10. Acquire or rank shared weapons.
11. Survive four hand-authored surge beats.
12. At 12:00, spawn the final boss while late-game zombie spawning continues.
13. Win by killing the boss or lose by dying.
14. Show game-over/run-summary flow with quick restart and character-select options.
15. Record lightweight unlock progression if the run ended naturally by death or victory.

## 2. Movement and Aiming

### Movement

- Manual keyboard movement.
- No universal dodge roll.
- The arena should be large enough to scroll and should not feel cramped.
- Terrain and props may shape movement, but the arena is not an exploration game or maze.

### Basic Attack Aiming

Every character has one unique auto-firing basic attack.

The player can persistently switch between:

- **Auto Aim:** automatic target/direction selection.
- **Manual Aim:** firing direction follows mouse aim.

This toggle affects the unique basic attack only.

### Active Ability Aiming

- Directional tacticals read explicit aim/movement input.
- Ultimates use their own designed behavior.
- Shared weapons generally target/operate automatically according to their own weapon logic.

## 3. Character Kit Structure

Every V1 character has:

- unique basic attack
- tactical ability
- ultimate ability
- small base-stat differences
- archetype identity

Broad cadence targets, to be tuned in data rather than hardcoded as design constants:

- Tactical: approximately 5 to 15 seconds between uses.
- Ultimate: approximately 20 to 40 seconds between uses.

Character kit progression is automatic:

- Level 5: improve the unique basic attack.
- Level 10: improve the tactical.
- Level 15: improve the ultimate.

These milestones are rewards for surviving and leveling well. The game does not guarantee that Level 15 is reached in every run.

Unique basic attacks scale automatically with level. Shared weapon level-up choices should not be diluted by separate character-skill upgrade cards.

## 4. Shared Weapon System

### Core Pool

The Vertical Slice baseline contains six shared weapons:

1. Throwing Knives
2. Katana
3. Auto-Turret
4. Molotov
5. Chain Lightning
6. Grenade Launcher

All six are available from the beginning. They are not metaprogression unlocks.

### Loadout

- Maximum of 4 shared weapons equipped at once.
- Character unique basic attack does not consume a shared weapon slot.
- A full offensive kit is therefore 1 unique basic + up to 4 shared weapons + tactical + ultimate.

### Rank Structure

Each shared weapon has 5 total ranks.

- Rank 1: acquisition.
- Ranks 2 to 4: meaningful improvements.
- Rank 5: dramatic capstone version.

Rank 5 is not a separate evolution item or sixth upgrade. It is the weapon's exponentially strongest intended version.

A successful run should often reach the boss with only 1 or 2 Rank 5 weapons. The player should not routinely complete all four weapons.

### Level-Up Choice Rules

When the player levels up:

- pause gameplay completely
- show exactly 3 choices
- choices are shared-weapon acquisitions or upgrades
- no reroll system in the core version

Before four slots are filled, choices may include new weapons or upgrades to owned weapons.

After four slots are filled, only upgrades to owned weapons may be offered.

No ammo or reload mechanics exist. Weapon cadence is controlled by fire rate, cooldown, attack cycle, and weapon-specific behavior.

## 5. Shared Weapon Behaviors

### Throwing Knives

Role: directional projectile / gunfire analogue.

- fast, narrow volleys
- readable forward pressure
- little default knockback

### Katana

Role: close-range sweep.

- fast crescent slashes around or immediately in front of the player
- strong close-space coverage
- ordinary knockback should remain modest unless a specific rank intentionally changes it

### Auto-Turret

Role: deployable.

- placed/deployed entity
- periodically targets and fires at nearby zombies automatically
- should not require player micromanagement after deployment

### Molotov

Role: persistent area-of-effect.

- creates a lingering fire patch
- rewards positioning and horde pathing
- damages enemies remaining inside the zone

### Chain Lightning

Role: bouncing/chaining attack.

- strikes a target and jumps between nearby zombies
- should visually communicate its chain order without cluttering the screen

### Grenade Launcher

Role: explosive lobbed attack.

- arcing explosive shots
- strong local area damage
- attack arc/landing should remain readable at horde density

## 6. Enemy Model

The three regular zombie types are intentionally simple. Complexity should come from density and composition, not bespoke AI trees.

### Basic Swarm Zombie

- baseline health and speed
- pursues player
- primary threat is contact/melee pressure
- appears throughout the run

### Fast Fragile Zombie

- lower durability
- higher movement speed
- applies positional pressure
- should remain mechanically simple

### Slow Tank Zombie

- high durability
- lower movement speed
- occupies space and makes paths harder to clear
- remains mechanically simple rather than gaining elaborate special abilities

Normal zombie attack presentation may use brief attack animations, but their underlying behavior should remain pursuit/contact focused.

### Elites

- rare tougher variants
- boosted stats only
- no extra AI behavior required for the core version
- elite health bars are visible

## 7. Damage, Health, and Recovery

Health is precious. Mistakes should accumulate.

- Healing is uncommon.
- Do not shower the player with random healing drops from ordinary kills.
- Static health pickups respawn at fixed arena locations.
- At boss arrival, guarantee a health pickup nearby.
- Ordinary attacks use little knockback.
- Strong displacement belongs primarily to specific abilities and Ryan's kit.

An extremely rare revive pickup/opportunity is part of the intended fantasy, but its exact spawn rule is not yet specified. Do not build a revive economy or guaranteed revive system. Treat this as an exceptional pickup to specify during later tuning.

## 8. XP and Leveling

- Kills are focused on XP, not a secondary currency economy.
- Nearby XP automatically flies to the player.
- Pickup behavior should feel generous enough that collection is not the main movement challenge.
- No exact expected level at each timestamp is locked.
- Use broad pacing expectations and tune empirically.
- Players who survive deep into a run should commonly reach meaningful kit milestones, but Level 15 is not guaranteed.

## 9. Run Director and Surge Schedule

The director is hand-authored rather than fully dynamic.

Standard survival timer: **12:00**.

Major surge beats:

- **2:30 - Swarm emphasis**
- **5:00 - Fast-zombie emphasis**
- **7:30 - Tank emphasis**
- **10:00 - Combined pressure**
- **12:00 - Boss arrival**

Continuous spawning occurs between surges. The surges should change the perceived composition and intensity of the fight, not stop the run for separate wave transitions.

## 10. Boss Phase

The final boss is a huge mutated zombie.

Behavioral identity:

- durable
- slow
- several clearly telegraphed area attacks
- must remain readable while ordinary late-game zombies continue spawning at full intensity

At 12:00:

1. boss appears
2. normal late-game horde remains active
3. normal late-game spawning continues
4. guaranteed health pickup appears nearby

A successful boss fight should usually add roughly 1 to 2 minutes, but it is not hard time-limited.

## 11. Death and Run Completion

Default death behavior:

- game over immediately after death presentation
- quick restart option
- quick character-select option
- show run summary

A run counts toward character unlock progression if it ends naturally by either death or victory, regardless of how long it lasted.

Closing the game mid-run does not preserve the run.

## 12. Lightweight Metaprogression

No permanent stat bonuses.

V1 progression is content/unlock based.

Character track:

- Sterling unlocked immediately.
- Ryan unlocks after 1 naturally completed run.
- Cooper unlocks after 3 total naturally completed runs.

The six core shared weapons are available immediately.

## 13. Acceptance Principles

A gameplay system is not done merely because it produces output.

Examples:

### Movement / Basic Combat Done

- controls are responsive
- aim direction is visually obvious
- Auto Aim and Manual Aim both behave predictably
- switching aim modes does not interrupt firing incorrectly
- character identity remains readable under dense combat

### Level-Up System Done

- gameplay fully pauses
- exactly three valid choices display
- no invalid duplicate/illegal acquisition state is presented
- four-slot cap is enforced
- once four slots are filled, only owned weapon upgrades appear
- Rank 5 behaves as the final capstone rank

### Horde System Done

- continuous spawning feels sustained rather than bursty by accident
- surge composition changes are perceptible
- ordinary enemies do not require expensive bespoke AI
- late-run density remains playable and readable

### Boss Done

- telegraphs remain visible through the horde and VFX
- boss health bar is clear
- normal horde spawning continues correctly
- guaranteed health pickup appears at boss arrival
- defeating the boss ends the run cleanly
