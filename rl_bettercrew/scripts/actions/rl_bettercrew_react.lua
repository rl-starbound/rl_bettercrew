-- This file was supposed to be called `rl_bettercrew_reaction.lua`, but
-- it seems that there is an undocumented length limit on the paths to
-- behavior scripts. At its intended length, the behavior tree system
-- was not invoking the function in this file, but when I shortened the
-- length of this file name and made no other changes, the function was
-- invoked.

-- param position
-- param target
-- output position
-- output x
-- output y
function rl_bettercrew_npcToyGetFootPosition(args, board)
  -- Returns a position adjusted so that the NPC's feet will be at the
  -- input position, if the object requires foot positioning. The
  -- default for objects is to require foot positioning unless the
  -- `npcToy.useFootPosition` parameter is set to false. (In general,
  -- this should be set to false only for objects not intended to be
  -- placed on the ground, e.g., desktop or wall-mounted objects.)

  if args.position == nil then return false end
  local x = args.position[1]
  local y = args.position[2]

  if world.callScriptedEntity(args.target, "config.getParameter",
    "npcToy.useFootPosition", true
  ) then
    y = y - mcontroller.boundBox()[2]
  end

  return true, {position = {x, y}, x = x, y = y}
end

function playBehaviorReaction(args, board, nodeId, dt)
  if not self.rl_bettercrew_playBehaviorReactionWarned then
    sb.logWarn("behavior action 'playBehaviorReaction' invoked; should call 'rl_bettercrew_playBehaviorReaction' instead")
    self.rl_bettercrew_playBehaviorReactionWarned = true
  end
  return rl_bettercrew_playBehaviorReaction(args, board, nodeId, dt)
end

-- param reaction
function rl_bettercrew_playBehaviorReaction(args, board, nodeId, dt)
  -- In the base game implementation, this function ignored personality
  -- of NPCs when passing parameters to behavior trees. This caused,
  -- among other problems, nocturnal NPCs to be unable to sleep and fast
  -- NPCs not to run.

  local reaction = root.assetJson("/npcs/default_reactions.config:behaviorReactions")[args.reaction]

  local key = string.format("playBehaviorReaction-%s-%s", args.reaction, nodeId)
  local tree = ReactionTreeCache[key]
  if not tree then
    local parameters = sb.jsonMerge(
      self.behaviorConfig or config.getParameter("behaviorConfig", {}),
      reaction.parameters or {}
    )
    tree = behavior.behavior(reaction.behavior, parameters, _ENV, board)
    ReactionTreeCache[key] = tree
  else
    tree:clear()
  end

  while true do
    local result = tree:run(dt)
    if result == false or result == true then
      return result
    else
      dt = coroutine.yield()
    end
  end
end
