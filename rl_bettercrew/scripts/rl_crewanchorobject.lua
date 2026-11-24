require '/scripts/vec2.lua'

local previous_init = init
local previous_uninit = uninit
local previous_update = update

local function finishRegistration(success)
  self.finishedRegisteringCrewAnchors = true
  self.successfullyRegisteredCrewAnchors = success

  if #config.getParameter('scripts', {}) < 2 then
    -- If this script file is the only script assigned to this object,
    -- then after completing its crew anchor registration, this script
    -- should disable further updates. In the event that the object is
    -- uninit'ed and init'ed again, this will be reset.
    script.setUpdateDelta(0)
  elseif self.originalScriptDelta then
    -- If this script temporarily set scriptDelta to 1, then reset it to
    -- the original scriptDelta.
    script.setUpdateDelta(self.originalScriptDelta)
    self.originalScriptDelta = nil
  end
end

function init()
  if previous_init then previous_init() end

  self.crewAnchorObjectId = tostring(entity.id())
  self.crewAnchorOptions = config.getParameter('crewAnchorOptions', {})
  if self.crewAnchorOptions.useFootPosition == nil then
    self.crewAnchorOptions.useFootPosition = true
  end
  self.crewAnchorTags = config.getParameter('crewAnchorTags', {})

  -- For objects, the default scriptDelta is 5 ticks, if not specified
  -- in the object configuration.
  local originalScriptDelta = config.getParameter('scriptDelta', 5)

  if originalScriptDelta ~= 1 then
    -- Object registration requires the update function to be called,
    -- the sooner the better. If the object definition sets scriptDelta
    -- to 0 or to greater than 1, then temporarily set it to 1 to allow
    -- registration to occur ASAP.
    self.originalScriptDelta = originalScriptDelta
    script.setUpdateDelta(1)
  end
end

function uninit()
  if self.successfullyRegisteredCrewAnchors then
    world.sendEntityMessage(
      'rl_crewanchormanager', 'deregisterCrewAnchorObject',
      self.crewAnchorObjectId, self.crewAnchorTags
    ):result()
  end

  if previous_uninit then previous_uninit() end
end

function update(dt)
  if not self.finishedRegisteringCrewAnchors then
    if world.loadUniqueEntity('rl_crewanchormanager') == 0 then
      finishRegistration()
    else
      local offset = self.crewAnchorOptions[
        object.direction() > 0 and 'offsetRight' or 'offsetLeft'
      ] or self.crewAnchorOptions.offset or {0, 0}
      if world.sendEntityMessage(
        'rl_crewanchormanager', 'registerCrewAnchorObject',
        self.crewAnchorObjectId, self.crewAnchorTags,
        vec2.add(entity.position(), offset),
        {useFootPosition = not not self.crewAnchorOptions.useFootPosition}
      ):result() then
        finishRegistration(true)
      end
    end
  end

  if previous_update then previous_update(dt) end
end
