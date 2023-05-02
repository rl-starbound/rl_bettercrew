-- param position
-- param range
-- param orderBy
-- param orientation
-- param unoccupied
-- param withoutEntity
-- output entity
-- output list
function findLoungable(args, board)
  -- In the vanilla implementation, this function's orderBy and
  -- withoutEntityId args were ignored accidentally.

  if args.position == nil then return false end

  local queryArgs = {
    order = args.orderBy,
    orientation = args.orientation,
    withoutEntityId = args.withoutEntity
  }
  local loungables = world.loungeableQuery(args.position, args.range, queryArgs)

  if args.unoccupied then
    local unoccupied = {}
    for _,loungableId in pairs(loungables) do
      if not world.loungeableOccupied(loungableId) then
        table.insert(unoccupied, loungableId)
      end
    end
    loungables = unoccupied
  end

  if #loungables > 0 then
    return true, {entity = loungables[1], list = loungables}
  else
    return false
  end
end

-- param reaction
function playBehaviorReaction(args, board, nodeId, dt)
  -- In the vanilla implementation, this function ignored personality of
  -- NPCs when passing parameters to behavior trees. This caused, among
  -- other problems, nocturnal NPCs to be unable to sleep.

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

-- param defaultPosition
-- output position
function rl_bettercrew_crewAnchorObject(args, board)
  if math.random() < 0.125 then
    return true, {position = args.defaultPosition}
  end
  local result = world.sendEntityMessage(
    'techstation', 'getCrewAnchorObject', npc.npcType()
  ):result()
  if not result then
    return true, {position = args.defaultPosition}
  end
  return true, {position = result}
end

-- param direction
-- param run
function rl_bettercrew_moveUnidirectionally(args, board, node)
  -- In the vanilla function `move`, the args (specifically `direction`)
  -- are updated on each tick. In some invocations, this caused NPCs to
  -- become stuck moving back and forth rapidly if the `move` command
  -- was invoked when the NPC was directly above or below their "home"
  -- location. In this variant, we read the args only on the initial
  -- function call.

  if args.direction == nil then return false end
  local direction = util.toDirection(args.direction)
  local run = args.run
  local bounds = mcontroller.boundBox()

  while true do
    if config.getParameter("pathing.forceWalkingBackwards", false) then
      if run == true then run = mcontroller.movingDirection() == mcontroller.facingDirection() end
    end

    local position = mcontroller.position()
    position = {position[1], math.ceil(position[2]) - (bounds[2] % 1)} -- align bottom of the bound box with the ground

    local move = false
    -- Check for walls
    for _,yDir in pairs({0, -1, 1}) do
      --util.debugRect(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir})), "yellow")
      if not world.rectTileCollision(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir}))) then
        move = true
        break
      end
    end

    -- Also specifically check for a dumb collision geometry edge case where the ground goes like:
    --
    --        #
    -- ###### ######
    -- #############
    local boundsEnd = direction > 0 and bounds[3] or bounds[1]
    local wallPoint = {position[1] + boundsEnd + direction * 0.5, position[2] + bounds[2] + 0.5}
    local groundPoint = {position[1] + boundsEnd - direction * 0.5, position[2] + bounds[2] - 0.5}
    if world.pointTileCollision(wallPoint) and not world.pointTileCollision(groundPoint) then
      move = false
    end

    -- Check for ground for the entire length of the bound box
    -- Makes it so the entity can stop before a ledge
    if move then
      local boundWidth = bounds[3] - bounds[1]
      local groundRect = rect.translate({bounds[1], bounds[2] - 1.0, bounds[3], bounds[2]}, position)
      local y = 0
      for x = boundWidth % 1, math.ceil(boundWidth) do
        move = false
        for _,yDir in pairs({0, -1, 1}) do
          --util.debugRect(rect.translate(groundRect, {direction * x, y + yDir}), "blue")
          if world.rectTileCollision(rect.translate(groundRect, {direction * x, y + yDir}), {"Null", "Block", "Dynamic", "Platform"}) then
            move = true
            y = y + yDir
            break
          end
        end
        if move == false then break end
      end
    end

    if move then
      moved = true
      mcontroller.controlMove(direction, run)
      if not self.setFacingDirection then controlFace(direction) end
    else
      if moved then
        mcontroller.setXVelocity(0)
        mcontroller.clearControls()
      end
      return false
    end
    coroutine.yield()
  end
end
