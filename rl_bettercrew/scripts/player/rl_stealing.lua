require "/scripts/player/stealing.lua"

local previous_messageStagehands = messageStagehands

function messageStagehands(position, messageType)
  if player.isAdmin() then return end

  return previous_messageStagehands(position, messageType)
end
