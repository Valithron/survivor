# Game Vision

## Project Identity

Survivor is a small bullet-heaven / horde-survival game starring stylized pixel-art versions of members of the Commune. The mechanical inspirations are games such as Vampire Survivors and Swarm-style horde modes, but the project must not copy proprietary characters, names, maps, UI, sounds, abilities, or assets.

The V1 roster is Sterling, Ryan, and Cooper. The remaining Commune members are intentionally deferred to a later release.

## Player Fantasy

The dominant fantasy is a blend of two things:

1. **The Commune fighting a zombie apocalypse.** The characters should be recognizable, distinct, and personal enough that playing Sterling, Ryan, or Cooper feels meaningfully different.
2. **Extreme power growth.** A run should escalate from manageable survival into increasingly outrageous bullet-heaven power while the horde becomes more dangerous and visually dense.

The game should not be tuned around constant desperation. Health is precious and mistakes matter, but the player should still experience dramatic offensive growth.

## Tone

The tone is **cool anime action with real Commune personality and humor**.

The characters are not joke characters. Their combat should look legitimate, stylish, and satisfying. Humor comes from recognizable personality, occasional combat-triggered quips, ability flavor, and the premise itself.

Quips should be sparse enough not to become noise. Favor triggers such as:

- large kill streaks
- taking meaningful damage
- activating an ultimate

## Visual Target

The game uses an anime-influenced pixel-art style.

The battlefield perspective is mostly top-down, but characters and world objects should read in a loose 3/4 perspective. Do not use rigid isometric geometry. The goal is to preserve character recognition and dimensionality while keeping horde readability.

Presentation priorities, in order of protection when scope must be cut:

- recognizable Commune characters
- strong pixel/anime presentation
- addictive upgrade choices
- huge zombie hordes

The arena itself should remain comparatively simple so the characters, enemies, and combat effects dominate the screen.

## Combat Feel

Moment-to-moment combat should be active despite the bullet-heaven foundation.

The player manually moves, while the unique basic attack auto-fires. The player can persistently toggle the basic attack between:

- **Auto Aim:** the game chooses a target/direction.
- **Manual Aim:** the basic attack follows mouse aim.

Each character also has:

- one frequent tactical ability
- one longer-cooldown ultimate

Directional tacticals use explicit aim/movement input. Ultimates follow their own designed targeting behavior. The Auto Aim / Manual Aim toggle applies only to the unique basic attack.

There is no universal dodge roll. Survival comes from movement, spacing, terrain awareness, character tools, and build strength.

## Run Fantasy

A standard successful run is tuned around 12 minutes of survival followed by a boss fight that usually adds roughly 1 to 2 minutes.

The emotional shape should be:

`competent survivor -> growing build -> dangerous density -> powerful build under heavy pressure -> combined pre-boss crisis -> boss plus full late-game horde`

The boss does not replace the horde. At 12:00 the boss arrives while normal late-game spawning continues. A guaranteed health pickup appears nearby to give the player a recoverable but not free transition into the final phase.

## Character Identity Model

Characters share the same weapon ecosystem, but each character has a unique combat identity built from:

- unique basic attack
- unique tactical ability
- unique ultimate
- small base-stat differences
- a strong combat archetype

This is the main compromise between personality and scope. Do not create separate weapon trees or bespoke progression economies for every character.

V1 archetypes:

- Sterling: Speedster
- Ryan: Bruiser
- Cooper: Glass Cannon

## Replayability Model

Replayability should come primarily from:

- choosing a different character
- receiving different level-up choices
- committing to different combinations of four shared weapons
- different degrees of weapon completion by the boss
- adapting to the four timed surge phases

A strong run should normally end with only 1 or 2 shared weapons at Rank 5, not a fully maxed four-weapon build. Unfinished builds are intentional and should create reasons to replay.

## Non-Goals

The following are explicitly not part of the current V1 vision:

- 3D character models
- seven playable characters in V1
- multiple arenas in V1
- deep permanent stat metaprogression
- elaborate exploration objectives
- handcrafted special AI for every zombie
- ammunition management or reloading
- a universal dodge mechanic
- controller support before V1 ships
- web deployment as a V1 blocker
- run suspension/resume
- hundreds of hand-authored animation frames per character
- direct copying of content from other commercial games

## Quality Bar

A milestone does not pass because its checklist technically runs.

The game should feel like the intended product as early as practical. In particular, the Prototype must already use the final Sterling sprite sheet and one real zombie sprite. The Prototype go/no-go question is whether moving, aiming, and shooting Sterling already feels fun in a dense enough horde to resemble the intended game.

If that answer is no, development should loop back into combat feel before proceeding deeper into content production.
