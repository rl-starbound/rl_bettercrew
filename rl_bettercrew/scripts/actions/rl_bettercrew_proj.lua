-- This file was supposed to be called `rl_bettercrew_projectiles.lua`,
-- but it seems that there is an undocumented length limit on the paths
-- to behavior scripts. At its intended length, the behavior tree system
-- was not invoking the function in this file, but when I shortened the
-- length of this file name and made no other changes, the function was
-- invoked.

-- param fromPosition
-- param toPosition
-- param speed
-- param gravityMultiplier
-- param collisionCheck
-- param useHighArc
-- output aimVector
-- output aimAngle
function rl_bettercrew_projectileAimVector(args, board)
  -- The base game version of this function normalized the aim vector
  -- before returning it to the caller. This was mathematically
  -- unnecessary and caused loss of floating point precision, which
  -- threw off aim.

  if args.fromPosition == nil or args.speed == nil or args.toPosition == nil then return false end
  local gravityMultiplier = args.gravityMultiplier or mcontroller.baseParameters().gravityMultiplier

  local toTarget = world.distance(args.toPosition, args.fromPosition)
  local aimVector, foundVector = util.aimVector(toTarget, args.speed, gravityMultiplier, args.useHighArc)
  if not foundVector then return false end

  -- Simulate the arc and do basic line and poly collision checks
  if args.collisionCheck then
    local normalizedAimVector = vec2.norm(aimVector)
    local velocity = vec2.mul(normalizedAimVector, args.speed)
    local startArc = mcontroller.position()
    local x = 0
    while x < math.abs(toTarget[1]) do
      local time = x / math.abs(velocity[1])
      local yVel = velocity[2] - (gravityMultiplier * world.gravity(mcontroller.position()) * time)
      local step = vec2.add({util.toDirection(normalizedAimVector[1]) * x, ((velocity[2] + yVel) / 2) * time}, mcontroller.position())

      if world.lineTileCollision(startArc, step) or world.polyCollision(poly.translate(mcontroller.collisionPoly(), step)) then
        return false
      end

      startArc = step
      local arcVector = vec2.norm({velocity[1], yVel})
      x = x + math.abs(arcVector[1])
    end
  end

  return true, {aimVector = aimVector, aimAngle = vec2.angle(aimVector)}
end
