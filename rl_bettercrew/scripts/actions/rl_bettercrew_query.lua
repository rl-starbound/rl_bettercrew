-- param position
-- param range
-- param orderBy
-- param orientation
-- param unoccupied
-- param withoutEntity
-- output entity
-- output list
function findLoungable(args, board)
  -- In the base implementation, this function's orderBy and
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
