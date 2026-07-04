-- This file was supposed to be called `rl_bettercrew_movement.lua`, but
-- it seems that there is an undocumented length limit on the paths to
-- behavior scripts. At its intended length, the behavior tree system
-- was not invoking the functions in this file, but when I shortened the
-- length of this file name and made no other changes, the functions
-- were invoked.

require "/scripts/rl_bettercrew_pathutil.lua"

-- param position
-- param pathOptions
-- param run
-- param runSpeed
-- param groundPosition
-- param minGround
-- param maxGround
-- param avoidLiquid
-- param closeDoors
-- output direction
-- output pathfinding
function rl_bettercrew_moveToPosition(args, board, node)
  -- In the base game implementation of the function `moveToPosition`,
  -- the function may yield with a table, which will contain the key
  -- `pathfinding`. If the function returns true or false, it does not
  -- return any table. If the table is nil, then the outputs will not be
  -- set to nil, but will retain their last yielded setting. In other
  -- words, if the final yield returned `pathfinding = true`, and then
  -- the function returned success due to finishing moving to the
  -- destination, then the output `pathfinding` variable will remain
  -- true. And if a series of subsequent calls immediately return true
  -- without yielding because the NPC doesn't need to move, then the
  -- pathing time limit code will mistakenly believe the function is
  -- stuck pathing and abort it. This function is similar to the
  -- original, but it explicitly returns a table containing appropriate
  -- values when the function returns success or failure. Additionally,
  -- this function calls a more sophisticated function to close doors
  -- behind the NPC, ensuring that doors and hatches are closed.

  if args.position == nil then
    return false, {pathfinding = false, direction = mcontroller.facingDirection()}
  end

  if entity.entityType() == "npc" then npc.resetLounging() end
  local pathOptions = applyDefaults(args.pathOptions or {}, {
    returnBest = false,
    mustEndOnGround = mcontroller.baseParameters().gravityEnabled,
    maxDistance = 200,
    swimCost = 5,
    dropCost = 5,
    boundBox = mcontroller.boundBox(),
    droppingBoundBox = rect.pad(mcontroller.boundBox(), {0.2, 0}), --Wider bound box for dropping
    standingBoundBox = rect.pad(mcontroller.boundBox(), {-0.7, 0}), --Thinner bound box for standing and landing
    smallJumpMultiplier = 1 / math.sqrt(2), -- 0.5 multiplier to jump height
    jumpDropXMultiplier = 1,
    enableWalkSpeedJumps = true,
    enableVerticalJumpAirControl = false,
    maxFScore = 400,
    maxNodesToSearch = 70000,
    maxLandingVelocity = -10.0,
    liquidJumpCost = 15
  })

  local entityPreviousBox = rect.translate(mcontroller.boundBox(), mcontroller.position())

  local lastPosition = false
  local targetPosition = {args.position[1], args.position[2]}

  local updateTarget = function()
    lastPosition = {args.position[1], args.position[2]}
    if args.groundPosition then
      targetPosition = findGroundPosition(lastPosition, args.minGround, args.maxGround, args.avoidLiquid)
    else
      targetPosition = lastPosition
    end
  end

  updateTarget()
  if not targetPosition then
    return false, {pathfinding = false, direction = mcontroller.facingDirection()}
  end
  local result = mcontroller.controlPathMove(targetPosition, args.run, pathOptions)
  while true do
    if not lastPosition or world.magnitude(args.position, lastPosition) > 2 then
      updateTarget()
      if not targetPosition then
        return false, {pathfinding = false, direction = mcontroller.facingDirection()}
      end
    end

    if result == false or result == true then
      return result, {pathfinding = false, direction = mcontroller.facingDirection()}
    end
    result = mcontroller.controlPathMove(targetPosition, args.run)
    if not self.setFacingDirection then 
      if not mcontroller.groundMovement() then
        controlFace(mcontroller.velocity()[1])
      elseif mcontroller.running() or mcontroller.walking() then
        controlFace(mcontroller.movingDirection())
      end
    end

    if entity.entityType() == "npc" then
      -- The invocation of `openDoorsAhead` is commented out because the
      -- core engine handles opening doors as of v1.4.0. This causes a
      -- bug because this action is used by aggroed non-ghost flying
      -- monsters, which can now open doors too. Repairing this bug will
      -- require a fix in the core engine.

      --openDoorsAhead()
      if args.closeDoors then
        local entityNewBox = rect.translate(mcontroller.boundBox(), mcontroller.position())
        rl_bettercrew_closeDoorsBehind(entityPreviousBox, entityNewBox)
        entityPreviousBox = entityNewBox
      end
    end

    coroutine.yield(nil, {pathfinding = mcontroller.pathfinding(), direction = mcontroller.facingDirection()})
  end

  return true, {pathfinding = false, direction = mcontroller.facingDirection()}
end

-- param direction
-- param run
function rl_bettercrew_moveUnidirectionally(args, board, node)
  -- In the base game implementation of the function `move`, the args
  -- (specifically `direction`) are re-interpreted on each update. This
  -- caused NPCs to become stuck moving back and forth rapidly if the
  -- `move` command was invoked when the NPC was directly above or below
  -- their "home" location. This variant reads the args only on the
  -- initial invocation.

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

--------------------------------------------
--DOORS
--------------------------------------------

-- param direction
-- param distance
-- param openLocked
function rl_bettercrew_openDoors(args, board)
  -- The base game version of this function could open doors that did
  -- not actually intersect the bounds, due to a quirk in the core
  -- engine's `world.entityQuery` function. This version strictly opens
  -- only doors that intersect the bounds.
  --
  -- Also, it's worth noting that the base game's description of this
  -- function was, "Returns true if the path is clear from doors".
  -- However, that was not an accurate description of what the base game
  -- function did. It returned true if no closed doors existed within
  -- the bounds or if it was successful in opening at least 1 closed
  -- door. This version of the function makes no changes to those
  -- semantics.

  local direction = args.direction or mcontroller.facingDirection() --Default to opening doors in front

  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  bounds[2] = bounds[2] + 0.125
  bounds[4] = bounds[4] - 0.125
  if direction > 0 then
    bounds[1] = bounds[3]
    bounds[3] = bounds[3] + args.distance
  else
    bounds[3] = bounds[1]
    bounds[1] = bounds[1] - args.distance
  end

  util.debugRect(bounds, "blue")

  local opened = true
  if world.rectTileCollision(bounds, {"Dynamic"}) then
    opened = false

    -- There is a colliding object in the way. See if we can open it
    local closedDoors = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "closedDoor" } })
    if args.openLocked then
      local lockedDoors = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "lockedDoor" } })
      closedDoors = util.mergeLists(closedDoors, lockedDoors)
    end
    for _, doorId in ipairs(closedDoors) do
      local doorBounds = objectBounds(doorId)

      -- The core engine sometimes returns doors that don't actually
      -- intersect the bounds. Treat them as though they were opened
      -- successfully.
      if not rect.intersects(bounds, doorBounds) then
        opened = true
      else
        local toDoor = world.distance(world.entityPosition(doorId), mcontroller.position())
        if toDoor[1] * direction > 0 then
          world.callScriptedEntity(doorId, "openDoor")
          opened = true
        end
      end
    end
  end

  return opened
end

-- param direction
-- param distance
function rl_bettercrew_closeDoors(args, board)
  -- The base game version of this function could close doors that did
  -- not actually intersect the bounds, due to a quirk in the core
  -- engine's `world.entityQuery` function. This version strictly closes
  -- only doors that intersect the bounds.
  --
  -- Also, it's worth noting that the base game's description of this
  -- function was, "Close doors - returns false if there are still open
  -- doors, true if there are no open doors". However, that was not an
  -- accurate description of what the base game function did. It
  -- returned true if at least 1 closed door already existed within the
  -- bounds, if no open doors existed within the bounds, or if it was
  -- successful in closing at least 1 open door. This version of the
  -- function makes no changes to those semantics.

  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  bounds[2] = bounds[2] + 0.5
  bounds[4] = bounds[4] - 0.5
  local direction = args.direction or -mcontroller.facingDirection()
  if direction < 0 then
    bounds[3] = bounds[1] - 1
    bounds[1] = bounds[1] - args.distance
  else
    bounds[1] = bounds[3] + 1
    bounds[3] = bounds[3] + args.distance
  end

  util.debugRect(bounds, "blue")

  if not world.rectTileCollision(bounds, {"Dynamic"}) then
    local openDoorIds = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "openDoor" } })
    local closed = (#openDoorIds > 0)
    if #openDoorIds == 0 then
      return true
    else
      for _, openDoorId in ipairs(openDoorIds) do
        local doorBounds = objectBounds(openDoorId)

        -- The core engine sometimes returns doors that don't actually
        -- intersect the bounds. Treat them as though they were closed
        -- successfully.
        if not rect.intersects(bounds, doorBounds) then
          closed = true
        else
          local npcs = world.entityQuery(rect.ll(doorBounds), rect.ur(doorBounds), {includedTypes = {"npc", "player"}})
          if #npcs == 0 then
            world.sendEntityMessage(openDoorId, "closeDoor")
            closed = true
          end
        end
      end
    end
    return closed
  end
  return true
end
