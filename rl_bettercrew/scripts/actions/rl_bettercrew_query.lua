-- param cooldown
-- param defaultPosition
-- param defaultProbability
-- output position
function rl_bettercrew_crewAnchorObject(args, board, nodeId)
  -- Crew member NPCs can use this function, while on their captain's
  -- ship, to find crew anchor objects around which to congregate. This
  -- avoids the degenerate behavior of the crew mobbing the teleporter
  -- and ignoring the rest of the ship. If invoked when not on a player
  -- ship or if the NPC type is not supported, the behavior is the base
  -- game (i.e., the NPC will hang around their spawn position).

  local cooldownKey = "rl_bettercrew_crewAnchorObject__cooldown-"..nodeId
  local posKey = "rl_bettercrew_crewAnchorObject__position-"..nodeId

  local cooldown = board:getNumber(cooldownKey)
  if cooldown and world.time() < cooldown then
    return true, {position = board:getPosition(posKey) or args.defaultPosition}
  end

  local result = args.defaultPosition
  if math.random() > (args.defaultProbability or 0.083333) then
    local crewAnchorManager = world.loadUniqueEntity('rl_crewanchormanager')
    if crewAnchorManager ~= 0 then
      local response = world.sendEntityMessage(
        crewAnchorManager, 'getCrewAnchorObject', npc.npcType()
      ):result()
      if response then
        if response.options.useFootPosition then
          -- The returned position is expected to be where the NPC's
          -- feet should be. Subtracting the lower Y coordinate of the
          -- NPC's bounding box (which is non-positive) from the Y
          -- coordinate of the object position provides the position the
          -- NPC should aim for so that their foot position is correct.
          response.position[2] = response.position[2] - mcontroller.boundBox()[2]
        end
        result = response.position
      end
    end
  end

  board:setNumber(cooldownKey, world.time() + (args.cooldown or 30))
  board:setPosition(posKey, result)
  return true, {position = result}
end

function findLoungable(args, board)
  if not self.rl_bettercrew_findLoungableWarned then
    sb.logWarn("behavior action 'findLoungable' invoked; should call 'rl_bettercrew_findLoungable' instead")
    self.rl_bettercrew_findLoungableWarned = true
  end
  return rl_bettercrew_findLoungable(args, board)
end

-- param position
-- param range
-- param orderBy
-- param orientation
-- param unoccupied
-- param withoutEntity
-- output entity
-- output list
function rl_bettercrew_findLoungable(args, board)
  -- In the base game implementation, this function's `orderBy` and
  -- `withoutEntityId` args were ignored accidentally.

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
