require "/scripts/companions/rl_bettercrew_recruitspawner.lua"

local previous_init = init
local previous_update = update

-- This table should be equal to the `/scripts/companions/player.lua`
-- table `petPersistentEffects`.
local recruitPersistentEffects = {
    powerMultiplier = true,
    protection = true,
    maxHealth = true
  }

function getRecruitPersistentEffects()
  local effects = {}
  for _,effect in ipairs(status.getPersistentEffects("armor")) do
    local effectType = type(effect)
    if effectType == "table" then
      if recruitPersistentEffects[effect.stat] then
        table.insert(effects, effect)
      end
    elseif effectType == "string" then
      local translation = self.recruitExtraPersistentEffects.translations[effect]
      if translation then
        util.appendLists(effects, translation)
      elseif self.recruitExtraPersistentEffects.allowedUniqueEffects[effect] then
        table.insert(effects, effect)
      end
    end
  end
  if onOwnShip() then
    util.appendLists(effects, recruitSpawner:getShipPersistentEffects())
  end
  return effects
end

function init()
  previous_init()

  self.recruitExtraPersistentEffects = config.getParameter("recruitExtraPersistentEffects")
  for k,v in pairs(self.recruitExtraPersistentEffects.translations) do
    local output = {}
    for _,t in ipairs(v) do
      table.insert(output, {stat = t.stat, [t.statType] = root.assetJson(t.assetJson)})
    end
    self.recruitExtraPersistentEffects.translations[k] = output
  end

  self.rallyRecruitsRadioMessageTimer = 0
  self.rallyRecruitsRadioMessageTimeout = 10
  message.setHandler("recruits.rally", localHandler(rallyRecruits))
end

function update(dt)
  previous_update(dt)

  if self.rallyRecruitsRadioMessageTimer > 0 then
    self.rallyRecruitsRadioMessageTimer = self.rallyRecruitsRadioMessageTimer - dt
  end
end

function rallyRecruits()
  if onOwnShip() then return end
  world.sendEntityMessage(player.id(), "rl_bettercrew_playCrewCommunicationSound")
  if not player.hasCompletedQuest("shiprepair") then
    if self.rallyRecruitsRadioMessageTimer <= 0 then
      player.radioMessage("rallyRecruitsPremature")
      self.rallyRecruitsRadioMessageTimer = self.rallyRecruitsRadioMessageTimeout
    end
    return
  end
  if recruitSpawner:crewSize() < 1 then
    if self.rallyRecruitsRadioMessageTimer <= 0 then
      player.radioMessage("rallyRecruitsNoCrew")
      self.rallyRecruitsRadioMessageTimer = self.rallyRecruitsRadioMessageTimeout
    end
    return
  end
  local sent = false
  for uuid, recruit in pairs(recruitSpawner.followers) do
    local promise = recruit:sendMessage("recruit.confirmFollow", true)
    if promise then
      promises:add(promise, function (success)
          recruitSpawner:recruitFollowing(false, uuid, recruit:toJson())
        end)
      sent = true
    end
  end
  if not sent and self.rallyRecruitsRadioMessageTimer <= 0 then
    player.radioMessage("rallyRecruitsNoResponse")
    self.rallyRecruitsRadioMessageTimer = self.rallyRecruitsRadioMessageTimeout
  end
end
