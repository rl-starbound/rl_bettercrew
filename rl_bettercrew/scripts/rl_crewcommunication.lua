function rl_bettercrew_rallyCrew()
  local id = player.id()
  if world.entityExists(id) then
    world.sendEntityMessage(id, "recruits.rally")
  end
end
