# Better Crew & NPC Behavior: User Guide

*Better Crew & NPC Behavior* improves NPC behavior in many ways, focusing on better shipboard behavior of the crew, but also fixing a large number of bugs in NPC combat and general NPC behavior. The full list of features and improvements is documented here. A more technical discussion, appropriate for modders, can be found in the [Modding Guide](modding-guide.md).

## Crew Anchor Objects

While onboard their ship, crew will be attracted to certain objects. These objects will pull the crew away from their spawn location, the teleporter. If you have done a good job designing your ship, this should result in your crew spreading throughout the ship and moving around in a way that looks natural.

A full list of which objects attract which crew types can be found by reading the [object patches](https://github.com/rl-starbound/rl_bettercrew/tree/master/rl_bettercrew/objects) and looking for the key `crewAnchorTags`. In general, crew are attracted to objects that are related to their occupations, and this mod patches almost 130 base game objects with crew anchor tags.

### Crew Anchor Objects and BYOS

This mod is compatible with *BYOS* and the *Frackin Universe* BYOS, but crew anchor objects will only affect crew behavior when a recognized SAIL console exists on the ship. If you break your SAIL console, the crew will return to hanging around their spawn point. If you replace the SAIL console, you may need to leave and return to the ship, or restart the game, to force all objects to re-register their crew anchor tags.

### Extensions

This mod patches only base game objects and crew types, and I do not intend to add patches for modded content into it. Mod authors are encouraged to refer to the documentation for [adding compatibility](modding-guide.md#adapting-modded-objects-with-crew-anchor-tags) for custom objects and crew types.

Vix has written a couple of extensions that add support for large numbers of third party [objects](https://steamcommunity.com/sharedfiles/filedetails/?id=3095344193) and [races](https://steamcommunity.com/sharedfiles/filedetails/?id=3092932735).

InkWarrior101 has written an extension for [compatibility](https://steamcommunity.com/sharedfiles/filedetails/?id=3677854700) with the Remnants of the Protectorate mod.

## NPC Combat Improvements

NPC combat in Starbound is simplistic. Each NPC can make behavioral decisions every 1/6th of a second. If an NPC has a ranged weapon, they will attempt to move to a position within range and line of sight of the target, and fire until they have exhausted their energy. In an NPC has a melee weapon, they will attempt to move adjacent to the target, at which point they will raise the melee weapon for a windup interval, swing the weapon, and then wait for a cooldown interval before attempting another strike. If the NPC is more than 10 blocks from the target while using a melee weapon, they may choose to attempt a melee leap instead of a simple swing. If the NPC has both a ranged and melee weapon, they will prefer the ranged weapon, will swap to the melee weapon only when out of energy, and will swap back to the ranged weapon after 8 seconds.

That's the entire battle strategy of NPCs. But, because of the implementation, the specifics are incredibly complicated and difficult to comprehend. Implementing more complex strategies or tactics would likely incur significant performance penalties. It would also require massive changes to the behavior files and Lua scripts, as well as improvements to the core engine. These are not likely to happen any time soon.

However, there are many flaws in the existing combat behaviors, which can be improved relatively safely, with virtually no performance impact. This mod makes the following improvements:

* Crew members' combat power was set to 25% of their calculated combat power (based on the player's currently-equipped armor's combat power). All other combat-capable NPCs' combat power is 50% to to 100% of their world level multiplier. I don't know why Chucklefish nerfed crew members like this, but I bumped it up to 75% for soldiers, outlaws, and penguin mercenaries, and 65% for other crew types. Crew are now useful in combat.
* Penguin mercenaries were equipped with two different pistols, but one of them was never used because there is no code to swap from one ranged weapon to another ranged weapon. Instead, I've set penguin crew members to use a dagger in addition to their pistol. As a bonus, it's a lot of fun to watch a penguin shank something to death.
* NPC melee weapons had far more windup time and cooldown time than player weapons of the same type. As a result, NPCs spend far more time holding up their weapons without striking, or standing around after striking, doing nothing but taking damage. I've adjusted NPC melee windup and cooldown to be roughly equivalent to player weapons. NPCs should deliver approximately the same average damage per second as they did in the base game, but they'll now strike much more frequently.
* Melee leap had a flaw where the 0.75 second windup phase (really, 0.83 second, when accounting for script delta) could get repeated multiple times, so the NPC would stand around holding up their weapon for several seconds. This has been corrected, in addition to some other flaws with the melee leap.
* NPCs didn't always reorient themselves if they crossed positions with their target. This resulted in NPCs swinging their weapons in the wrong direction, hitting nothing. NPCs are now much better at reorienting themselves to face the target before swinging their weapon.
* NPCs aimed bows continuously during windup, but aimed guns only briefly before beginning to shoot, and did not re-aim as the target moved. Now, NPCs continuously re-aim guns as they fire. (Note, this is not predictive aiming; that would require core engine updates or a significant performance penalty. But, it's better than what we had before.)
* NPCs using bows aimed slightly below their targets. This was usually noticeable only for long shots against stationary targets. This has been corrected, and NPCs are now better shots with a bow and arrow.
* NPCs did not recognize crouching behavior, and aimed too high when their target was a humanoid who was crouching. This has been corrected.
* Ranged weapon minimum ranges were ignored, which meant that NPCs with long guns would often fire their weapon when their target's hit box was between the muzzle and themselves, which meant the shot missed its target entirely. Now, weapon minimum ranges are respected during the aiming phase, and NPCs will attempt to move away from a target that is crowding them.
* Path-finding to a position from which to fire a ranged weapon could become stuck in an indefinite `moveToPosition` loop. Now, NPCs can switch back to a melee weapon, or say "cantReachRanged" dialog if this happens.
* NPCs could get crowded by a target within their minimum firing range, resulting in the NPC being unable to fire their ranged weapon. Now, NPCs can switch back to a melee weapon if this happens.
* If a target is out of range of melee and ranged weapons, and the NPC can't path-find to a position in range, they'll just stand there indefinitely until something changes. You notice this most often on worlds with stationary floating monsters such as [pyromantles](https://starbounder.org/Pyromantle). While I can't prevent this particular freezing, I can at least make NPCs say "cantReach" or "cantReachRanged" dialog periodically, so the player gets a hint as to why they're standing still.
* Melee and ranged weapons have different minimum and maximum ranges. When an NPC swapped between melee and ranged weapons, the NPC's state and the combat coordinator's state went out of sync for a few ticks, which often resulted in the NPC swinging their melee weapon far out of range of the target. This has been fixed.
* Bows weren't defined correctly in the combat coordinator, so it was possible for the coordinator to direct an NPC to a position from which they could not fire their bow, resulting in indefinite freezing.
* Many NPC weapons had no minimum and maximum ranges defined in the combat coordinator, which resulted in defaults being used that were often far more restrictive than necessary.
* NPCs that used an expendable weapon (e.g., the pet capture pod) were unable to replace the weapon once it was expended, leaving them with only a melee or ranged weapon. This mod adds a replacement capability and implements it for cultist generals and Glitch evil lords.

## Crew Rallying

When the player brought a crew member off ship and then ordered them to stop following, to make them begin following again, the player had to find and interact with them. This could be annoying if the player traveled far from them.

I have added new functionality to allow the player to rally all non-following crew who are on the same (non-ship) world as the player. When summoned, they will begin following the player, and this will result in them running or teleporting to the player's current position. If no surviving crew are present on the same world as the player, SAIL will give you a warning.

Crew rallying requires an additional mod. If either of the [Stardust Core Lite](https://steamcommunity.com/sharedfiles/filedetails/?id=2512589532) or [Stardust Core](https://steamcommunity.com/sharedfiles/filedetails/?id=764887546) mods is installed, crew can be summoned by opening the `Quickbar` and selecting `Crew Communications`. If [Better Crew: No Quickbar](README_noquickbar.md) is installed, they can be summoned by equipping and using the `Crew Communicator` tool, which can be obtained for free during the ship repair quest. (If lost, or if the mod is installed after completing that quest, it can be purchased from Penguin Pete at the Outpost.)

## Additional Fixes and Improvements

This section contains in-depth discussion of additional fixes and improvements that could not be covered in the README.

### NPC Spinning

Sometimes an NPC would be observed spinning back and forth over a single block. An NPC stuck spinning would continue to spin indefinitely, or until a higher priority behavior was triggered, such as combat or player interaction.

I have fixed all known instances of this issue.

### NPC Freezing

If an NPC wanted to move to a specific position in the world, but the game was not able to path-find a route to that position, the NPC would freeze in place, and would wait indefinitely until a path became available, or a higher priority behavior was triggered, such as combat or player interaction.

This behavior can be observed on ships, by placing a bed or chair behind a closed locked door. NPCs on the ship will eventually want to lie in the bed or sit on the chair, and will be unable to path-find a route to it, because the core engine will not route NPCs through a closed locked door. In the absence of the player interacting with them, the NPCs will remain frozen indefinitely as long as the shipworld remains loaded. This issue can also be observed in dungeons that feature elevators (which NPCs cannot use), or that feature stairwells between floors that are long distances away, such as Glitch Castles.

I have altered all of the affected behaviors to use a path-finding timeout, which prevents indefinite freezing.

### What Counts as a Locked Door?

A common cause of NPC movement issues is when an NPC wants to move to an object, for example a bed or chair, that is on the other side of a closed locked door. Path-finding is handled in the core engine, and the core engine will not attempt to route an NPC through a closed locked door.

That seems fine, but **the game considers any door with something wired to its input node to be a locked door**, even if that something is a proximity sensor. (Note, a door with a built-in proximity sensor, such as an [airlock](https://starbounder.org/Large_Airlock_Door), does not exhibit this problem, because the game does not consider it to be locked as long as nothing is attached to its input node.) As a result, the core engine will not attempt to route any NPC through a closed door with an attached proximity sensor. If the player or an NPC moves near enough to the proximity sensor, the door will open, and the core engine will begin routing NPCs through it. However, once the door closes, the core engine will cease routing NPCs through it, trapping them on whichever side of the door they end up on.

**You should be mindful of this issue for all doors with wired input nodes.** I have written a new mod, [Automatic Ship Doors](https://github.com/rl-starbound/rl_automaticshipdoors), that makes the base game's ship doors open automatically. You may wish to use it, rather than wiring proximity sensors to ship doors.

### NPCs Closing Doors in Your Face

When an NPC moved through a doorway, they checked whether other NPCs were also in the doorway before closing the door, but they didn't check for players. As such, most players have grown accustomed to NPCs slamming doors in their faces.

Now, NPCs are slightly less rude, and check for players as well as NPCs in a doorway before closing the door.

### NPCs Leaving Hatches Open

NPCs usually closed doors behind themselves, but if they moved through hatches, they rarely closed them.

Now, NPCs will usually close hatches after passing through them, following the same logic as closing doors. This logic isn't perfect, so they may occasionally leave a hatch open, as they sometimes leave doors open.

### NPC Personality Effects

NPC personality was not used in the base game behavior logic, so some NPC personality types did not behave as documented. Specifically, "nocturnal" NPCs got stuck in a sleep-wake loop during the daytime, and "fast" NPCs were supposed to run everywhere, but moved at normal speed.

I have improved the behavior logic to use NPC personality traits in NPC reactions.

### NPC Personality Effects (Nocturnal)

An additional bug related to NPC sleep and wake times was that nocturnal NPCs went to sleep between times 0.0 to 0.4 and woke up from sleep between times 0.5 and 0.0. Note that these actions overlapped when the time of day was exactly 0.0. On player space stations, NPC space stations, terrestrial worlds, and the player ship if orbiting a terrestrial world, this did not matter, because time 0.0 occurred only for an instant. However, Starbound does not manage time on many non-terrestrial worlds, nor on the player ship if not orbiting a terrestrial world. In these environments, the time of day is set permanently to 0.0 and nocturnal NPCs could become stuck in a sleep-wake loop indefinitely, or until a higher priority behavior was triggered, such as combat or player interaction.

I have fixed this by altering nocturnal NPCs' sleep time to be between 0.1 and 0.4. However, due to how NPC personality data is stored, this will only affect new nocturnal NPCs. Existing nocturnal NPCs will continue to exhibit the erroneous behavior on non-terrestrial worlds that have beds. **Nocturnal crew members must be dismissed and respawned to correct the behavior.**

### NPC Item Swapping

The base game contains faulty NPC item-swapping functions that could result in NPCs losing item sets and becoming disarmed. This bug could be observed as a solider or outlaw crew member swapping to their melee or ranged weapon, and then never swapping back. It could also be observed in certain unarmed hostile NPCs, such as Avians in hostile Avian temples and tombs. These NPCs were originally armed, but if the player approached them while they were sleeping, the faulty swap function sometimes lost their weapons, resulting in an unarmed hostile NPC.

I have fixed these faults, so NPCs should not lose weapons now.

### Crew Elemental Resistances

Crew members obtained their statistics for maximum health, defense, and combat power from the player's currently equipped armor set. However, if the player had an elemental resistance and status immunity due to an EPP augment, this did not extend to crew members. Bringing crew members to hazardous locations, such as toxic ocean worlds, was difficult because they would take poison damage from the environment.

This mod extends elemental resistance and status immunity of the four base game elemental EPP augments to crew members, when such augments are equipped by the player. (Note: There is nothing in the base game that gives the player resistance to lava, so nothing will give NPCs resistance to it either. Crew are still idiots around lava.)

It also extends the Peacekeeper augments' defense bonus to crew members, when the player has equipped one of those augments.

### Crew Sitting and Sleeping

NPCs would only sleep in beds within 50 blocks of their spawn location, and would only sit in chairs within 80 blocks of their spawn location.

For crew members onboard their ship, the search radius for beds and chairs is now 300 blocks.

### Crew Hold Positions

When the player brought a crew member off ship and then ordered them to stop following, what often happened was that the crew member immediately wandered away. The reason this happened is that, in the absence of anything better to do, an NPC would return to their spawn position. For crew members off the ship, the spawn position was either the beam-in site or the position of the player when the game loaded. If the game was able to path-find to the spawn position, the crew member would abandon their assigned position to return to their spawn position.

In this mod, when the player instructs the crew member to stop following, I replace the crew member's spawn position with the player's current position, so the crew member will hold the position, while still being able to interact with nearby NPCs and objects.

### Medic Improvements

The medic would apply healing effects to the player immediately upon sighting an enemy. This often occurred before the player took any damage, wasting the effect and incurring a 60 second cooldown. Furthermore, medics only healed a paltry 1/12th of the player's maximum health.

Now, the medic waits until the player has taken at least 20% damage before applying healing effects, and heals 1/6th of the player's maximum health.

### Guards Respond to Friendly Fire

Friendly NPCs are generally immune to player weapons. However, some weapons, such as molotovs and bombs, do indiscriminate damage, which can harm friendly NPCs. If the player hit a villager with an indiscriminate weapon, the villager would take damage, turn hostile, and scream for help, turning other nearby villagers and village guards hostile. However, if the player hit a village guard with an indiscriminate weapon, the guard would take damage, but would not otherwise react. A player could murder an entire room full of village guards, and none of them would do anything to oppose it, as long as they didn't observe the player hurting any non-combatant villagers.

Village guards will now become hostile if a player attacks them with indiscriminate weapons. However, certain types of guards, such as crew members and guard tenants, will remain absolutely loyal to the player and will never turn hostile.

Players should take great care in not using indiscriminate weapons near friendly NPCs.

### Admins Cannot Steal

Starbound's stealing mechanic penalizes players for breaking blocks or objects in villages using the matter manipulator or other tools such as pickaxes. If any villager catches the player doing so three or more times, they will become hostile and either attack the player on sight, or alert other villagers, who will likewise turn hostile. While this mechanic offers a sense of realism, by preventing the player from bulldozing existing villages and ignoring the inhabitants, it can also be annoying for players who are merely trying to maintain a village, for example, by cleaning loose silt after a sand storm.

With this mod, admins will not be accused of stealing. I feel that this strikes a reasonable balance between the original intent of the stealing mechanic and the needs of admins to maintain and improve villages without turning their inhabitants hostile.

### Miscellaneous Improvements

* Prevented NPCS who are following the player from teleporting to the player if the player is in zero-gravity.
* Fixed the NPC teleportation "beamin" animation so that it waits until the game actually moves the NPC.
* Fixed a number of visual bugs in how NPCs align themselves with objects or other NPCs to interact with them.
* Fixed a bug that allowed NPCs to jump through a solid floor or ceiling to lounge in a bed or chair.
* Reduced the duration of the NPC `follow` reaction from 60 to 15 seconds, to reduce the chance of groups of NPCs following one another ad nauseam.
* Changed piano music to loop as long as an NPC continues playing the piano.
* Increased the duration that two NPCs have to randomly independently decide to play air hockey to 30 seconds.

## Compatibility

Compatible:

* *BYOS*
* *Crew Customization+*
* *NpcSpawner+*
* *RPG Growth*

Compatible (some *Better Crew* functionality is overridden):

* *Corbent's Interactive Crew*
* *Earth's Finest*
* *Frackin Universe*

Incompatible:

* *NPCs Aren't Stupid*
* *Smart Crew*
* *Supper's Combat Overhaul*

This mod can be considered a replacement for *NPCs Aren't Stupid* and *Smart Crew*. While it is not nearly as ambitious as *Supper's Combat Overhaul*, it does provide improved NPC combat when compared to the base game.

### Compatibility Notes

This mod should be generally compatible. However, it patches behavior files and replaces faulty Lua functions, and there is no 100% safe way to do that. If it is combined with other mods that alter the same behavior files or Lua functions, conflicts may happen. If conflicts happen, one possible reaction is that all NPCs will die, and if the affected NPCs are not crew or tenants, they will be gone forever.

This mod patches significant structural changes into the following behavior files:

* `/behaviors/npc/combat.behavior`
* `/behaviors/npc/combat/melee.behavior`
* `/behaviors/npc/combat/meleeapproach.behavior`
* `/behaviors/npc/combat/meleeleap.behavior`
* `/behaviors/npc/combat/ranged.behavior`
* `/behaviors/npc/crew/combat.behavior`
* `/behaviors/npc/crew/notifications.behavior`
* `/behaviors/npc/flee.behavior`
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

The coding of these patches is extremely defensive, and should correctly apply or refuse to apply if conflicting patches were applied before this mod was loaded. However, many other mods are not so defensively coded, so if other mods attempt to patch these files after this mod has been loaded, broken behavior is likely.

(Additional behavior files have been patched, but those patches have been judged unlikely to cause conflicts. See the [behavior patches](https://github.com/rl-starbound/rl_bettercrew/tree/master/rl_bettercrew/behaviors) for full details.)

This mod safely replaces the following faulty behavior actions with renamed fixed versions:

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

Other mods' behaviors may still invoke the base game versions of these actions, which might result in the faulty behavior re-occurring, but should not result in serious issues.

This mod replaces the following faulty Lua functions with improved versions, and all invocations of these functions automatically use the improved versions:

* `/npcs/bmain.lua`: `setNpcItemSlot`
* `/stagehands/coordinator.lua`: `onGetResource`

In each case, the faulty function has been replaced using a secondary script appended to the respective entity's scripts list. Other mods should be safe to add or replace other functions in those scripts using the same mechanism, as long as they don't replace those exact same functions. If another mod replaces either of those functions, then faulty behavior might occur.

## Unfixable Issues

Some NPCs behavior issues cannot be fixed easily, or at all. These issues are not caused by this mod, but may be more noticeable because this mod fixes many more obvious bad behaviors.

### NPCs Cannot Route Across a Closed Hatch

NPCs are able to perform unplanned movements (e.g., flee, patrol, wander) across the top of a closed hatch without issue. They are able to hop over an open hatch without issue. As of v1.4.0, they are able to move through a closed hatch by opening it as they move toward it. But, if a behavior plans a route for an NPC across the top of a closed hatch, the NPC will become stuck as soon as they step onto the hatch. Crew members will declare that the player is "too far", even if they're only a few blocks away, and will teleport to the player eventually. Non-crew member NPCs will become stuck until a higher priority behavior is triggered.

Fortunately thanks to the movement timeouts introduced by this mod, as well as the many higher priority behaviors, this generally isn't too much of an issue, but you should be aware of it when placing hatches in your designs. Unfortunately, this seems to be a problem with the core engine's path-finding, so there appears to be nothing that a mod such as *Better Crew* can do to fix it.
