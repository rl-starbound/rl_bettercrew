-- param entity
-- output position
function rl_bettercrew_entityPosition(args, board)
  -- NPCs and players may crouch. The crouching collision polygon for
  -- humanoid races is 0.5 blocks below the entity position, resulting
  -- in hostile NPCs aiming too high to hit them. Check for this case
  -- and return an adjusted entity position. Note, this may not work in
  -- the case of modded races with even more exotic collision geometry,
  -- but we'll cross that bridge if we come to it.

  if args.entity == nil or not world.entityExists(args.entity) then return false end

  local position = world.entityPosition(args.entity)

  local entityType = world.entityType(args.entity)
  if entityType == "npc" or entityType == "player" then
    local entities = world.entityQuery(
      position, vec2.add(position, 0.125), {includedTypes = {entityType}}
    )
    if not contains(entities, args.entity) then
      position = vec2.add(position, {0, -0.75})
    end
  end

  return true, {position = position, x = position[1], y = position[2]}
end

-- param position
function rl_bettercrew_gravityPositive(args, board)
  if args.position == nil then return false end

  return world.gravity(args.position) > 0
end
