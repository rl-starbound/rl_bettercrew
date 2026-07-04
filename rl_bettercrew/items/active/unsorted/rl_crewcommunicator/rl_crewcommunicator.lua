require "/scripts/rl_crewcommunication.lua"

function update(dt, fireMode, shifting)
  if self.lastFireMode ~= fireMode then
    if fireMode == "primary" then
      rl_bettercrew_rallyCrew()
    end
    self.lastFireMode = fireMode
  end
end
