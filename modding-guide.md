# Better Crew & NPC Behavior: Modding Guide

This document provides detailed technical discussion of *Better Crew & NPC Behavior*, aimed at an audience of modders. Casual users should refer to the [user guide](user-guide.md) instead. Modders should also be familiar with that guide, especially the [compatibility notes](user-guide.md#compatibility-notes).

## Crew Anchor Objects

The inspiration behind this mod is *Smart Crew* by metamorphexx. In that mod, each crew type has a hard-coded list of objects that attract that crew type, and on each behavior tick, each crew member on the player's ship performs world searches for each object on their type's list and moves to one random object. This struck me as inefficient, because world searches happen on each behavior tick, for each crew member, for each object in the crew type's list.

In my implementation, which shares no code with *Smart Crew*, the crew types that can be attracted to an object are a property of each object. As each crew anchor object is placed into the ship world, it registers itself and its position with the ship's SAIL. When an object is removed, it de-registers itself. On each behavior tick, for each crew member, the SAIL registry is consulted for a random object for that crew type, and the crew member moves to the registered position, without any computationally expensive world searches. The SAIL console was chosen as the registry object because it is permanently present on all base game ships.

Crew anchor object registration is not persisted to storage. This means that, every time you start your game on your ship, and every time you beam onto your ship, all objects will re-register themselves with SAIL as they are loaded. While this causes a small performance penalty during the loading of the ship world (so small I don't notice it, but it has to exist), it prevents potential desynchronization issues from accumulating. What I mean by that is, when breaking an object on your ship, if for any reason the de-register code does not run successfully, then SAIL will think that a crew anchor object exists at a position which it does not. If registrations were persisted, these sort of errors would accumulate until the crew were effectively moving randomly around the ship. By not persisting registration, the issue will correct itself as soon as you reload the ship world. (No issues with de-registration are currently known. This is simply a case of defensive coding in practice.)

### Which Objects Should be Crew Anchor Objects?

When deciding which objects should be enriched with crew anchor tags, I made several editorial decisions. First, I only wanted crew being drawn to "interesting" objects related to their job functions. As such, "boring" objects such as ordinary tables, chairs, and so forth, were not considered. Likewise, purely decorative objects such as posters and paintings were not considered. Finally, if an object was interactive, even if it met my other criteria, I generally only gave it crew anchor tags if it was wider than 2 blocks or taller than 5 blocks. I did this because crew will often stand in front of objects with crew anchor tags, and if the object is too small, the player will have trouble interacting with it.

### Adapting Modded Objects With Crew Anchor Tags

Two pieces of metadata must be added to an object to make it a crew anchor object:

1. The script `/scripts/rl_crewanchorobject.lua` must be appended to the object's `scripts` list. If the object is not already scripted, the `scripts` field must be added to the object and its value must be a JSON list containing this script. See examples in this repo of a pattern for adding the `scripts` field to an object while minimizing the risk of a mod conflict, for example, [outpostgenerator](rl_bettercrew/objects/outpost/outpostgenerator/outpostgenerator.object.patch).
1. A new field called `crewAnchorTags` must be added to the object. It must be a JSON list containing at least one string. Each string must be one of the crew NPC types that will be attracted to this object.

If your mod adds a custom SAIL console, you must adapt it to support crew anchor tags:

1. The script `/scripts/rl_crewanchormanager.lua` must be appended to your SAIL console object's `scripts` list.
1. The field `keepAlive` must be added to the SAIL console object, and it must be set to true.

If your mod adds custom crew NPC types, you should add appropriate crew anchor tags for those crew types to your mod's custom objects. You should also consider patching base game objects, when appropriate, with additional tags for your custom crew types.

Once your mod contains at least one crew anchor object or SAIL console, you must add *rl\_bettercrew* to the `requires` field in your mod's `_metadata` file. Failure to do so will cause your mod's objects to crash worlds when they are loaded, if users have not also added this mod.

Due to the risk of mod incompatibility when adding mods to the `requires` field, it is generally preferable to offer compatibility as an additional mod on top of your mod. That is, if your mod's metadata name is *my\_mod*, and you want to add crew anchor tags to its objects, the best practice is to create a new mod, let's give it the metadata name *my\_mod\_\_compat\_\_rl\_bettercrew*, make patches to your objects in that mod, and have that mod require both *my\_mod* and *rl\_bettercrew* in its `requires` field.

## Expendable Item Replacements

Some NPCs are equipped with expendable items, such as pet capture pods. These items are expended on use, leaving the NPC with an empty hand. The NPC can swap to their sheathed weapon set, but the base game contains no functionality to replace the items in the empty item slots. For example, cultist generals are fairly weak, because they have only a sniper rifle, no usable melee weapon, and are susceptible to crowding once their pet is killed.

In *Better Crew* I introduce the concept of expendable item replacements. To give an NPC type a replacement for an expendable item, use a patch similar to the following:

```
{
  "op" : "add",
  "path" : "/scriptConfig/expendableItemReplacement",
  "value" : {
    "primary" : [ "npcbroadsword", "npcshortsword" ],
    "alt" : "commonsmallshield"
  }
}
```

When the expendable item is used, the `primary` item is set to null, so it (and any pre-existing `alt` item) is replaced by the contents of the `expendableItemReplacement` field. If either replacement slot is undefined or null, then that slot will be empty. If either slot is a list, then one item will be chosen at random from the list. If the `primary` is a two-handed item, then the `alt` is not equipped. In the above example, if the game randomly chooses the broadsword, then the shield is not equipped, but if the shortsword is chosen, then the shield will be equipped.

When designing the replacement item set for an NPC type, keep in mind that the combat behavior can only use a weapon in the `primary` slot, and can only use a shield in the `alt` slot, and only if the `primary` is a melee weapon. Furthermore, combat behavior can only swap from melee to ranged, or from ranged to melee; it cannot swap from ranged to ranged or melee to melee.

I have implemented expendable item replacements for cultist generals and Glitch evil lords. These mini-boss NPCs are now more formidable adversaries.

## Replacements for Faulty Behaviors

This mod contains fixes for several faulty base game behavior actions. Mods that require *Better Crew* should prefer to use the replacements over their faulty base game counterparts.

* `/scripts/actions/movement.lua`: `move`
* `/scripts/actions/movement.lua`: `moveToPosition`
* `/scripts/actions/movement.lua`: `openDoors`
* `/scripts/actions/movement.lua`: `closeDoors`
* `/scripts/actions/npc.lua`: `friendlyTargeting`
* `/scripts/actions/npc.lua`: `swapItemSlots`
* `/scripts/actions/projectiles.lua`: `projectileAimVector`
* `/scripts/actions/query.lua`: `findLoungable`
* `/scripts/actions/reaction.lua`: `playBehaviorReaction`
* `/scripts/actions/world.lua`: `entityPosition`

### NPC Spinning

Sometimes an NPC would be observed running back and forth over a single block. This occurred if an NPC performed a `move` action while directly above or below their home position. In this action, the `direction` argument is reinterpreted on each tick. Thus, if the NPC moved across the X-axis of their spawn position, the direction of motion would flip, causing the NPC to begin running back and forth over the block. An NPC stuck like this would continue to spin indefinitely, or until a higher priority behavior was triggered, such as combat or player interaction.

I have implemented a new behavior action, `rl_bettercrew_moveUnidirectionally`, in which the `direction` argument is interpreted only once, at the beginning of the invocation. Mods that require *Better Crew* should consider whether to use this action instead of the base game's `move` action.

### NPC Freezing

The `moveToPosition` action is used extensively in NPC behaviors. An NPC behavior invokes `moveToPosition` with positional coordinates, the core engine plans a route to that position, and the NPC moves there. However, if the core engine cannot path-find from the NPC's current position to its destination, the NPC stands still and waits, presumably in case a route opens up in the future. There is no built-in timeout functionality in `moveToPosition`. An NPC stuck waiting will continue to wait indefinitely, or until a higher priority behavior is triggered, such as combat or player interaction. A few of the base game invocations of `moveToPosition` were wrapped inside of a timeout, but the vast majority were not.

I have altered all of the affected base game behaviors to use a path-finding timeout. A list can be found in [moveToPosition.csv](moveToPosition.csv). I left several of the base game behaviors unmodified because I judged that they were unlikely to result in freezing. In most cases, the unmodified behaviors occurred in instance dungeons with pre-planned and shielded layouts, meaning that it was virtually impossible for the NPCs to encounter unroutable movement requests.

In addition to the lack of a native timeout, the `moveToPosition` action contains a second flaw. The action is asynchronous, which means it is intended to be invoked over the course of multiple clock ticks. If, on the second to last clock tick, the action yields with `pathfinding` true, and then on the last clock tick, it succeeds or fails, then the `pathfinding` variable will not be reset, and will continue to be true. This may cause erroneous behaviors, especially with the timeout wrapper. I have replaced all action invocations in the base game with `rl_bettercrew_moveToPosition`, a copy that properly resets the yielded variables `pathfinding` and `direction`. Mods that require *Better Crew* should use this action instead of `moveToPosition`.

### NPCs Closing Doors in Your Face and Leaving Hatches Open

The `closeDoorsBehind` function is called in `moveToPosition` after each tick of movement. For doors about to be closed, it checked for other NPCs in the doorway, but did not check for players. Additionally, it is clear that it was written only with doors in mind, not hatches. It occasionally closed a hatch through which the NPC passed, but accidentally, not intentionally. It could also miss closing some doors, especially behind fast NPCs, and could also close some doors and hatches through which the NPC did not pass.

The `rl_bettercrew_moveToPosition` action calls a new function, `rl_bettercrew_closeDoorsBehind`, which reimplements the logic to determine which doors to close so that it more consistently closes both doors and hatches through which the NPC passed, and not doors and hatches through which the NPC did not pass. It also checks for both NPCs and players in a doorway before closing the door. Mods that require *Better Crew* should use this action instead of `moveToPosition`.

### NPCs Opening and Closing Doors Unnecessarily

The base game actions `openDoors` and `closeDoors` rely on a call to the core engine to find doors that need to be opened or closed while an NPC is performing unpathed movement (e.g., fleeing, patrolling, or wandering). Due to its quirks, the core engine sometimes returns doors that do not intersect the bounds specified in those functions, causing NPCs to open or close doors unnecessarily.

This mod provides the new actions `rl_bettercrew_openDoors` and `rl_bettercrew_closeDoors`, which contain additional code to ensure that the doors opened or closed actually intersect the specified bounds. Mods that require *Better Crew* should use these actions instead of `openDoors` and `closeDoors`.

### Guards Respond to Friendly Fire

In the base game, village guards cannot recognize or respond to friendly fire due to numerous faults in the base game behavior action, `friendlyTargeting`.

I have fixed these faults in a new behavior action, `rl_bettercrew_friendlyTargeting`, and have replaced all base game invocations with the fixed version. Mods that require *Better Crew* should use this action instead of `friendlyTargeting`.

### NPC Item Swapping

The base game contains the faulty NPC function `setNpcItemSlot` and the faulty behavior action `swapItemSlots`. These faulty functions could result in NPCs losing item sets and becoming disarmed when they swap items.

I have replaced `setNpcItemSlot` with a patch to the base NPC type, so all NPC types automatically use the fixed version.

I have also created a new behavior action `rl_bettercrew_swapItemSlots`, and have replaced all base game invocations with the fixed version. Mods that require *Better Crew* should use this action instead of `swapItemSlots`.

### Aiming Arrows With Precision

Determining a firing solution for a projectile that follows a parabolic trajectory (e.g., arrows) involves invoking the `projectileAimVector` action with the projectile speed and the desired destination position. The action returns an aim angle, expressed as a vector. However, the action normalized the vector. While unnormalized and normalized vectors produce the same angle in pure mathematics, when floating point arithmetic is involved, normalizing produces a loss of precision. For small projectiles, only a single pixel wide, this could be the difference between hitting a target and missing it.

In the dynamics of the game, this discrepancy was not usually noticeable. However, in certain circumstances, for example, when an NPC was firing an arrow in a long shot toward a stationary target, it could be quite noticeable.

The ranged combat behavior logic appeared to attempt to compensate for this loss of precision by multiplying the aim vector by 10, and by setting the projectile speed passed into the action to 62.5, when the actual arrow speed was 50. This resulted in arrows being aimed slightly below their intended target. Setting the actual arrow speed to 62.5 resulted in arrows being aimed above their intended target.

I have created a new action, `rl_bettercrew_projectileAimVector`, which operates similarly to `projectileAimVector`, except that it does not normalize the returned vector. I have replaced the invocation of `projectileAimVector` in the ranged combat behavior with this new action and have eliminated the vector multiplication that came after it. These changes are not perfect, and setting the actual arrow speed to 62.5 still results in arrows being aimed slightly above their intended target. However, setting the actual arrow speed to 58 results in a very high degree of accuracy.

Future work could improve this result, until the projectile speed passed into the action equals the actual projectile speed, which results in perfectly aimed shots. However, floating point arithmetic being what it is, a measure of imprecision is inevitable.

Mods requiring *Better Crew* may choose to invoke the `rl_bettercrew_projectileAimVector` action instead of `projectileAimVector` when precision aiming is important. Even then, experimentation will be needed to determine the ideal projectile speed to pass into the action, and the ideal actual projectile speed. In the context of arrows aimed using this action, when the projectile speed passed into this action is 62.5, the ideal actual projectile speed appears to be 58.

### Find the Nearest Loungable

Due to programmer error, the base game's `findLoungable` action ignored the arguments `orderBy` and `withoutEntityId`. Among other issues, this meant that behaviors anticipating receiving the nearest loungable might instead receive a random loungable within the specified range.

I have created a new behavior action `rl_bettercrew_findLoungable`, and have replaced all base game invocations with the fixed version. Mods that require *Better Crew* should use this action instead of `findLoungable`.

### NPC Personality Effects

NPC personality was not used in the behavior tree, so some NPC personality types did not behave as documented. The culprit was the faulty base game action `playBehaviorReaction`.

I have replaced all invocations in the base game with a new behavior action, `rl_bettercrew_playBehaviorReaction`, which properly passes the NPC's personality information into the behavior tree. Mods that require *Better Crew* should use this action instead of `playBehaviorReaction`.

### NPCs Aim Above Crouching Players

The base game `entityPosition` action returns the position in the world at which the entity exists. In most cases, this is a good surrogate for, "where should an NPC aim a weapon to hit this entity?". However, when a humanoid NPC or player (of all base game and most modded races) crouches, their entity position is above their crouching collision polygon. In this case, aiming a weapon at the entity position would fire over the target, and this is what happens when NPCs fire at crouching humanoids.

The simplest and most effective solution to this problem would be to alter the humanoid crouching collision polygon so that it encompasses the entity position. This would make sense, because in the crouching graphic, the head of the humanoid encompasses the entity position. However, changing the collision geometry would also affect player mobility, and would make the player unable to traverse certain tunnels. (None of these hypothetical tunnels exist in the base game, but they could exist in mods or in users' universes.) As such, changing collision geometry poses too high a risk for incompatibility.

The alternative chosen in this mod is to create a new action, `rl_bettercrew_entityPosition`, which operates similarly to `entityPosition`. If the target is an NPC or player, the action queries whether the target collides with the aim position. If it does not collide, then the reported entity position is lowered by 0.75 blocks, which is sufficient to put it within the crouching collision polygon of a humanoid target.

Unlike other actions discussed in this section, the `entityPosition` action is not faulty per se. To determine whether you should use it or `rl_bettercrew_entityPosition`, you will need to consider the context of the invocation. If determining a point at which to aim a weapon, you probably want `rl_bettercrew_entityPosition`. For other uses, the base game function is preferable.

## Additional New Behavior Actions

This mod provides a number of additional new behavior actions that can be used by other mods that require it.

### Check for Gravity

The `rl_bettercrew_gravityPositive` action returns true if the gravity at the specified `position` is greater than zero.

### Check for Held Items

The `rl_bettercrew_hasPrimaryItem` and `rl_bettercrew_hasAltItem` actions return true if the NPC is holding anything in their primary and alt hands respectively.

### Counters

The `rl_bettercrew_incrementCounter` action increments the integer counter identified by `name` by 1. If `name` does not exist when the action is invoked, it is created with value 0 and immediately incremented to 1 by the invocation.

The `rl_bettercrew_resetCounter` action resets the counter identified by `name` to 0. If `name` does not exist when the action is invoked, it is created and set to 0.

### Min and Max

The `rl_bettercrew_max` and `rl_bettercrew_min` expose the Lua `math.max` and `math.min` functions to behavior trees.

### Speaking With Less Risk

The base game action `sayToEntity` would crash, killing the NPC, if the specified `dialogType` did not exist for the NPC type. The `rl_bettercrew_sayToEntityIfExists` action reimplements this function, but returns true if the specified `dialogType` does not exist. It is otherwise semantically equivalent to the base game action.
