local previous_init = init
function init()
  previous_init()

  self.rl_currentWorldId = self.rl_currentWorldId or player.worldId()
  self.rl_ownShipWorldId = self.rl_ownShipWorldId or player.ownShipWorldId()
end

local previous_update = update
function update(dt)
  retval = previous_update(dt)
  if retval ~= nil then return retval end

  if self.bettercrew_crewanchormanager == nil then
    self.bettercrew_crewanchormanager = rl_bettercrew_crewanchormanager_init()
  end
end

function rl_bettercrew_crewanchormanager_init()
  if self.rl_currentWorldId ~= self.rl_ownShipWorldId then
    return false
  end

  if self.rl_bettercrew_crewanchormanager_loader then
    local status, result = coroutine.resume(
      self.rl_bettercrew_crewanchormanager_loader
    )
    if not status then error(result) end
    if result then
      self.rl_bettercrew_crewanchormanager_loader = nil
      return result
    end
  else
    self.rl_bettercrew_crewanchormanager_loader = coroutine.create(
      rl_bettercrew_crewanchormanager_load
    )
  end
end

function rl_bettercrew_crewanchormanager_load()
  local stagehandType = "rl_crewanchormanager"
  local stagehandParameters = { tryUniqueId = stagehandType }

  while true do
    local findManager = world.findUniqueEntity(stagehandType)
    while not findManager:finished() do coroutine.yield() end
    if findManager:succeeded() then
      -- findUniqueEntity returns the position, about which we do not
      -- care. We only care to validate the existence of the unique Id.
      return stagehandType
    else
      world.spawnStagehand({1024, 1028}, stagehandType, stagehandParameters)
    end
    coroutine.yield()
  end
end
