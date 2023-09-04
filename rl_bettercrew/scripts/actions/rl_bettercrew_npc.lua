function swapItemSlots(args, board)
  -- In the base implementation, there are edge cases in which a call to
  -- `npc.setItemSlot` will fail, sometimes returning false, and
  -- sometimes returning true but incorrectly setting the item in the
  -- slot to nil. If that happens, the core and instance values will go
  -- out of sync and the NPC may become disarmed. Fix this by verifying
  -- that the calls succeed before altering instance state.

  if not npc.setItemSlot("primary", self.sheathedPrimary) then
    -- This should not happen with a correctly-defined NPC.
    sb.logWarn("swapItemSlots failure at npc.setItemSlot(primary = " .. (type(self.sheathedPrimary) == "table" and util.tableToString(self.sheathedPrimary) or tostring(self.sheathedPrimary)) .. "). Aborting swap.")
    return false
  end
  if (not self.sheathedPrimary) ~= (not npc.getItemSlot("primary")) then
    -- Edge cases exist in which `npc.setItemSlot` succeeds but then
    -- `npc.getItemSlot` returns nil. This seems to occur in relation to
    -- swapping items while lounging, but there may be other causes.

    --sb.logWarn("swapItemSlots unknown failure at npc.setItemSlot(primary = " .. (type(self.sheathedPrimary) == "table" and util.tableToString(self.sheathedPrimary) or tostring(self.sheathedPrimary)) .. "). Aborting swap.")
    if not npc.setItemSlot("primary", self.primary) then
      -- This should not happen with a correctly-defined NPC.
      sb.logWarn("swapItemSlots failure reverting npc.setItemSlot(primary = " .. (type(self.primary) == "table" and util.tableToString(self.primary) or tostring(self.primary)) .. "). Desync may have occurred.")
    elseif (not self.primary) ~= (not npc.getItemSlot("primary")) then
      -- All known cases that fail to swap to "sheathedprimary" also
      -- fail to swap back to "primary". However, in all known cases,
      -- the behavior code gracefully handles and retries the swap,
      -- which succeeds.

      --sb.logWarn("swapItemSlots unknown failure reverting npc.setItemSlot(primary = " .. (type(self.primary) == "table" and util.tableToString(self.primary) or tostring(self.primary)) .. "). Desync may have occurred.")
    end
    return false
  end
  local primary = self.primary
  self.primary = self.sheathedPrimary
  self.sheathedPrimary = primary

  if not npc.setItemSlot("alt", self.sheathedAlt) then
    -- This should not happen with a correctly-defined NPC.
    -- TODO: If it does happen, we will need to unwind the transaction
    -- to fix the "primary" state.
    sb.logWarn("swapItemSlots failure at npc.setItemSlot(alt = " .. (type(self.sheathedAlt) == "table" and util.tableToString(self.sheathedAlt) or tostring(self.sheathedAlt)) .. "). Desync may have occurred.")
  end
  if (not self.sheathedAlt) ~= (not npc.getItemSlot("alt")) then
    -- TODO: Does this ever happen? If it does, we will need to unwind
    -- the transaction to fix the "primary" state.
    sb.logWarn("swapItemSlots unknown failure at npc.setItemSlot(alt = " .. (type(self.sheathedAlt) == "table" and util.tableToString(self.sheathedAlt) or tostring(self.sheathedAlt)) .. "). Desync may have occurred.")
  end
  local alt = self.alt
  self.alt = self.sheathedAlt
  self.sheathedAlt = alt

  return true
end
