-- This file was supposed to be called `rl_bettercrew_reaction.lua`, but
-- it seems that there is an undocumented length limit on the paths to
-- behavior scripts. At its intended length, the behavior tree system
-- was not invoking the function in this file, but when I shortened the
-- length of this file name and made no other changes, the function was
-- invoked.

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
