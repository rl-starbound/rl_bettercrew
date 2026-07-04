-- param dialogMode
-- param dialogType
-- param dialog
-- param entity
-- param tags
function rl_bettercrew_sayToEntityIfExists(args, board)
  -- Duplicates the base game `satToEntity` function, except instead of
  -- crashing if the specified dialog does not exist, it returns true.
  -- Useful if you add a new category of dialog and don't want to crash
  -- NPCs from other mods that don't have that dialog category. Also,
  -- allows overriding dialogMode on a case by case basis.

  local dialog = args.dialog and speciesDialog(args.dialog, args.entity) or queryDialog(args.dialogType, args.entity);
  local dialogMode = args.dialogMode or config.getParameter("dialogMode", "static")

  if dialog == nil then
    return true
  end

  if dialogMode == "static" then
    dialog = staticRandomizeDialog(dialog)
  elseif dialogMode == "sequence" then
    dialog = sequenceDialog(dialog, args.dialogType)
  else
    dialog = randomizeDialog(dialog)
  end
  if dialog == nil then return true end

  local tags = sb.jsonMerge(self.dialogTags or {}, args.tags)
  tags.selfname = world.entityName(entity.id())
  if args.entity then
    tags.entityname = world.entityName(args.entity)

    local entityType = world.entityType(args.entity)
    if entityType and entityType == "npc" then
      tags.entitySpecies = world.entitySpecies(args.entity)
    end
  end

  local options = {}

  -- Only NPCs have sound support
  if entity.entityType() == "npc" then
    options.sound = randomChatSound()
  end

  context().say(dialog, tags, options)
  return true
end
