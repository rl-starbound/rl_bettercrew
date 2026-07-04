require "/scripts/pathutil.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

function rl_bettercrew_closeDoorsBehind(oldBox, newBox)
  -- The base game version of this function missed closing some doors
  -- and nearly all hatches. It also allowed NPCs to close doors in the
  -- player's face.

  local oll = rect.ll(oldBox)
  local our = rect.ur(oldBox)
  local nll = rect.ll(newBox)
  local nur = rect.ur(newBox)
  local bounds = {
    math.min(oll[1], nll[1]) + 0.125, math.min(oll[2], nll[2]) + 0.125,
    math.max(our[1], nur[1]) - 0.125, math.max(our[2], nur[2]) - 0.125
  }

  util.debugRect(bounds, "blue")

  if not world.rectTileCollision(bounds, {"Dynamic"}) then
    local openDoorIds = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "openDoor" } })
    for _, openDoorId in ipairs(openDoorIds) do
      local doorBounds = objectBounds(openDoorId)

      -- The core engine sometimes returns doors that don't actually
      -- intersect the bounds. Filter them out.
      if rect.intersects(bounds, doorBounds) then
        local entities = world.entityQuery(rect.ll(doorBounds), rect.ur(doorBounds), {includedTypes = {"npc", "player"}})

        -- Don't close doors on NPCs or players.
        if #entities == 0 then
          world.sendEntityMessage(openDoorId, "closeDoor")
        end
      end
    end
  end
end
