local previous_init = init
local previous_uninit = uninit
local previous_update = update

local function finishRegistration(success)
  self.finishedRegisteringCrewAnchors = true
  self.successfullyRegisteredCrewAnchors = success

  -- If this script file is the only script assigned to this object,
  -- then after completing its crew anchor registration, this script
  -- should disable further updates. In the event that the object is
  -- uninit'ed and init'ed again, this will be reset.
  if #config.getParameter('scripts', {}) < 2 then script.setUpdateDelta(0) end
end

function init()
  if previous_init then previous_init() end

  self.crewAnchorObjectId = tostring(entity.id())
  self.crewAnchorTags = config.getParameter('crewAnchorTags', {})
end

function uninit()
  if self.successfullyRegisteredCrewAnchors then
    world.sendEntityMessage(
      'techstation', 'deregisterCrewAnchorObject',
      self.crewAnchorObjectId, self.crewAnchorTags
    ):result()
  end

  if previous_uninit then previous_uninit() end
end

function update(dt)
  if not self.finishedRegisteringCrewAnchors then
    if world.loadUniqueEntity('techstation') == 0 then
      finishRegistration()
    else
      if world.sendEntityMessage(
        'techstation', 'registerCrewAnchorObject',
        self.crewAnchorObjectId, self.crewAnchorTags, entity.position()
      ):result() then
        finishRegistration(true)
      end
    end
  end

  if previous_update then previous_update(dt) end
end
