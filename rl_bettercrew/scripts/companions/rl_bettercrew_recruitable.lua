-- The base game version of this function calculates the armor power
-- multiplier, then raises it to the power of 2. However, the base game
-- crewmember npctype file quarters that power multiplier, resulting in
-- crew that are far less powerful than the player or other NPCs, given
-- the player's equipped armor. (Actually, the base game crewmember
-- npctype file also sets the `powerMultiplierExponent` to 1, but due to
-- a bug, the code never sees that value and defaults to 2.) In this
-- version of the function, I calculate separate estimates of both the
-- armor bonus and the weapon level bonus based on the player's equipped
-- armor. Furthermore, this mod's patch to the crewmember npctype files
-- boosts crewmember power multiplier base values, resulting in crew
-- whose power is equivalent to most NPCs. The `powerMultiplierExponent`
-- in the crewmember npctype file is, as in the base game, ignored.
function recruitable.updateStatus(persistentEffects, damageTeam)
  -- We can't take the effects of BOTH the NPC's level AND the player's armor
  -- or we'd be overpowered.
  -- This happens the first time the NPC is recruited, before we've beamed off
  -- the planet and been respawned by the player.
  local takePlayerArmorEffects = npc.level() <= 1

  if persistentEffects and takePlayerArmorEffects then
    -- Approximates using same level weapon and armor
    -- since crew members don't level their weapons
    local armorPowerMultiplier = 1.0
    local weaponPowerMultiplier = 0.5
    persistentEffects = util.filter(persistentEffects, function(effect)
      if effect.stat and effect.stat == "powerMultiplier" and effect.baseMultiplier then
        armorPowerMultiplier = armorPowerMultiplier + (effect.baseMultiplier - 1.0)
        weaponPowerMultiplier = weaponPowerMultiplier + (effect.baseMultiplier - 1.0)
        return false
      else
        return true
      end
    end)
    local powerMultiplier = armorPowerMultiplier * weaponPowerMultiplier
    table.insert(persistentEffects, {stat = "powerMultiplier", baseMultiplier = powerMultiplier})

    status.setPersistentEffects("crew", persistentEffects)
  end
  if damageTeam then
    npc.setDamageTeam(damageTeam)
  end

  local portrait = nil
  if recruitable.portraitChanged then
    recruitable.portraitChanged = false
    portrait = world.entityPortrait(entity.id(), "full")
  end

  return {
      status = getCurrentStatus(),
      storage = preservedStorage(),
      portrait = portrait
    }
end
