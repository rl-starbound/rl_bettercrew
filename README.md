# Starbound mod: Better Crew and NPC Behavior

You recruit twelve NPCs to become your ship's crew, and then what happens onboard? They all mob the teleporter and ignore the rest of your ship.

NPC behaviors in Starbound are simplistic, and this becomes obvious in crew behavior onboard the player's ship. This mod alters and improves NPC behaviors in a number of ways, focusing on improved shipboard behavior of the crew, but also fixing a number of general bugs in NPC behavior. **Please read and understand the compatibility notes before installing!**

## Compatibility Notes

I have used Starbound modding best practices, so this mod should be widely compatible. However, this mod patches behavior files and replaces bugged Lua functions, and there is no truly safe way to modify those. **If this mod is combined with any other mod that modifies the same behavior files or Lua functions, the result is likely to be broken NPC behaviors.** Please see the [Compatibility Notes](technical.md#compatibility-notes) technical documentation for additional details about the behavior files and Lua scripts modified.

As a rule of thumb, you should assume that this mod is not compatible with any other mod that significantly alters NPC behavior. This mod is known to be incompatible with *Corbent's Interactive Crew*, *Smart Crew*, and *Supper's Combat Overhaul*. It is probably not compatible with *BYOS*, or any other mod that adds similar functionality, such as *Frackin Universe*.

This mod does not change persistent state, and is therefore safe to add or remove at will. However, if this mod conflicts with other mods, one likely reaction is that NPCs will die instantly upon loading. If the affected NPC is not a crew member or tenant, they will be gone for good. **It is therefore advised to backup your universe before testing this mod.**

## Mod Functionality

### Shipboard Duty Stations and Patrols

While onboard the player's ship, each of the twelve base game crew types will now be attracted to certain objects, if present. These objects will pull the crew away from their spawn location (i.e., the teleporter). If you have done a good job designing your ship's spaces, this should result in the crew spreading throughout the ship and moving around in a way that looks natural.

A full list of which objects attract which crew types can be found by reading this mod's source code, particularly by looking in all of the `*.object.patch` files for the key `crewAnchorTags`. In general, crew are attracted to objects that are related to their occupations, and this mod patches almost 130 base game objects with crew anchor tags.

This mod adds crew anchor tags only to base game objects. If you furnish your ship with objects added by mods, your crew won't be attracted to those objects. You'll need to ask mod authors to add crew anchor tags to their mods' objects. Mod authors should refer to the [technical documentation](technical.md#adapting-modded-objects-with-crew-anchor-tags) for instructions and risk mitigation.

### Crew Sitting and Sleeping

In the base game, NPCs will only sleep in the beds within 50 blocks of their spawn location, and will only sit in chairs within 80 blocks of their spawn location.

I increased the search radius for beds and chairs to 250 blocks for crew members onboard player ships, which should sufficiently cover all base game ship classes.

### NPC Freezing

While developing this mod, I noticed that most of my crew members were standing still for long periods of time. They would begin moving if I interacted with them, but given enough time, they would eventually freeze again. I also noticed this issue wasn't limited to crew; in some villages, especially Glitch Castles, NPCs would often appear to freeze until I interacted with them. After debugging, I realized that if an NPC wants to move to a specific position in the world, but the game is not able to path-find a route to that position, the NPC will freeze until a route becomes available or a higher priority event occurs, for example, combat or player interaction.

I have altered all of the affected base game behaviors to use a path-finding timeout, and the freezing behavior appears to be fixed, without any known adverse effects.

### What Counts as a Locked Door?

The game's path-finding logic will not attempt to route an NPC through a closed locked door. That seems fine, but the game considers any door with something wired to its input node to be a locked door, even if that something is a proximity sensor. As a result, the game will not attempt to route NPCs through a proximity-sensitive door as long as it is closed. If the player or an NPC moves near enough to such a door, the door will open, and the game will begin routing NPCs through it. However, once the door closes, the game will immediately cease routing NPCs through it, trapping them on whichever side of the door they end up on.

I modified all of the racial ship doors to open automatically, and removed the proximity sensor wiring from my ship. **You should be mindful of this issue for all doors with wired input nodes.**

### NPC Personality Effects

In the base game, NPCs' personality trait information was not used in the behavior logic, with the result that certain NPC personality types were not behaving as documented. Specifically, nocturnal NPCs' could not sleep and often got stuck in a sleep-wake loop during the daytime. Another example of incorrectly behaving NPC personality types was the "fast" type. Fast NPCs are supposed to run everywhere, but were moving at the normal rate of speed due to this bug.

I fixed the behavior logic to use personality trait information. These fixes should be automatic in most cases, but nocturnal crew members will have to be dismissed and re-spawned to completely fix the issue.

### Crew Hold Positions

In the base game, when the player brings a crew member off ship, and then orders that crew member to stop following, the crew member should hold their position. Instead, what often happens is that the crew member immediately abandons the position, making it difficult for the player to find them later. The reason this happens is that, in the absence of anything better to do, an NPC will return to their spawn position. When off the ship, this is either the beam-in site, or the position of the player when the game loaded. If the game is able to path-find a route to the spawn position, the crew member will abandon their assigned position.

I have altered crew member behavior so that, if the player and crew member are off the ship, and the player instructs the crew member to stop following, the crew member's spawn position will be replaced with the player's current position. The crew member will then hold the position, while still being able to interact with nearby NPCs and objects.

### Crew Rallying

In the base game, when the player brings a crew member off ship, and then orders that crew member to stop following, to make the crew member begin following again, the player must find and interact with them. This can be annoying if the player has traveled far from the crew member.

I have added new functionality to allow the player to summon all non-following crew members that are currently alive and on the same world as the player. This feature requires [Stardust Core Lite](https://steamcommunity.com/sharedfiles/filedetails/?id=2512589532) version `Alpha 0.37` or newer. This mod is an optional dependency, but if it is not installed, this feature will not be available for use.

Non-following crew members can be summoned remotely while off ship by opening the `Quickbar` and selecting `Crew Communications`. All non-following crew members on the world will begin following the player, and this will usually result in them running or teleporting to the player's current position. If the player has not brought any crew members along, or if all such crew members have died, SAIL will issue a warning.

### Medic Improvements

In the base game, the medic will apply healing effects to a player immediately upon start of combat. This often occurs before the player takes any damage, wasting the effect and incurring a 60 second cooldown. Furthermore, medics only heal a paltry 1/12th of the player's max health.

I have modified the medic behavior so that the medic waits until the player has taken at least 20% damage before applying healing effects. I have also increased combat and field regeneration so that the medic heals 1/6th of the player's max health.

### Crew Status Immunities

Max health, defense, and attack power are set and updated automatically for crew members based on the player's currently equipped armor. However, elemental resistance and status immunity, based on the player's EPP augment, are not extended to crew members. This makes it difficult, for example, to bring crew members to a toxic ocean planet, because they will die quickly due to contact with acid rain or liquid poison.

I have extended the elemental resistance and status immunity of the four base game elemental EPP augments to crew members, when such augments are equipped by the player.

### Crew Sheathed Weapons Fix

Many NPCs, including crew members, have a default load-out and a sheathed load-out, and these can be swapped during combat. In the context of a crew member, when the swap first occurs, the crew member's default load-out may be lost until the game is reloaded.

I have fixed the code so this can no longer happen.

### Beds No Longer Disarm NPCs

If an armed NPC (friendly or hostile) is sleeping in a bed and is woken by combat, a bug in the base game may cause the weapon swap behavior to disarm the NPC. A common symptom of this bug is unarmed Avian temple guards near altars, but it can affect any armed NPC that is sleeping.

I have improved the code to detect the erroneous condition and abort the swap if it occurs. I'm not certain that this fixes all possible occurrences, but I am now unable to reproduce the bug.

### Admins Cannot Steal

Starbound's stealing mechanic penalizes players for breaking blocks or objects in villages using the matter manipulator or other tools, such as pickaxes. If any villager catches the player doing so three or more times, they will become hostile and either attack the player on sight, or alert other villagers, who will likewise turn hostile. While this mechanic offers a sense of realism, by preventing the player from bulldozing existing villages and ignoring the inhabitants, it can also be annoying for players who are merely trying to maintain a village.

I have modified the stealing mechanic to ignore players who currently have admin privileges. I feel that this strikes a reasonable balance between the original intent of the stealing mechanic and the needs of admins to maintain and improve villages without turning their inhabitants hostile.

### Miscellaneous Bug Fixes and Tweaks

* I fixed a number of visual bugs in how NPCs align themselves with objects or other NPCs to interact with them. This also fixes an issue in which NPCs can jump through a solid floor or ceiling to lounge in a chair or bed.
* When an NPC teleports from one location to another in a world (e.g., a tenant beaming to their colony deed) the `beamin` animation occurs immediately after the `beamout` animation, without waiting for the game to actually move the NPC, producing a jarring visual discontinuity. I fixed this in all of the behaviors that I found exhibited it.
* The air hockey table rarely gets used because two NPCs have to randomly, independently decide to use it within a 10 second window of one another, in order for it to be used. I increased this window to 30 seconds.
* NPCs may play the piano for up to 30 seconds, but sound only plays for about 5.5 seconds. I tweaked this so that the sound loops for as long as the NPC plays the piano.
* NPC follow behavior duration has been reduced from 60 to 15 seconds, to avoid groups of NPCs following each other ad nauseam.
* NPCs can no longer teleport to the player if the player's position is in 0-gravity.

## Uninstallation

This mod makes no changes to persistent state. You should be able to remove it safely at any time.

## Collaboration

If you have any ideas for additional improvements to base game NPC behaviors, please contact me via [Github](https://github.com/rl-starbound) or [Chucklefish Forums](https://community.playstarbound.com/members/rl-starbound.885402/) and let me know. I don't intend to build support for other mods directly into this mod, but I'll be glad to give help or advice on writing compatibility mods.

You can find additional technical details about this mod [here](technical.md).

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's `_metadata` file;
* A link is provided to https://github.com/rl-starbound/rl_bettercrew in the accompanying files or documentation of any derived work;
* The name "rl_bettercrew" is not used as the name of any derived work without explicit consent of the author(s); however, the name may be used in verbatim distribution of this mod. For the purposes of this clause, minimal changes to metadata files to allow distribution on Steam shall be considered a verbatim distribution so long as authorship attribution remains.
