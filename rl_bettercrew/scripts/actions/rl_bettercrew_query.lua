-- param defaultPosition
-- output position
function rl_bettercrew_crewAnchorObject(args, board)
  -- Crew member NPCs can use this function, while on their captain's
  -- ship, to find crew anchor objects around which to congregate. This
  -- avoids the degenerate behavior of the crew mobbing the teleporter
  -- and ignoring the rest of the ship. If invoked when not on a player
  -- ship, not on a player ship with a supported techstation, or if the
  -- NPC type is not supported, the behavior is equivalent to the base
  -- game (i.e., the NPC will hang around their spawn position).

  if math.random() < 0.1 then
    return true, {position = args.defaultPosition}
  end
  local techStation = world.loadUniqueEntity('techstation')
  if techStation == 0 then
    return true, {position = args.defaultPosition}
  end
  local result = world.sendEntityMessage(
    techStation, 'getCrewAnchorObject', npc.npcType()
  ):result()
  if not result then
    return true, {position = args.defaultPosition}
  end
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
