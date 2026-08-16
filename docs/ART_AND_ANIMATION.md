# Art and Animation

## Art Direction

Survivor uses a **medium-detail anime-influenced pixel-art style** with a mostly top-down battlefield view and loose 3/4 character/environment read.

The project should avoid rigid isometric geometry. Character recognition, horde readability, and production efficiency are more important than mathematically consistent isometric projection.

Primary visual priorities:

1. recognizable Commune characters
2. readable silhouettes under horde pressure
3. coherent pixel-art language
4. punchy but restrained anime combat effects
5. simple arena art that supports, rather than competes with, combat

## Character Scale

Target character scale: approximately **48 to 64 pixels tall**, subject to final sprite template tests.

The final choice within that range should be made by testing:

- face/hair/clothing recognition
- readability at the chosen camera distance
- horde density
- animation workload

Do not upscale the art specification merely because more pixels allow more detail. The goal is enough detail to recognize the person without making each sprite expensive to animate or visually dominant over the arena.

## Perspective and Directional Facings

Gameplay should read as 8-directional movement/aiming.

Production rule:

- author 5 unique facings where possible
- mirror left/right-compatible directions to produce the remaining facings
- break mirroring only when a weapon, asymmetrical accessory, or silhouette makes it visibly wrong

The art pipeline should preserve a consistent 3/4 read across all directions.

## Player Animation Specification

Every player character should ultimately support:

### Idle

- 2 to 3 frames
- subtle motion only
- avoid busy looping animation

### Run / Walk

- 6 frames
- primary locomotion animation
- must read clearly at normal gameplay speed

### Unique Basic Attack

- 2-frame firing/recoil treatment per authored facing
- character's unique basic attack is visibly animated on the character
- firing should remain compatible with movement rather than forcing a long stationary attack pose

### Hurt

- 1-frame hurt reaction/flash
- brief enough not to interrupt control responsiveness

### Death

- 4 frames
- readable but concise

### Tactical / Ultimate

Do not create bespoke full-body animation sequences by default.

Tacticals, ultimates, and shared weapons should primarily use:

- independent VFX
- projectiles
- trails
- shockwaves
- particles
- temporary overlays
- camera/impact feedback

Only add new character frames when the effect genuinely cannot read without them.

## Zombie Animation Specification

Zombie animation is intentionally leaner than player animation.

Each of the three normal zombie types needs:

- run/movement
- attack
- death

Idle animation is not required for normal combat behavior.

Zombie frame counts should be kept as low as possible while still reading clearly at gameplay speed. The exact counts may be chosen during asset production, but should remain materially cheaper than the player sheets.

## Prototype Art Gate

The Prototype is not allowed to use a generic placeholder player.

Before Prototype approval:

- Sterling must have his **full final sprite sheet** according to the player animation specification.
- One normal zombie type must have a **real production-quality sprite set**.
- Other zombie types, arena art, UI, and weapon VFX may still be temporary.

This is a deliberate project rule. The first combat test should already feel like Survivor rather than a generic Godot mechanics demo.

## First Playable Art Gate

By First Playable, the following must use real game art:

- Sterling
- all 3 normal zombie types
- core arena terrain/props
- core pixel-art HUD/UI

Some weapon effects may remain temporary, provided their behavior and hit areas are clear.

The boss must be represented as a real, readable game entity for the complete run, but final polish may continue into the Vertical Slice.

## Vertical Slice Art Gate

By Vertical Slice:

- Sterling, Ryan, and Cooper use production-quality sprites
- all 3 normal zombies use production-quality sprites
- boss uses production-quality core art
- arena visual language is established
- UI visual language is established
- all 6 core shared weapons have coherent readable VFX
- character tactical/ultimate effects clearly communicate behavior

Audio and final polish may still be incomplete at this milestone.

## AI-Assisted Asset Workflow

The intended asset-production method is:

`character/reference specification -> AI-assisted generation -> cleanup/normalization -> sprite-sheet assembly -> in-engine validation`

The user is willing to do **very little manual pixel cleanup**. Therefore the pipeline should be designed to produce near-ready assets rather than relying on extensive hand correction later.

### Strict Consistency Requirements

No AI-assisted asset should be treated as production-ready until it is normalized to the project style.

Normalize:

- canvas/sprite scale
- perspective
- silhouette proportions
- palette logic
- outline language
- shading language
- light direction
- frame alignment
- directional consistency
- weapon placement
- transparency/background cleanup

A generated sheet that looks good in isolation but violates project scale or perspective is not accepted.

## Sprite Template Requirement

Before producing the full roster, establish one canonical player sprite-sheet template with:

- frame dimensions
- facing order
- animation row/order convention
- pivot/origin convention
- feet/ground anchor
- hitbox reference
- weapon/recoil alignment reference
- naming convention

Sterling's final sheet should become the first validated implementation of this template.

Similarly, establish a lean canonical zombie template before producing all three enemy types.

## Arena Art

The V1 arena is a large scrolling combat space.

Art density should be low to moderate:

- simple terrain
- simple props
- enough landmarks to orient the player
- fixed health pickup locations should be visually recognizable
- obstacles may create escape routes and positioning decisions

Do not fill the arena with decorative animation or clutter.

The exact environmental theme remains open. Candidate themes were discussed but not locked. Do not silently choose a final setting without explicit approval if that choice materially changes the game's identity.

## HUD and Menus

The UI should be **fully pixel-art styled** and visually coherent with the battlefield.

Combat HUD should show:

- health
- XP / current level
- tactical cooldown
- ultimate cooldown
- run timer
- up to 4 shared weapon slots
- each equipped weapon's current rank

Combat entities:

- show damage numbers on hits
- show health bars for elites and boss only
- do not show normal zombie health bars

Core V1 menus:

- title
- character select
- pause
- game over / run summary

Do not overbuild settings/history/meta menus before V1 needs them.

## VFX and Readability

Target: punchy anime effects with readability preserved.

Use:

- brief impact flashes
- light screen shake
- clear trails/projectiles
- distinct hit effects
- readable telegraphs

Avoid:

- constant camera zooms
- heavy screen shake
- repeated full-screen flashes
- effects that hide the player silhouette
- effects that hide boss telegraphs
- excessive damage-number clutter

Late-game spectacle may become intense, but nearby threats and dangerous boss attacks must remain legible.

## Camera

Camera distance should be medium:

- player remains visually recognizable
- substantial battlefield area remains visible
- several hundred zombie pressure can be represented without the player filling the screen

Final camera zoom should be chosen through in-engine art/readability tests rather than fixed from documentation alone.

## Audio Direction

No single musical genre is locked.

Audio should support energetic, fun combat and may blend:

- anime-action influences
- rock/metal elements
- electronic/chiptune elements
- arcade-style combat sounds

First Playable may use temporary audio.

Vertical Slice should prove the audio direction, but final audio polish may remain incomplete until V1.

## Character Quips

Quips/reactions are primarily combat-triggered.

Good triggers include:

- high kill streak
- meaningful damage taken
- ultimate activation

Keep the pool sparse and avoid constant chatter.

## Art Acceptance Gate

An asset is not accepted solely because the source image looks good.

It must also:

- animate cleanly in Godot
- align correctly across facings
- maintain feet/pivot consistency
- remain readable at gameplay scale
- match the established palette/perspective/shading rules
- avoid distracting jitter between frames
- preserve character recognition during movement
