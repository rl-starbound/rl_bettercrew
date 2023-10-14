# Starbound mod: Better Crew and NPC Behavior

This document details technical and implementation notes for the *Better Crew* mod.

## Compatibility Notes

This mod patches in significant structural changes to the following behavior files:

* `/behaviors/npc/crew/combat.behavior`
* `/behaviors/npc/crew/notifications.behavior`
* `/behaviors/npc/inspect.behavior`
* `/behaviors/npc/npcblink.behavior`
* `/behaviors/npc/patrol.behavior`
* `/behaviors/npc/play.behavior`
* `/behaviors/npc/reactions/comfort.behavior`
* `/behaviors/npc/reactions/flirtwithplayer.behavior`
* `/behaviors/npc/reactions/pianoparty.behavior`
* `/behaviors/npc/reactions/playairhockey.behavior`
* `/behaviors/npc/reactions/watchsleeping.behavior`
* `/behaviors/npc/sit.behavior`
* `/behaviors/npc/sleep.behavior`
* `/behaviors/npc/wander.behavior`
* `/behaviors/tenant/returnhome.behavior`

If this mod is combined with any other mod that modifies any of those behavior files, broken NPC behaviors are likely.

This mod replaces the following bugged Lua functions with improved versions:

* `/npcs/bmain.lua`: `setNpcItemSlot`
* `/scripts/actions/npc.lua`: `swapItemSlots`
* `/scripts/actions/query.lua`: `findLoungable`
* `/scripts/actions/reaction.lua`: `playBehaviorReaction`

If it is combined with any other mod that modifies any of those functions, conflicts will happen.

## Crew Anchor Objects

The inspiration behind this mod is based on the mod *Smart Crew* by metamorphexx. In that mod, each crew type has a hard-coded list of base game objects that attracts that crew type, and on each behavior tick, each crew member searches the player's ship for each object on their type's list and moves to one such object, if found. This struck me as inefficient, because world searches happen on each behavior tick, for each crew member, for each object in the crew type's list.

In my implementation, which shares no code or logic with *Smart Crew*, the crew types that can be attracted to an object are a property of each object. As each crew anchor object is placed into the ship world, it registers itself and its position with the ship's SAIL. When an object is removed, it de-registers itself. On each behavior tick, for each crew member, the SAIL registry is consulted for a random object for that crew type, and the crew member moves to the position, without any computationally expensive world searches. The SAIL console was chosen as the registry object because it is permanently present on all base game ships.

Crew anchor object registration is not persisted to storage. This means that, every time you start your game on your ship, and every time you beam onto your ship, all objects will re-register themselves with SAIL as they are loaded. While this causes a small performance penalty during the loading of the ship world (so small I couldn't actually notice it, but it has to exist), it prevents potential desynchronization issues from accumulating. What I mean by that is, when breaking an object on your ship, if for any reason the de-register code does not run successfully, then SAIL will think that a crew anchor object exists at a position which it does not. If registrations were persisted, these sort of errors would accumulate until the crew were effectively moving randomly around the ship. However, by not persisting registration, the issue will correct itself as soon as you reload the ship world. (No issues with de-registration are currently known. This is simply a case of defensive coding in practice.)

When deciding which base game objects would be enriched with crew anchor tags, I had to make several editorial decisions. First, I only wanted crew being drawn to "interesting" objects related to their job functions. As such, "boring" objects such as ordinary tables, chairs, and so forth, were not considered. Likewise, purely decorative objects such as posters and paintings were not considered. Finally, if an object was interactive, even if it met my other criteria, I generally only gave it crew anchor tags if it was wider than 2 blocks or taller than 5 blocks. I did this because crew will often stand in front of objects with crew anchor tags, and if the object is too small, the player will have trouble interacting with it.

### Adapting Modded Objects With Crew Anchor Tags

Two pieces of metadata must be added to an object to make it a crew anchor object:

1. The script `/scripts/rl_crewanchorobject.lua` must be appended to the object's `scripts` list. If the object is not scripted, then the `scripts` field must be added to the object and its value must be a JSON list containing this script.
1. A new field called `crewAnchorTags` must be added to the object. It must be a JSON list containing at least one string. Each string must be one of the crewmember NPC types that will be attracted to this object.

Once your mod contains at least one crew anchor object, you must add *rl_bettercrew* to the `requires` field in your mod's `_metadata` file. Failure to do so will cause your mod's objects to crash worlds when they are loaded, if players have not also added this mod. Due to the risk of mod incompatibility when adding mods to the `requires` field, it is generally preferable to offer compatibility as an additional mod on top of your mod. That is, if your mod is called *MyMod*, and you wish to add crew anchor tags to its objects, you should create a new mod, let's call it *MyMod Better Crew Compatibility*, have that mod require both *MyMod* and *rl_bettercrew*, and make patches to your objects in that mod.

## Additional Implementation Details

### NPC Freezing

The `moveToPosition` function is used extensively in Starbound behaviors, and I used it in my own shipboard duty stations behaviors. An NPC behavior fires `moveToPosition` with some coordinates, and the NPC plans a route to those coordinates (via a call to Starbound's C++ API) and moves there. If the core engine cannot path-find a route from the NPC's original location to its specified destination, the NPC just stands there and waits, presumably in case a route opens up in the future. There is no built-in timeout functionality in `moveToPosition`. An NPC stuck waiting will continue to wait indefinitely, or until a higher priority behavior is triggered (e.g., combat, or the player interacting with them). A few of the base game uses of `moveToPosition` were wrapped inside of a timeout behavior, but the vast majority were not.

I have altered (what I believe to be) all of the affected behaviors to use a path-finding timeout. I left several of the base game behaviors unmodified because I judged that they were unlikely to result in freezing. In all cases, the unmodified behaviors occurred in instance dungeons with pre-planned and shielded layouts, meaning that it was virtually impossible for the NPCs to encounter unroutable movement requests.

### NPC Personality Effects (Nocturnal)

An additional bug related to NPC sleep and wake times is that nocturnal NPCs go to sleep between times 0.0 to 0.4 and wake up from sleep between times 0.5 and 0.0. Note that these actions overlap when the time of day is exactly 0.0. On player space stations, NPC space stations, terrestrial worlds, and the player ship if orbiting a terrestrial world, this does not matter, because time 0.0 occurs only for an instant. However, Starbound does not manage time on many non-terrestrial worlds, nor on the player ship if not orbiting a terrestrial world. In these environments, the time of day is set permanently to 0.0 and nocturnal NPCs can become stuck in a sleep-wake loop.

I have fixed this by altering nocturnal NPCs' sleep time to be between 0.1 and 0.4. However, due to how NPC personality data is stored, this will only affect new nocturnal NPCs. Existing nocturnal NPCs will continue to exhibit the erroneous behavior on non-terrestrial worlds that have beds.
