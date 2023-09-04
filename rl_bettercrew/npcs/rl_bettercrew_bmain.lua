function setNpcItemSlot(slotName, item)
  if not npc.setItemSlot(slotName, item) then return false end
  storage.itemSlots = storage.itemSlots or {}
  storage.itemSlots[string.lower(slotName)] = item

  self.primary = npc.getItemSlot("primary")
  self.alt = npc.getItemSlot("alt")

  -- In the base implementation, as of 1.4.4, `npc.setItemSlot` cannot
  -- alter "sheathedprimary" or "sheathedalt" and will return false on
  -- the attempt. This will get trapped in the first line of this modded
  -- function. Because there is no other way to change the value in the
  -- core data for either of these slots, we must rely on the instance
  -- values for them as the source of truth. Thus, we must comment out
  -- the following lines to prevent incorrect core data values from
  -- overwriting the instance values.

  --self.sheathedPrimary = npc.getItemSlot("sheathedprimary")
  --self.sheathedAlt = npc.getItemSlot("sheathedalt")
  return true
end
