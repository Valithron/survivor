# Characters and Content

## Scope

The V1 playable roster is intentionally limited to three Commune members:

1. Sterling
2. Ryan
3. Cooper

Cydney, Gabi, Kenly, and Ashley are deferred to a later version. Do not build hidden placeholder character systems around seven V1 characters. The architecture should remain extensible, but current content production is for three.

All three characters use the same shared weapon pool. Their identity comes from:

- unique basic attack
- unique tactical
- unique ultimate
- small base-stat differences
- archetype-specific strengths and weaknesses

Character kits should prioritize fun first, then incorporate personality and recognizable flavor. Do not force real-life references into mechanics if they make the gameplay worse.

## Global Character Rules

- Unique basic attacks auto-fire continuously.
- Basic attack uses the persistent Auto Aim / Manual Aim toggle.
- Manual Aim follows mouse direction.
- Auto Aim chooses an appropriate nearby target/direction.
- Character tacticals do not inherit the Auto/Manual toggle. They use explicit aim or movement input as specified.
- Character ultimates use their own behavior.
- No ammo or reloads.
- Base stats may differ modestly in health, speed, damage, or cooldown-related tuning.
- Level 5 improves the unique basic.
- Level 10 improves the tactical.
- Level 15 improves the ultimate.
- Exact numeric values belong in editable Godot Resources and should be tuned through playtesting.

# Sterling

## Archetype

**Speedster**

Sterling should feel best while constantly repositioning. His identity is rapid ranged pressure, movement tempo, and maintaining offense while mobile.

## Base Stat Direction

Do not hardcode final values during planning, but his relative profile should lean toward:

- above-average movement speed
- high basic attack cadence
- moderate survivability rather than tankiness

## Unique Basic: Dual Pistols

- Visual weapon: dual pistols.
- Pattern: twin alternating rapid-fire shots.
- Auto-fires continuously.
- Current movement speed directly increases basic fire rate.
- The speed-to-fire-rate relationship must be capped or curved so later movement bonuses cannot create unbounded cadence.
- Level 5 milestone improves this basic in a clearly noticeable way.

### Feel Requirement

The dual pistols are part of the Prototype go/no-go gate. Moving and aiming Sterling while the pistols fire must already feel fun before deeper production continues.

## Tactical: Reposition Burst

Behavior:

1. Sterling performs an instant reposition burst.
2. Immediately afterward, he receives a short fire-rate buff.

The tactical should be used frequently enough to create tempo, not saved like an ultimate.

Design intent:

- escape pressure
- cross a dangerous gap
- reposition to exploit a line of enemies
- convert movement into a brief offensive spike

## Ultimate: Radial Bullet Storm

- Rapid radial projectile bursts fire in all directions.
- Sterling remains able to move during the ultimate.
- It should feel like screen-wide offensive escalation without hiding the player or boss telegraphs.

## Character Loop

`move quickly -> fire faster -> reposition burst -> temporary firing spike -> continue moving -> radial ultimate during crisis`

# Ryan

## Archetype

**Bruiser**

Ryan is aggressive, moderately durable, and excels at creating room through impact and displacement.

## Base Stat Direction

Relative profile should lean toward:

- above-average durability
- lower tempo than Sterling
- close/mid-range pressure
- access to meaningful displacement through his unique kit

## Unique Basic: Combat Shotgun

- Visual weapon: combat shotgun.
- Pattern: short cone blast.
- Applies small knockback.
- Knockback should be noticeable but not so strong that the basic permanently trivializes horde approach.
- Level 5 milestone improves the basic in a visible way.

Ryan's shotgun is one of the few ordinary attacks allowed to meaningfully move enemies because displacement is central to his identity.

## Tactical: Armored Charge

- Charges in the aimed direction.
- Damages enemies in the path.
- Shoves enemies aside.
- Should allow Ryan to force open a route through crowd pressure.

The ability should feel committed and physical, not like a teleport.

## Ultimate: Escalating Impact Sequence

- Several radial impacts occur around Ryan.
- Impacts escalate in strength/readability.
- Sequence culminates in one huge final shockwave.

The final hit should be a major crowd-control and spectacle moment while preserving battlefield readability.

## Character Loop

`hold ground -> shotgun pressure -> charge through congestion -> re-establish space -> escalating shockwave ultimate during heavy encirclement`

# Cooper

## Archetype

**Glass Cannon**

Cooper should output exceptional sustained damage while being unusually vulnerable to mistakes.

## Base Stat Direction

Relative profile should lean toward:

- very low health or otherwise clearly lower survivability
- weak recovery margin
- very high sustained damage potential

## Unique Basic: Automatic Rifle

- Visual weapon: automatic rifle.
- Pattern: continuous stream of rapid projectiles.
- Auto-fires continuously.
- Level 5 milestone improves the basic in a visible way.

The rifle should communicate reliable sustained DPS rather than burst damage.

## Tactical: Damage Overclock

- Grants a huge damage boost while active.
- Reduces movement speed while active.

This is an intentional commitment tradeoff. The player chooses whether current positioning is safe enough to sacrifice mobility for damage.

## Ultimate: Anchored Sustained Fire

- Cooper becomes nearly rooted in place.
- In exchange, he unleashes dramatically increased sustained damage.

The ultimate should feel dangerous to activate in a bad position and devastating in a good one.

## Character Loop

`maintain firing lane -> exploit high base DPS -> choose safe moment to overclock -> accept reduced mobility -> nearly anchor for overwhelming ultimate damage`

# Shared Weapon Pool

The core six shared weapons are available immediately to all characters.

## Throwing Knives

Attack family: directional projectile.

- fast narrow volleys
- precision/line pressure
- little ordinary knockback

## Katana

Attack family: close-range sweep.

- fast crescent slashes
- protects immediate space
- one of the two Prototype shared weapons

## Auto-Turret

Attack family: deployable.

- deploys an autonomous turret
- turret periodically fires at nearby zombies
- should not require manual aiming after deployment

## Molotov

Attack family: persistent area-of-effect.

- creates lingering fire patch
- damage persists over time
- rewards pathing through and around zones
- one of the two Prototype shared weapons

## Chain Lightning

Attack family: bouncing/chaining.

- jumps between nearby zombies
- emphasizes clustered horde damage

## Grenade Launcher

Attack family: explosive lobbed attack.

- arcing projectiles
- area explosion on landing
- should remain readable at high density

# Weapon Rank Contract

Each weapon has five ranks total.

Rank 5 is the capstone version, not a separate evolution system.

Every weapon rank should materially change at least one of:

- damage
- cadence
- area
- projectile count
- persistence
- targeting capacity
- deployment capacity
- chaining behavior
- another weapon-specific property

Rank 5 should have a noticeable qualitative or exponential-feeling jump. Do not make Rank 5 merely another small percentage increase.

Exact per-rank effects remain to be designed and tuned during weapon implementation. They are not locked in planning.

# Enemy Roster

## Swarm Zombie

Role: baseline horde body.

- ordinary movement
- ordinary durability
- contact/melee pressure
- high numbers

## Fast Zombie

Role: fragile positional threat.

- high speed
- low health
- reaches openings quickly
- no bespoke special ability required

## Tank Zombie

Role: slow space denial.

- high health
- low speed
- difficult to clear quickly
- no bespoke special ability required

## Elites

Any of the three normal archetypes may appear as a rare elite variant.

Elites:

- use boosted stats
- retain the same underlying behavior
- receive a visible health bar
- should not require new animation/AI systems

# Final Boss

Behavior is locked; final visual design is not.

Core identity:

- huge mutated zombie
- slow
- durable
- several telegraphed area attacks
- fought while ordinary late-game zombies continue spawning at full intensity

The boss must test build power without making screen readability collapse.

The exact visual silhouette, mutation theme, attack list, and art treatment remain open until concept/art work begins.

# Unlock Progression

- Sterling: unlocked immediately.
- Ryan: unlock after 1 naturally completed run.
- Cooper: unlock after 3 total naturally completed runs.

A naturally completed run means the run ended by death or victory. Quitting/closing the game mid-run does not count.

The system should be data-driven enough that future characters can use similar unlock conditions without rewriting the progression manager.

# V1 Expansion Rule

The Vertical Slice baseline contains the complete three-character roster, three normal zombie archetypes, final boss, and six core shared weapons.

After the Vertical Slice, V1 should add roughly 30 to 50 percent more gameplay content based on what playtesting reveals is actually thin. Likely candidates include:

- more shared weapons
- more surge variants
- boss variants or additional boss content
- more achievements/unlockable content

The exact V1 expansion mix is intentionally deferred.

Hard constraint: V1 remains exactly three playable characters and one arena.
