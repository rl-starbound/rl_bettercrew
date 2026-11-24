require("/scripts/util.lua")

function init()
  if world.type() ~= "unknown" or
     type(world.getProperty("ship.fuel")) ~= "number"
  then
    script.setUpdateDelta(0)
    stagehand.die()
    return
  end

  local tryUniqueId = config.getParameter("tryUniqueId")
  if entity.uniqueId() ~= tryUniqueId then
    if world.loadUniqueEntity(tryUniqueId) == 0 then
      stagehand.setUniqueId(tryUniqueId)
    else
      script.setUpdateDelta(0)
      stagehand.die()
      return
    end
  end

  self.crewAnchorObjects = {}
  self.crewAnchorObjectsKeys = {}

  message.setHandler("deregisterCrewAnchorObject", deregisterCrewAnchorObject)
  message.setHandler("getCrewAnchorObject", getCrewAnchorObject)
  message.setHandler("registerCrewAnchorObject", registerCrewAnchorObject)
end

function deregisterCrewAnchorObject(_, _, objectId, tags)
  --logInfo("deregistering %s with tags %s", objectId, sb.printJson(tags))
  for _,tag in ipairs(tags) do
    if self.crewAnchorObjects[tag] then
      self.crewAnchorObjects[tag][objectId] = nil
      self.crewAnchorObjectsKeys[tag] = nil
    end
  end
  return true
end

function getCrewAnchorObject(_, _, tag)
  if self.crewAnchorObjects[tag] then
    self.crewAnchorObjectsKeys[tag] = self.crewAnchorObjectsKeys[tag] or
      util.keys(self.crewAnchorObjects[tag])
    if #self.crewAnchorObjectsKeys[tag] > 0 then
      local k = util.randomFromList(self.crewAnchorObjectsKeys[tag])
      --logInfo("querying for tag %s: found %s",
      --  tag, sb.printJson(self.crewAnchorObjects[tag][k])
      --)
      return self.crewAnchorObjects[tag][k]
    end
  end
  --logInfo("querying for tag %s: not found", tag)
end

function registerCrewAnchorObject(_, _, objectId, tags, pos, options)
  --logInfo("registering %s at %s with tags %s options %s",
  --  objectId, sb.printJson(pos), sb.printJson(tags), sb.printJson(options)
  --)
  for _,tag in ipairs(tags) do
    self.crewAnchorObjects[tag] = self.crewAnchorObjects[tag] or {}
    self.crewAnchorObjects[tag][objectId] = {
      position = pos,
      options = options
    }
    self.crewAnchorObjectsKeys[tag] = nil
  end
  return true
end

------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------

function logError(fmt, ...)
  sb.logError(
    "rl_crewanchormanager: %s", string.format(fmt, table.unpack({...}))
  )
end

function logWarn(fmt, ...)
  sb.logWarn(
    "rl_crewanchormanager: %s", string.format(fmt, table.unpack({...}))
  )
end

function logInfo(fmt, ...)
  sb.logInfo(
    "rl_crewanchormanager: %s", string.format(fmt, table.unpack({...}))
  )
end
