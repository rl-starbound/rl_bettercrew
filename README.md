# Starbound mod: Better Crew & NPC Behavior

You recruit twelve NPCs to become your ship's crew, and what happens? They swarm the teleporter and ignore the rest of your ship. This mod improves NPC behaviors in many ways, focusing on better shipboard behavior of the crew, but also fixing a large number of bugs in NPC combat and general NPC behavior.

**Read and understand the compatibility notes before installing!**

## Compatibility

**You are strongly advised to backup your storage folder before installing and testing this mod.**

This mod should be generally compatible. However, it patches behavior files and replaces faulty Lua functions, and there is no 100% safe way to do that. If it is combined with other mods that alter the same behavior files or Lua functions, conflicts may happen. If conflicts happen, one possible reaction is that all NPCs will die, and if the affected NPCs are not crew or tenants, they will be gone forever. Please see the documentation for detailed [compatibility notes](user-guide.md#compatibility-notes) on the behavior files and Lua scripts altered by this mod.

This mod is incompatible with *NPCs Aren't Stupid* and *Smart Crew*, but can be considered a replacement for both. It is also incompatible with *Supper's Combat Overhaul*, and while it is not a true replacement for that mod, it does provide improved NPC combat when compared to the base game.

It is generally compatible with *Corbent's Interactive Crew*, *Earth's Finest*, and *Frackin Universe*, but some of its behavior is overridden by those mods. It is compatible with *BYOS* (and the *Frackin Universe* BYOS), but see the documentation for more information on [using it with BYOS](user-guide.md#crew-anchor-objects-and-byos).

## Mod Functionality

### Crew Anchor Objects

While onboard their ship, crew will be attracted to certain objects. These objects will pull the crew away from their spawn location, the teleporter. If you have done a good job designing your ship, this should result in your crew spreading throughout the ship and moving around in a way that looks natural. In general, crew are attracted to objects that are related to their occupations, and this mod patches almost 130 base game [objects](user-guide.md#crew-anchor-objects) with crew anchor tags.

This mod patches only base game objects and crew types, and I do not intend to add patches for modded content into it. Mod authors are encouraged to refer to the documentation for [adding compatibility](modding-guide.md#adapting-modded-objects-with-crew-anchor-tags) for custom objects and crew types.

[Extensions](user-guide.md#extensions) can also be found in the documentation.

### NPC Combat Improvements

**This mod does not attempt to add new NPC combat strategies, tactics, or predictive aiming.** Instead, this mod makes narrowly-targeted improvements to existing tactics. These improvements are small individually, but collectively should provide a noticeable improvement in the quality of NPC combat. See the documentation for details on the [combat improvements](user-guide.md#npc-combat-improvements).

### Crew Rallying

When the player brought a crew member off ship and then ordered them to stop following, to make them begin following again, the player had to find and interact with them.

I have added new functionality to allow the player to rally all non-following crew who are on the same (non-ship) world as the player. When summoned, they will begin following the player, and this will result in them running or teleporting to the player's current position. See the documentation for instructions on how to [rally your crew](user-guide.md#crew-rallying).

### Additional Fixes and Tweaks

This mod contains too many improvements to list on this page. See the [documentation](user-guide.md#additional-fixes-and-improvements) for the full list of improvements. The major highlights are:

* Fixed cases where NPCs froze in place or spun back and forth indefinitely.
* Prevented NPCs from closing a door if a player is in the doorway.
* Fixed the close-door logic so that NPCs also close hatches after passing through them.
* Improved NPC reactions to use their personality types.
* Replaced faulty NPC item-swap functions that could lose an item set during a swap, possibly disarming the NPC.
* Extended the elemental resistance and status immunity of the base game elemental EPP augments to crew, when such augments are equipped by the player.
* Increased the search radius for beds and chairs to 300 blocks for crew members onboard their ship.
* Made crew hold their positions when off ship and the player orders them not to follow.
* Made medics wait for the player to take damage before applying healing effects.
* Made village guards respond to friendly fire.
* Changed the stealing mechanic to ignore players who currently have admin privileges.

## Uninstallation

**Uninstalling this mod may cause your worlds to crash.** If you no longer want to use this mod, you must replace it with the [Better Crew Uninstalled](README_uninstalled.md) mod, which defines a minimal set of resources that allow safe removal of this mod.

## Collaboration

If you have any questions, bug reports, or ideas for improvement, please contact me via [Chucklefish Forums](https://community.playstarbound.com/members/rl-starbound.885402/), [Github](https://github.com/rl-starbound), [Reddit](https://www.reddit.com/user/rl-starbound/), or the Starbound Discord (`rl.steam`). Steam users may wish to subscribe to my [workshop profile](https://steamcommunity.com/profiles/76561198808510456/myworkshopfiles/) for updates on this and my other mods. Also please let me know if you plan to republish this mod elsewhere, so we can maintain open lines of communication to ensure timely updates.

You can find additional details about this mod in the [user guide](user-guide.md) and the [modding guide](modding-guide.md). I don't intend to build support for other mods directly into this mod, but I'll be glad to give help or advice on writing compatibility mods.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's `_metadata` file;
* A link is provided to the [source repository](https://github.com/rl-starbound/rl_bettercrew) in the accompanying files or documentation of any derived work;
* The exact names "Better Crew" and "Better Crew & NPC Behavior" are not used as the metadata `friendlyName` of any derived work without explicit consent of the author(s); however, the names may be used in verbatim distribution of this mod. For the purposes of this clause, minimal changes to metadata files to allow distribution on Steam shall be considered a verbatim distribution so long as authorship attribution remains. In other words, if you distribute an altered version of this mod, you must make that clear in the name.
