# Starbound mod: Better Crew and NPC Behavior

You recruit twelve NPCs to become your ship's crew, and then what happens onboard? They all mob the teleporter and ignore the rest of your ship.

NPC behaviors in Starbound are quite simplistic, and this becomes most obvious in crew behavior onboard the player's ship. This mod alters and improves NPC behaviors in a number of ways, focusing on improved shipboard behavior of the crew, but also fixing a number of general bugs in NPC behavior. **Please read and understand the compatibility notes before installing!**

## Compatibility Notes

I have used Starbound modding best practices, so this mod should be widely compatible. However, this mod modifies behavior files and replaces buggy Lua functions, and there is no truly safe way to modify those. **If this mod is combined with any other mod that modifies the same behavior files or Lua functions, the result is likely to be broken NPC behaviors.** Please see the [Compatibility Notes (Technical)](#compatibility-notes-technical) section for technical details about behavior files and Lua scripts modified.

As a general rule of thumb, you should assume that this mod is not compatible with any other mod that significantly alters NPC behavior. This mod is known to be incompatible with *Smart Crew* and *Supper's Combat Overhaul*.

This mod is almost certainly not compatible with *BYOS*, or any other mod that adds similar functionality, such as *Frackin Universe*. Those large mod authors are free to include a modified version of this mod in theirs, provided they obey the [license](#license), but I will not be adding code to this mod for compatibility with them.

Note: This mod does not modify persistent state, and is therefore safe to add or remove at will. However, please note that if this mod conflicts with other mods, one likely reaction is that NPCs will die instantly upon loading. If the affected NPC is not a crew member or tenant, they will be gone for good. **It is therefore advised to backup your universe before testing this mod.**

## Mod Functionality

### Shipboard Duty Stations and Patrols

While onboard the player's ship, each of the twelve crew types will now be attracted to certain objects, if present. These objects will pull the crew away from their spawn location (i.e., the teleporter). If you have done a good job designing your ship's spaces, this should result in the crew spreading out throughout the ship and moving around in a way that feels natural.

A full list of which objects attract which crew types can be found by reading this mod's source code, particularly by looking in all of the `*.object.patch` files for the key `crewAnchorTags`. In general, crew are attracted to objects that are related to their occupations, and this mod patches over 100 base game objects with crew anchor tags. (Note to other mod authors: You may add the field `crewAnchorTags` to your own objects, if you wish to use this mod in combination with your own. The value is a JSON list of strings, with each string being one of the crewmember NPC types that should be attracted to the object.)

Implementation Note: The idea behind this mod is based on the mod *Smart Crew* by metamorphexx. In that mod, each crew type has a hard-coded list of objects that attracts that crew type, and on each behavior tick, each crew member searches the player's ship for each object on their type's list and moves to one such object, if found. This struck me as inefficient, as searches happen on each behavior tick, for each crew member, for each object in the crew type's list. In my implementation, the crew types that can be attracted to an object are a property of each object. As each object is placed into the ship world, it registers itself and its location with the ship. Then, on each behavior tick for each crew member, the ship's registry is consulted for a random object for that crew type, and the crew member moves to the location, without any computationally expensive object searches.

### Crew Sitting and Sleeping

One of my Condor-class ship designs featured the crew sleeping quarters and mess hall at one end of the ship, far away from the teleporter. I noticed that my crew never slept in the beds, nor did they sit at the tables in the mess hall. After examining the behavior code, I realized that no NPC will attempt to sleep in a bed further than 50 blocks or sit in a chair further than 80 blocks from their spawn location, which on the ship is the teleporter.

I increased the search radius for beds and chairs to 250 blocks for crew members onboard player ships, which should sufficiently cover all base game ship classes.

### NPC Freezing

On my larger ships, I usually designate one room the captain's quarters, and lock its door so that crew cannot wander into it. After implementing shipboard duty stations and fixing the sleeping bug, I noticed that most of my crew members were standing still for very long periods of time, often ten minutes or more. They would begin moving if I interacted with them, but given enough time, would eventually freeze again. After debugging this, I realized that Starbound's simplistic behavior logic hides a significant bug.

The `moveToPosition` function is used extensively in Starbound behaviors, and I used it in my own shipboard duty stations behaviors. Basically, an NPC behavior fires `moveToPosition` with some coordinates, and the NPC plans a route to those coordinates (via a call to Starbound's C++ API) and moves there. If the game cannot plan a route from the NPC's original location to its specified destination (e.g., if the location is behind a locked door), the NPC just stands there and waits, presumably in case a route opens up in the future. There is no built-in timeout functionality in `moveToPosition`. An NPC stuck waiting will continue to wait indefinitely, or until a higher priority behavior is triggered (e.g., combat, or the player interacting with them). A few of the base game uses of `moveToPosition` were wrapped inside of a timeout behavior, but the vast majority were not.

I modified all of my own uses and most of the base game uses of `moveToPosition` to use the timeout wrapper, and the freezing behavior appears to be fixed.

### What Counts as a Locked Door?

On my ships, I generally prefer to use the racial ship doors. However, manually opening and closing doors is annoying, so I wired proximity sensors on either side of each door. While investigating the NPC freezing issue described above, I realized that the game has a simplistic definition of a locked door, which was affecting my crews' movement through the ship.

The game's path-finding logic will not attempt to route an NPC through a closed and locked door. That seems fine. But, the game considers any door with something wired to its input node as a locked door, even if that something is a proximity sensor. As a result, the game would not attempt to route any NPC through my proximity-sensitive ship doors as long as they were closed. However, if I moved my character through a door, or if an NPC wandered near enough to a door, the door would open, and suddenly the game would route NPCs through it. However, once the door closed, the game would immediately cease routing NPCs through it, trapping them on whichever side of the door they ended up on.

While somewhat amusing, this ultimately interfered with my vision of how shipboard NPCs should work, so I modified all of the racial ship doors to open automatically, and removed the proximity sensor wiring. **You should be mindful of this issue for all non-automatically opening doors.**

Note that the game's path-finding logic is in its C++ code. Modders cannot fix this directly, so we have to develop hacks to work around its limitations.

### NPC Personality Effects

While fixing the bed search logic described above, I noticed that some NPCs would get into a bed, immediately get out of bed, and repeat this behavior in a loop for many minutes. I also noticed that all such NPCs had the "nocturnal" personality type. After studying the behavior code, I realized that NPCs' personality trait information was not used in the behavior logic loop, with the result that certain NPC personality types were not behaving as documented. In this specific case, nocturnal NPCs' sleep was correctly triggered at daytime (as opposed to being triggered at nighttime for all other NPC personality types), but the trait that sets their wake up trigger to be nighttime was not used in the loop, and thus they were waking up at daytime like all other NPC personality types, triggering a sleep-wake loop during the daytime.

Another example of incorrectly behaving NPC personality types was the "fast" type. Fast NPCs are supposed to run everywhere, but were moving at the normal rate of speed due to this bug.

I fixed the main behavior loop to use personality trait information correctly.

An additional bug related to NPC sleep and wake times is that nocturnal NPCs go to sleep between times 0.0 to 0.4 and wake up from sleep between times 0.5 and 0.0. Note that these actions overlap when the time of day is exactly 0.0. On player space stations, NPC space stations, terrestrial worlds, and the player ship if orbiting a terrestrial world, this does not matter, because time 0.0 occurs only for an instant. However, Starbound does not manage time on many non-terrestrial worlds, nor on the player ship if not orbiting a terrestrial world. In these environments, the time of day is set permanently to 0.0 and nocturnal NPCs can become stuck in a permanent sleep-wake loop.

I have fixed this by altering nocturnal NPCs' sleep time to be between 0.1 and 0.4. However, due to how NPC personality data is stored, this will only affect new nocturnal NPCs. Existing nocturnal NPCs will continue to exhibit the erroneous behavior on non-terrestrial worlds that have beds.

### Crew Hold Positions

In the base game, when the player brings a crew member off ship, and then orders that crew member to stop following, the crew member should hold their position. Instead, what often happens is the crew member immediately walks away from the position. This prevents them from defending the specified position from enemies, and also makes it difficult for the player to locate them later. The reason this happens is that, in the absence of anything better to do, an NPC will execute the `Return Home` behavior. This causes a crew member not following the player to attempt to go back to their spawn position, which when off the ship, is either the beam-in site, or the position of the player when the game loaded. If the core engine is able to plan a route to the spawn position, the crew member will abandon their assigned position.

I have altered crew member behavior such that, if the player and crew member are off the ship, and the player instructs the crew member to stop following, the crew member's spawn position will be replaced with the player's current position. As such, the crew member will hold their assigned position, but will continue to interact with nearby NPCs and objects.

Note that if the player and crew member are off the ship, and the crew member is not following the player, and the player beams to another world or quits the game and reloads, then the crew member's spawn position will be reset and they will resume following the player. This is unchanged from the base game behavior.

### Crew Rallying

In the base game, when the player brings a crew member off ship, and then orders that crew member to stop following, their positions in the world will begin to diverge. To make the crew member begin following again, the player must find and interact with them. This can be annoying if the player has traveled far from where the crew member was ordered to hold position. Alternatively, the player can beam to their ship to reunite with wayward crew members, or quit the game and reload it. However, both of those options are disruptive to whatever the player was doing on the planet.

I have added new functionality to allow the player to summon all non-following crew members that are currently alive and on the same world as the player. This feature requires [Stardust Core Lite](https://steamcommunity.com/sharedfiles/filedetails/?id=2512589532) version `Alpha 0.37` or newer. This mod is an optional dependency, but if it is not installed, this feature will not be available for use.

Non-following crew members can be summoned remotely while off ship by opening the `Quickbar` and selecting `Crew Communications`. All non-following crew members on the world will begin following the player, and this will usually result in them running or teleporting to the player's current position. If the player has not brought any crew members along, or if all such crew members have died, SAIL will issue a warning.

### Medic Improvements

In the base game, the medic will apply healing effects to a player immediately upon initiation of combat. This often occurs before the player takes any damage, thus wasting the effect and requiring a 60 second cooldown before the next healing. Furthermore, medics only heal a paltry 1/12th of the player's max health over a period of five seconds, making them significantly less effective than a salve.

I have modified the `crewmember-combat` behavior module so that the medic waits until the player has taken at least 20% damage before applying healing effects. I have also increased combat and field regeneration so that the medic heals 1/6th of the player's max health over a period of five seconds.

### Crew Status Immunities

Armor, attack power, and max health are automatically set and updated for crew members based on the player's currently equipped armor stats. However, elemental resistance and status immunity, based on the player's EPP augment, are not extended to crew members. This makes it difficult, for example, to bring crew members to a toxic ocean planet, because they will die quickly due to contact with acid rain or liquid poison.

I have extended the elemental resistance and status immunity of the four base game elemental EPP augments to crew members, when such augments are equipped by the player.

### Crew Sheathed Weapons

Like many NPCs, crew members have a default primary-hand and alt-hand load-out and a sheathed primary-hand and alt-hand load-out, which can be swapped by the `swapItemSlots` behavior action. Due to idiosyncrasies of the core function `npc.setItemSlot` and the Lua function `setNpcItemSlot`, in the context of crew members, when the swap first occurs, the newly sheathed load-out may be overwritten by the original sheathed load-out. In effect, the crew member's default load-out will be lost until they are reloaded, for example, by teleporting to a new world or restarting the game.

I have fixed `setNpcItemSlot` so that this can no longer happen.

### Beds No Longer Disarm NPCs

If an armed NPC (friendly or hostile) is sleeping in a bed and is woken by combat, a bug in the core function `npc.setItemSlot` may cause the `swapItemSlots` behavior action to effectively disarm the NPC. A common symptom of this bug is unarmed Avian temple guards near altars, but it can affect any armed NPC type.

I have improved the action code to detect the erroneous condition and abort the swap if it occurs. I'm not certain that this fixes all possible occurrences, but I am now unable to reproduce the bug.

### Admins Cannot Steal

Starbound's stealing mechanic penalizes players for breaking blocks or objects in villages using the matter manipulator or other tools, such as pickaxes. If any villager catches the player doing so three or more times, they will become hostile and either attack the player on sight, or alert other villagers, who will likewise turn hostile. While this mechanic offers a sense of realism, by preventing the player from bulldozing existing villages and ignoring the inhabitants, it can also be annoying for players who are merely trying to maintain a village. The canonical example of this is a player removing loose silt blocks from a sandstorm that have accumulated in a village, only to be accused of thievery.

I have modified the stealing mechanic to ignore players who currently have admin privileges. I feel that this strikes a balance between the original intent of the stealing mechanic and the needs of admins to maintain and improve villages without turning their inhabitants hostile.

### Miscellaneous Bug Fixes and Tweaks

* I fixed a number of visual bugs in how NPCs align themselves with objects or other NPCs to interact with them.
* When an NPC teleports from one location to another in a world (e.g., a tenant beaming to their colony deed) the `beamin` animation occurs immediately after the `beamout` animation, without waiting for the game to actually move the NPC, producing a jarring visual discontinuity. I fixed this in all of the behaviors that I found to exhibit it.
* The air hockey table rarely gets used because two NPCs have to randomly, independently decide to use it within a 10 second window of one another, in order for it to be used. I increased this window to 30 seconds.
* NPCs may play the piano for up to 30 seconds, but sound only plays for about 5.5 seconds. I tweaked this so that the sound loops for as long as the NPC plays the piano.
* The NPC `reaction-follow` behavior's duration has been reduced from 60 to 15 seconds, to avoid groups of NPCs following each other ad nauseam.

## Uninstallation

This mod make no modifications to any game state. You should be able to add or remove it at any time.

## Compatibility Notes (Technical)

This mod makes minor changes to a large number of behavior files, but those should be relatively safe with respect to mod compatibility. However, this mod makes significant structural changes to the following behavior files:

* `/behaviors/npc/crew/combat.behavior`
* `/behaviors/npc/crew/notifications.behavior`
* `/behaviors/npc/inspect.behavior`
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

If this mod is combined with any other mod that modifies any of those behavior files, broken NPC behaviors and/or instantly-dying NPCs are likely.

This mod replaces the following Lua functions with improved versions:

* `/npcs/bmain.lua`: `setNpcItemSlot`
* `/scripts/actions/npc.lua`: `swapItemSlots`
* `/scripts/actions/query.lua`: `findLoungable`
* `/scripts/actions/reaction.lua`: `playBehaviorReaction`

If it is combined with any other mod that modifies any of these functions, conflicts will happen.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's `_metadata` file;
* A link is provided to https://github.com/rl-starbound/rl_bettercrew in the accompanying files or documentation of any derived work;
* The name "rl_bettercrew" is not used as the name of any derived work without explicit consent of the author(s); however, the name may be used in verbatim distribution of this mod. For the purposes of this clause, minimal changes to metadata files to allow distribution on Steam shall be considered a verbatim distribution so long as authorship attribution remains.
