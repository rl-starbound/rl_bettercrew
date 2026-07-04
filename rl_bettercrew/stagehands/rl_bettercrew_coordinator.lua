-- In the base game, this function crashes if `entityId` is not a member
-- of the group. Instead, return nil, as though the requested resource
-- does not exist.
function onGetResource(entityId, resource)
  local member = self.memberResources[entityId]
  if member == nil then return nil end
  local memberResource = member:get(resource)
  if memberResource ~= nil then
    return memberResource
  else
    return self.groupResources:get(resource)
  end
end
