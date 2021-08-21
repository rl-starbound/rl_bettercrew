# Starbound mod: Better Crew and NPC Behavior

You recruit twelve NPCs to become your ship's crew, and then what happens onboard? They all mob the teleporter and ignore the rest of your ship.

NPC behaviors in Starbound are quite simplistic, and this becomes most obvious in crew behavior onboard the player's ship. This mod alters and improves NPC behaviors in a number of ways, focusing on improved shipboard behavior of the crew, but also fixing a number of general bugs in NPC behavior.

## Mod Functionality

### Shipboard Duty Stations and Patrols

While onboard the player's ship, each of the twelve crew types will now be attracted to certain objects, if present. These objects will pull the crew away from their spawn location (i.e., the teleporter). If you have done a good job designing your ship's spaces, this should result in the crew spreading out throughout the ship and moving around in a way that feels natural.

A full list of which objects attract which crew types can be found by reading this mod's source code, particularly by looking in all of the `*.object.patch` files for the key `crewAnchorTags`. In general, crew are attracted to objects that are related to their occupations, and this mod patches over 100 vanilla objects with crew anchor tags.

Implementation Note: The idea behind this mod is based on the mod "Smart Crew" by metamorphexx. In that mod, each crew type has a hard-coded list of objects that attracts that crew type, and on each behavior tick, each crew member searches the player's ship for each object on their type's list and moves to one such object, if found. This struck me as inefficient, as searches happen on each behavior tick, for each crew member, for each object in the crew type's list. In my implementation, the crew types that can be attracted to an object are a property of each object. As each object is placed into the ship world, it registers itself and its location with the ship. Then, on each behavior tick for each crew member, the ship's registry is consulted for a random object for that crew type, and the crew member moves to the location, without any computationally expensive object searches.

### Crew Sitting and Sleeping

One of my Condor-class ship designs featured the crew sleeping quarters and mess hall at one end of the ship, far away from the teleporter. I noticed that my crew never slept in the beds, nor did they sit at the tables in the mess hall. After examining the behavior code, I realized that no NPC will attempt to sleep in a bed further than 50 blocks or sit in a chair further than 80 blocks from their spawn location, which on the ship is the teleporter.

I increased the search radius for beds and chairs to 200 blocks for crew members onboard player ships, which should sufficiently cover all vanilla ship classes.

### NPC Freezing

On my larger ships, I usually designate one room the captain's quarters, and lock its door so that crew cannot wander into it. After implementing shipboard duty stations and fixing the sleeping bug, I noticed that many of my crew members were standing still for very long periods of time, often ten minutes or more. They would begin moving if I interacted with them, but given enough time, would eventually freeze again. After debugging this, I realized that Starbound's simplistic behavior logic hides a significant bug.

The `moveToPosition` function is used extensively in Starbound behaviors, and I used it in my own shipboard duty stations behaviors. Basically, an NPC behavior fires `moveToPosition` with some coordinates, and the NPC plans a route to those coordinates (via a call to Starbound's C++ API) and moves there. If the game cannot plan a route from the NPC's original location to its specified destination (e.g., if the location is behind a locked door), the NPC just stands there and waits, presumably in case a route opens up in the future. There is no built-in timeout functionality in `moveToPosition`. An NPC stuck waiting will continue to wait indefinitely, or until a higher priority behavior is triggered (e.g., combat, or the player interacting with them). A few of the vanilla uses of `moveToPosition` were wrapped inside of a timeout behavior, but the vast majority were not.

I modified all of my own uses and most of the vanilla uses of `moveToPosition` to use the timeout wrapper, and the freezing behavior appears to be fixed.

### What Counts as a Locked Door?

On my ships, I generally prefer to use the racial ship doors. However, manually opening and closing doors is annoying, so I wired motion sensors on either side of each door. While investigating the NPC freezing issue described above, I realized that the game has a simplistic definition of a locked door, which was affecting my crews' movement through the ship.

The game's routing logic will not attempt to route an NPC through a closed and locked door. That seems fine. But, the game considers any door with something wired to its input node as a locked door, even if that something is a motion sensor. As a result, the game would not attempt to route any NPC through my motion-sensitive ship doors as long as they were closed. However, if I moved my character through a door, or if an NPC wandered near enough to a door, the door would open, and suddenly the game would route NPCs through it. However, once the door closed, the game would immediately cease routing NPCs through it, trapping them on whichever side of the door they ended up on.

While somewhat amusing, this ultimately interfered with my vision of how shipboard NPCs should work, so I modified all of the racial ship doors to open automatically, and removed the motion sensor wiring. You should be mindful of this issue for all non-automatically opening doors.

### NPC Personality Effects

While fixing the bed search logic described above, I noticed that some NPCs would get into a bed, immediately get out of bed, and repeat this behavior in a loop for many minutes. I also noticed that all such NPCs had the `nocturnal` personality type. After studying the behavior code, I realized that NPCs' personality trait information was not passed into the behavior logic loop, with the result that certain NPC personality types were not behaving as documented. In this specific case, nocturnal NPCs' sleep was correctly triggered at daytime (as opposed to being triggered at nighttime for all other NPC personality types), but the trait that sets their wake up trigger to be nighttime was not passed into the loop, and thus they were waking up at daytime like all other NPC personality types, triggering a sleep-wake loop during the daytime.

Another example of incorrectly behaving NPC personality types was the `fast` type. Fast NPCs are supposed to run everywhere, but were moving at the normal rate of speed due to this bug.

I fixed the main behavior loop to correctly pass in personality trait information.

### Miscellaneous Bug Fixes and Tweaks

* I fixed a number of visual bugs in how NPCs align themselves with objects or other NPCs to interact with them.
* When an NPC teleports from one location to another in a world (e.g., a tenant beaming to their colony deed) the beamin animation occurs immediately after the beamout animation, without waiting for the game to actually move the NPC, producing a jarring visual discontinuity. I fixed this in all of the behaviors that I found to exhibit it.
* The air hockey table rarely gets used because two NPCs have to randomly, independently decide to use it within a 10 second window of one another, in order for it to be used. I increased this window to 30 seconds.
* NPCs may play the piano for up to 30 seconds, but sound only plays for about 5.5 seconds. I tweaked this so that the sound loops for as long as the NPC plays the piano.

## Compatibility Notes

Whenever possible, I have used Starbound modding best practices, so this mod should be widely compatible. **However, this mod modifies behavior files, and there is no truly safe way to modify those. If this mod is combined with any other mod that modifies those same behavior files, the result is likely to be broken NPC behaviors. Furthermore, I had to overwrite two vanilla Lua functions, `findLoungable` and `playBehaviorReaction` to fix bugs. If this mod is combined with any other mod that modifies either of those functions, then conflicts may arise.**

## Uninstallation

This mod make no modifications to any game state. You should be able to add or remove it at any time.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's \_metadata file;
* A link is provided to https://github.com/rl-starbound/rl_bettercrew in the accompanying files or documentation of any derived work;
* The name "rl_bettercrew" is not used as the name of any derived work without explicit consent of the author(s); however, the name may be used in verbatim distribution of this mod.
