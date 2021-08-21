require("/scripts/util.lua")

local previous_init = init

local function deregisterCrewAnchorObject(_, _, objectId, tags)
  for _,tag in ipairs(tags) do
    if self.crewAnchorObjects[tag] then
      self.crewAnchorObjects[tag][objectId] = nil
      self.crewAnchorObjectsKeys[tag] = nil
    end
  end
  return true
end

local function getCrewAnchorObject(_, _, tag)
  if self.crewAnchorObjects[tag] then
    self.crewAnchorObjectsKeys[tag] = self.crewAnchorObjectsKeys[tag] or
      util.keys(self.crewAnchorObjects[tag])
    if #self.crewAnchorObjectsKeys[tag] > 0 then
      local k = util.randomFromList(self.crewAnchorObjectsKeys[tag])
      return self.crewAnchorObjects[tag][k]
    end
  end
end

local function registerCrewAnchorObject(_, _, objectId, tags, pos)
  for _,tag in ipairs(tags) do
    self.crewAnchorObjects[tag] = self.crewAnchorObjects[tag] or {}
    self.crewAnchorObjects[tag][objectId] = pos
    self.crewAnchorObjectsKeys[tag] = nil
  end
  return true
end

function init()
  previous_init()

  self.crewAnchorObjects = {}
  self.crewAnchorObjectsKeys = {}

  message.setHandler("deregisterCrewAnchorObject", deregisterCrewAnchorObject)
  message.setHandler("getCrewAnchorObject", getCrewAnchorObject)
  message.setHandler("registerCrewAnchorObject", registerCrewAnchorObject)
end
