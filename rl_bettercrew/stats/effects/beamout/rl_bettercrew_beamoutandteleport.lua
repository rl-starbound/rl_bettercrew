function trigger()
  -- In the vanilla implementation, beamin occurs immediately after
  -- beamout, which does not give the code the chance to setPosition of
  -- the entity to the new location, i.e., the beamin occurs at the same
  -- location as the beamout, and then the entity just appears at the
  -- new location. We solve this by removing the beamin code from this
  -- function and making it the responsibility of the caller to add the
  -- beamin effect after calling setPosition.

  if config.getParameter("teleport") then
    world.callScriptedEntity(entity.id(), "performTeleport")
    world.callScriptedEntity(entity.id(), "notify", { type = "performTeleport"})
  end
end
