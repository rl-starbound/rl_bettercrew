function rl_bettercrew_preSwapItemSlots(args, board)
  -- Items cannot be fired while being swapped, so ensure that none are.
  self.primaryFire = false
  self.altFire = false
end

function rl_bettercrew_postSwapItemSlotsSuccess(args, board)
  -- `rangedWeaponCrowdedTicks` is a counter that allows an NPC equipped
  -- with a ranged weapon to swap to a melee weapon in case they're
  -- crowded into a situation in which they don't have room to aim and
  -- fire the ranged weapon. Without this, the NPC would be stuck
  -- holding the unusable weapon indefinitely. When swapping weapons,
  -- this counter must be reset.
  board:setNumber("rangedWeaponCrowdedTicks", 0)

  -- `meleeAttackImminent` is a flag set when the NPC is about to
  -- complete a melee attack. Its purpose is to prevent the NPC from
  -- swapping to a ranged weapon just as a melee strike is about to
  -- happen. When swapping weapons, this flag must be cleared.
  board:setBool("meleeAttackImminent", false)

  -- `weaponIsExpendable` is a flag set when the NPC is about to use a
  -- weapon that is tagged as expendable, which means it is used up upon
  -- firing. If this flag is set at the beginning of an update and the
  -- NPC's hands are empty, the implication is that they have expended
  -- the weapon. In this case, if the NPC has a script config parameter
  -- `expendableItemReplacement`, then the NPC's current primary and alt
  -- slots will be set to the contents of that variable. When swapping
  -- weapons, this flag must be cleared.
  board:setBool("weaponIsExpendable", false)

  -- The base game has a bug in which the parameters for one weapon type
  -- are not cleared immediately when the NPC swaps to another weapon
  -- type. This manifests in behavior such as an NPC running up to an
  -- enemy in order to fire a sniper rifle. By leaving the combat group,
  -- these parameters are cleared, and the NPC will rejoin the group in
  -- the next update and repopulate it with the correct values for the
  -- currently-equipped weapon.
  BGroup:leaveGroup("combat")
end

function swapItemSlots(args, board)
  if not self.rl_bettercrew_swapItemSlotsWarned then
    sb.logWarn("behavior action 'swapItemSlots' invoked; should call 'rl_bettercrew_swapItemSlots' instead")
    self.rl_bettercrew_swapItemSlotsWarned = true
  end
  return rl_bettercrew_swapItemSlots(args, board)
end

function rl_bettercrew_swapItemSlots(args, board)
  -- In the base game implementation, there are cases in which a call to
  -- `npc.setItemSlot` will fail, sometimes returning false, and
  -- sometimes returning true but incorrectly setting the item in the
  -- slot to nil. If that happens, the core and instance values will go
  -- out of sync and the NPC may become disarmed. This implementation
  -- verifies that the calls succeed before altering instance state.

  rl_bettercrew_preSwapItemSlots(args, board)

  if not npc.setItemSlot("primary", self.sheathedPrimary) then
    -- This should not happen with a correctly-defined NPC.
    sb.logWarn("swapItemSlots failure at npc.setItemSlot(primary = %s). Aborting swap.", sb.printJson(self.sheathedPrimary))
    return false
  end
  if (not self.sheathedPrimary) ~= (not npc.getItemSlot("primary")) then
    -- Edge cases exist in which `npc.setItemSlot` succeeds but then
    -- `npc.getItemSlot` returns nil. This seems to occur in relation to
    -- swapping items while lounging, but there may be other causes.

    --sb.logWarn("swapItemSlots unknown failure at npc.setItemSlot(primary = %s). Aborting swap.", sb.printJson(self.sheathedPrimary))
    if not npc.setItemSlot("primary", self.primary) then
      -- This should not happen with a correctly-defined NPC.
      sb.logWarn("swapItemSlots failure reverting npc.setItemSlot(primary = %s). Desync may have occurred.", sb.printJson(self.primary))
    elseif (not self.primary) ~= (not npc.getItemSlot("primary")) then
      -- All known cases that fail to swap to "sheathedprimary" also
      -- fail to swap back to "primary". However, in all known cases,
      -- the behavior code gracefully handles and retries the swap,
      -- which succeeds.

      --sb.logWarn("swapItemSlots unknown failure reverting npc.setItemSlot(primary = %s). Desync may have occurred.", sb.printJson(self.primary))
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
    sb.logWarn("swapItemSlots failure at npc.setItemSlot(alt = %s). Desync may have occurred.", sb.printJson(self.sheathedAlt))
  end
  if (not self.sheathedAlt) ~= (not npc.getItemSlot("alt")) then
    -- TODO: Does this ever happen? If it does, we will need to unwind
    -- the transaction to fix the "primary" state.
    sb.logWarn("swapItemSlots unknown failure at npc.setItemSlot(alt = %s). Desync may have occurred.", sb.printJson(self.sheathedAlt))
  end
  local alt = self.alt
  self.alt = self.sheathedAlt
  self.sheathedAlt = alt

  rl_bettercrew_postSwapItemSlotsSuccess(args, board)
  return true
end

function friendlyTargeting(args, board, nodeId, dt)
  if not self.rl_bettercrew_friendlyTargetingWarned then
    sb.logWarn("behavior action 'friendlyTargeting' invoked; should call 'rl_bettercrew_friendlyTargeting' instead")
    self.rl_bettercrew_friendlyTargetingWarned = true
  end
  return rl_bettercrew_friendlyTargeting(args, board, nodeId, dt)
end

-- param queryRange
-- param trackingRange
-- param losTime
-- param broadcastInterval
-- param attackOnSight
-- param hostileDamageTeam
function rl_bettercrew_friendlyTargeting(args, board, nodeId, dt)
  -- In the base game implementation, the non-existent `self.wasDamaged`
  -- was used instead of `self.damaged`, rendering guards oblivious to
  -- damage they were taking. Furthermore, guards only turned hostile if
  -- the player attacked villagers, but ignored attacks on themselves or
  -- other guards. Finally, that block of code also contained a syntax
  -- error in the `table.insert` call that caused a crash on execution.

  local targets = {}
  local outOfSight = {}
  local attackOnSight = args.attackOnSight or {}

  local targetQuery = function()
    local cooldown = board:getNumber("queryCooldown-"..nodeId) or 0
    if world.time() - cooldown > 1.0 then
      local queried = world.entityQuery(entity.position(), args.queryRange, {includedTypes = {"monster", "npc", "player"}, order = "nearest", withoutEntityId = entity.id()})
      queried = util.filter(queried, entity.entityInSight)
      board:setNumber("queryCooldown-"..nodeId, world.time())
      return queried
    end
  end

  local filterActive = function(entityId)
    if not world.entityExists(entityId) then
      return false
    end

    if world.magnitude(entity.position(), world.entityPosition(entityId)) > args.trackingRange then
      return false
    end

    if not entity.entityInSight(entityId) then
      outOfSight[entityId] = args.losTime
      return false
    end

    return true
  end

  local filterNew = function(entityId)
    if world.magnitude(entity.position(), world.entityPosition(entityId)) > args.trackingRange
       or not entity.entityInSight(entityId)
       or contains(targets, entityId) then
      return false
    end

    if not entity.isValidTarget(entityId) then
      return false
    end

    if world.isNpc(entityId) then
      if entity.damageTeam().type ~= "pvp" and entity.damageTeam().team == 1 then
        -- villagers are on damage team 1 and should not attack other villagers even if their team types are different
        return not world.isNpc(entityId, entity.damageTeam().team)
      else
        return true
      end
    end

    if entity.damageTeam().type ~= "pvp" and world.entityType(entityId) == "player" and contains(attackOnSight, entityId) then
      npc.setDamageTeam(args.hostileDamageTeam)
      table.insert(attackOnSight, entityId)
    end

    return true
  end

  local broadcastTarget = function(targetId)
    local notification = {
      sourceId = entity.id(),
      targetId = targetId,
      type = "attack"
    }
    world.entityQuery(entity.position(), args.trackingRange, { includedTypes = {"npc"}, callScript = "notify", callScriptArgs = {notification} })
  end
  local periodicBroadcast = util.interval(args.broadcastInterval, function()
    if targets[1] then
      broadcastTarget(targets[1])
    end
  end)

  while true do
    local losCount = 0
    for entityId,timer in pairs(outOfSight) do
      if entity.entityInSight(entityId) then
        table.insert(targets, entityId)
        outOfSight[entityId] = nil
      else
        timer = timer - dt
        if timer <= 0 then
          outOfSight[entityId] = nil
        else
          outOfSight[entityId] = timer
          losCount = losCount + 1
        end
      end
    end

    targets = util.filter(targets, filterActive)

    -- Get a list of potential targets from querying, notifications, and taking damage
    local newTargets = targetQuery() or {}

    local notifications = util.filter(self.notifications, function(n)
      return n.type == "attack" or n.type == "attackThief"
    end)
    for _,notification in pairs(notifications) do
      if world.isNpc(notification.sourceId, entity.damageTeam().team) and notification.targetId then
        if entity.damageTeam().type ~= "pvp" and world.entityType(notification.targetId) == "player" then
          npc.setDamageTeam(args.hostileDamageTeam)
        end
        table.insert(newTargets, notification.targetId)
      end
    end

    if self.damaged then
      local damageSource = board:getEntity("damageSource")
      local entityIsNotPvP = entity.damageTeam().type ~= "pvp"
      if entityIsNotPvP and world.isNpc(damageSource, entity.damageTeam().team) then
        -- Why this does what it does is not obvious, but it seems to
        -- mirror the effects of /behaviors/npc/flee.behavior so I
        -- suppose it's correct.
        npc.setDamageTeam(args.hostileDamageTeam)
      else
        if entityIsNotPvP and world.entityType(damageSource) == "player" then
          npc.setDamageTeam(args.hostileDamageTeam)
        end
        table.insert(newTargets, damageSource)
      end
    end

    -- Filter out invalid targets, adds out of sight targets to outOfSight
    newTargets = util.filter(newTargets, filterNew)
    if #targets == 0 and #newTargets > 0 then
      broadcastTarget(newTargets[1])
    end
    util.appendLists(targets, newTargets)

    periodicBroadcast(dt)

    if #targets == 0 and losCount == 0 then return false end
    dt = coroutine.yield(nil, {target = targets[1] or outOfSight[1], attackOnSight = attackOnSight})
    attackOnSight = args.attackOnSight or {}
  end
end

function rl_bettercrew_hasAltItem(args, board)
  -- Succeeds if the NPC has any item in their alt slot.

  return self.alt ~= nil
end

function rl_bettercrew_hasPrimaryItem(args, board)
  -- Succeeds if the NPC has any item in their primary slot.

  return self.primary ~= nil
end

local function setItemSlot(slot, item)
  if type(item) == "table" and #item > 0 then
    -- It's a list, select one randomly.
    item = util.randomChoice(item)
  end
  if type(item) == "string" then
    item = {name = item}
  end
  setNpcItemSlot(slot, item)
end

function rl_bettercrew_replaceExpendableItem(args, board)
  -- Succeeds if the NPC has an `expendableItemReplacement` script
  -- config parameter. If defined, this parameter may contain item slot
  -- definitions for the primary and alt slots. These definitions will
  -- replace whatever is currently in those slots. (A null or undefined
  -- definition will empty the slot.) The same pre and post-success
  -- hooks will be run as with the swapItemSlots function.

  local replacements = config.getParameter("expendableItemReplacement")
  if not replacements then return false end

  rl_bettercrew_preSwapItemSlots(args, board)
  setItemSlot("primary", replacements.primary)
  setItemSlot("alt", replacements.alt)
  rl_bettercrew_postSwapItemSlotsSuccess(args, board)
  return true
end
