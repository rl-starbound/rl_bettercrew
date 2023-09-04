require "/scripts/companions/rl_bettercrew_recruitspawner.lua"

local previous_init = init
local previous_update = update

local recruitPersistentEffectsStrings = {
    electricblockaugment = true,
    fireblockaugment = true,
    iceblockaugment = true,
    poisonblockaugment = true
  }

-- This table should be equal to /scripts/companions/player.lua table
-- petPersistentEffects.
local recruitPersistentEffectsTables = {
    powerMultiplier = true,
    protection = true,
    maxHealth = true
  }

function getRecruitPersistentEffects()
  local effects = util.filter(status.getPersistentEffects("armor"),
    function (effect)
      local effectType = type(effect)
      if effectType == "table" then
        return recruitPersistentEffectsTables[effect.stat]
      elseif effectType == "string" then
        return recruitPersistentEffectsStrings[effect]
      end
    end)
  if onOwnShip() then
    util.appendLists(effects, recruitSpawner:getShipPersistentEffects())
  end
  return effects
end

function init()
  previous_init()

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
