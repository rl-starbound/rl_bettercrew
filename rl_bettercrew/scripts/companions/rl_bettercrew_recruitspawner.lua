function Recruit:getPersistentEffects()
  local effects = jarray()

  -- The player's armor takes effect if the player is spawning the recruit:
  if getRecruitPersistentEffects then
    util.appendLists(effects, getRecruitPersistentEffects())
  end

  return effects
end
