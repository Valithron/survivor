# Decision Status

This file preserves the planning contract using four states:

- **LOCKED** - explicitly decided and safe to implement.
- **OPEN** - unresolved; implementation should not silently choose if the decision materially changes the product.
- **INFERRED** - likely based on current design, but not explicitly approved as a requirement.
- **DEFERRED** - intentionally postponed until a later milestone.

If another document conflicts with this file, prefer the more specific design document for implementation behavior and update this ledger to remove the conflict.

# LOCKED

## Product

- Genre: bullet-heaven / horde-survival.
- Enemies: zombies.
- V1 playable roster: Sterling, Ryan, Cooper.
- Cydney, Gabi, Kenly, Ashley are not V1 characters.
- One arena through V1.
- Pixel-art presentation with anime influence.
- Mostly top-down camera with loose 3/4 visual read.
- Strong late-run horde pressure.
- Windows-first V1.

## Fantasy and Tone

- Commune personality plus extreme power growth.
- Cool action with real Commune personality and humor.
- Character quips primarily triggered by combat moments such as kill streaks, damage taken, and ultimates.

## Controls

- Manual movement.
- Keyboard + mouse for First Playable and V1.
- Unique basic auto-fires.
- Persistent Auto Aim / Manual Aim toggle for unique basic.
- Manual Aim follows mouse direction.
- Aim toggle affects basic only.
- Directional tacticals use explicit aim/movement input.
- Ultimates follow their own targeting behavior.
- No universal dodge.
- No ammo or reload system.

## Character Model

- Shared weapon pool across characters.
- Unique basic, tactical, ultimate per character.
- Small base-stat differences.
- Strong archetypes.
- Level 5 improves basic.
- Level 10 improves tactical.
- Level 15 improves ultimate.
- Unique basic scales automatically with level.

## Sterling

- Archetype: Speedster.
- Basic: dual pistols, twin alternating rapid fire.
- Movement speed directly increases basic fire rate.
- Tactical: instant reposition burst followed by short fire-rate buff.
- Ultimate: rapid radial projectile bursts while Sterling remains mobile.

## Ryan

- Archetype: Bruiser.
- Basic: combat shotgun, short cone, small knockback.
- Tactical: armored charge in aimed direction, damages and shoves enemies aside.
- Ultimate: several escalating radial impacts ending in one huge shockwave.

## Cooper

- Archetype: Glass Cannon.
- Basic: automatic rifle, continuous rapid projectile stream.
- Tactical: huge damage boost with movement-speed penalty.
- Ultimate: nearly roots Cooper while unleashing extreme sustained damage.

## Shared Weapon System

- Four shared weapon slots per run.
- Six core weapons in the Vertical Slice baseline.
- All six available immediately.
- Exactly three choices per level-up.
- Game fully pauses during level-up choice.
- Normal choices are new shared weapons or upgrades to owned shared weapons.
- Once four slots are full, only owned-weapon upgrades can be offered.
- No rerolls.
- Five total ranks per weapon.
- Rank 5 is the capstone, not a separate evolution.
- Strong runs should commonly end with only one or two maxed weapons.

Core six:

- Throwing Knives
- Katana
- Auto-Turret
- Molotov
- Chain Lightning
- Grenade Launcher

## Enemy Model

- Three normal zombie archetypes.
- Basic swarm.
- Fast fragile.
- Slow tank.
- Normal enemy behavior intentionally simple.
- Rare elite variants use boosted stats only.
- Minimal ordinary knockback outside specific kits/abilities.

## Health / Recovery

- Health is precious.
- Healing is uncommon.
- Static health pickups respawn at fixed arena locations.
- Guaranteed nearby health pickup at boss arrival.
- Extremely rare revive pickup/opportunity is part of the intended game.

## Arena

- The one V1 arena is an **abandoned shopping center** centered on a broad open parking lot.
- Abandoned storefront edges establish the outer environmental identity.
- Scattered abandoned cars, carts/cart returns, and simple lot obstacles create positioning texture without maze-like navigation.
- The central combat space stays open enough for very large zombie hordes.
- Recognizable landmarks make fixed health-pickup locations learnable.
- Environmental detail remains low to moderate so Sterling and the horde dominate readability.

## XP / Economy

- Kills focus on XP.
- Nearby XP flies automatically to the player.
- No general run currency in core V1 design.
- No exact level-at-time table is required.
- Broad XP pacing expectations only.

## Run Structure

- Standard survival timer: 12:00.
- Continuous spawning throughout.
- 2:30 surge: swarm emphasis.
- 5:00 surge: fast emphasis.
- 7:30 surge: tank emphasis.
- 10:00 surge: combined pressure.
- 12:00: final boss arrives.
- Normal late-game spawning continues at full intensity during boss.
- Boss fight typically adds roughly 1 to 2 minutes, but has no hard cap.

## Boss

- Huge multi-mutated zombie horror that remains recognizably humanoid.
- An asymmetrical silhouette is defined by one grotesquely oversized mutated arm plus smaller torso growths.
- Durable and slow.
- Its complete core moveset is exactly three readable attacks:
  - **Ground Slam:** a strong windup, large circular impact telegraph, and damaging radial shockwave.
  - **Sweeping Mutated-Arm Smash:** a long windup and broad frontal arc tied to the oversized arm.
  - **Mutant Charge:** a long straight-line telegraph followed by a heavy rush through the active battlefield.
- Do not add boss summons, phase transformations, ranged/vomit attacks, or other major boss mechanics without a later explicit decision.

## Death / Progression

- Immediate game-over flow with quick restart and character-select options.
- Run counts for unlock progression if it ends naturally by death or victory.
- Any naturally ended run counts regardless of duration.
- Sterling unlocked immediately.
- Ryan unlocks after 1 naturally completed run.
- Cooper unlocks after 3 total naturally completed runs.
- Very light metaprogression only.
- No permanent stat boosts.
- Active runs are not resumable after closing the game.

## Art

- Approximate character scale: 48 to 64 pixels tall.
- 8-direction presentation.
- Author about 5 unique facings and mirror when visually acceptable.
- Player idle: 2 to 3 frames.
- Player run: 6 frames.
- Player basic attack: 2-frame firing/recoil treatment.
- Player hurt: 1 frame.
- Player death: 4 frames.
- Character tacticals/ultimates/shared weapons primarily use separate VFX.
- Zombies use lean run + attack + death animation sets.
- AI-assisted generation with cleanup/normalization.
- User should need very little manual pixel cleanup.
- Strict consistency for palette, scale, perspective, outline, and shading.
- Fully pixel-art UI.
- Medium camera distance.
- Punchy but restrained anime VFX.
- Light screen shake and brief impact flashes.
- Damage numbers on hits.
- Health bars only for elites and boss.
- Simple arena terrain/props so characters and hordes dominate.

## Audio

- Energetic and fun.
- Genre may blend freely.
- Temporary audio acceptable at First Playable.

## Technology

- Godot 4.7.
- GDScript.
- Windows primary V1 platform.
- Several hundred active zombies is the intended late-run class of scale.
- Tuning values exposed through simple Godot Resources.
- Profile before major low-level optimization.
- Parallelize production aggressively but converge frequently into playable builds.

## Milestones

### Prototype

- 3 to 5 minute test.
- Sterling only.
- Full final Sterling sprite sheet required.
- One real zombie sprite required.
- Sterling movement/basic/aim toggle.
- One swarm zombie.
- XP/level-up.
- Katana + Molotov.
- Representative horde density, no fixed numeric target.
- Go/no-go criterion: moving, aiming, and shooting Sterling already feels fun.

### First Playable

- Complete 12-minute Sterling run.
- Boss included.
- Full core run structure.
- All 6 core weapons.
- All 3 normal zombies.
- Real Sterling, zombies, arena/UI baseline.
- Cooper/Ryan not required yet.

### Vertical Slice

- Sterling, Ryan, Cooper playable.
- All 6 core weapons.
- All 3 zombies.
- Boss.
- Surges.
- Unlock progression.
- Real core art.
- Some polish/audio may remain incomplete.

### V1

- Still exactly 3 characters and 1 arena.
- Add roughly 30 to 50 percent more gameplay content after Vertical Slice gap analysis.

# OPEN

The following remain unresolved and should not block current implementation unless the work packet specifically needs them:

- exact per-rank effects for each shared weapon
- exact character base-stat numbers
- exact character tactical/ultimate cooldowns and durations
- exact damage values
- exact XP threshold curve
- exact camera zoom within the approved medium-distance target
- exact normal zombie animation frame counts
- exact implementation/spawn rule for the extremely rare revive pickup
- exact V1 content expansion package after Vertical Slice
- exact achievement list beyond the locked run-count character unlocks

# INFERRED

These are reasonable working assumptions but are not product requirements unless later approved:

- Auto Aim can begin with a nearest-valid-target style heuristic.
- Throwing Knives + Auto-Turret are a sensible first post-Prototype weapon batch.
- Chain Lightning + Grenade Launcher are a sensible second post-Prototype weapon batch.
- Straightforward Godot nodes plus targeted pooling/reuse should handle the intended scale before lower-level server APIs are necessary.

Implementation may use these assumptions when they are low-risk and easily reversible. Do not treat them as immutable design requirements.

# DEFERRED

- Cydney playable character.
- Gabi playable character.
- Kenly playable character.
- Ashley playable character.
- Controller support.
- Web build/export as a supported release target.
- Multiple arenas.
- Deep metaprogression.
- Permanent stat-upgrade tree.
- Run suspension/resume.
- Large achievement/meta system beyond what V1 later selects.
- Any post-V1 content roadmap.

# Change Rule

When a future decision changes a locked item:

1. update the relevant detailed specification
2. update this ledger
3. update `IMPLEMENTATION_HANDOFF.md` if the change affects active Codex work
4. update `PROJECT_GRAPH.md` if dependencies or critical path change
5. do not leave contradictory stale requirements in the repository
