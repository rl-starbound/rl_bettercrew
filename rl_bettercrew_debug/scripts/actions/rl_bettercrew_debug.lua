-- Logs a position, along with its given context.
--
-- param level
-- param context
-- param position
function rl_bettercrew_logPosition(args, board)
  local logFunc
  if args.level == "error" then
    logFunc = sb.logError
  elseif args.level == "warn" then
    logFunc = sb.logWarn
  elseif args.level == "info" then
    logFunc = sb.logInfo
  else
    return false
  end

  if not (args.context and args.position) then return false end

  logFunc("%s: %s", args.context, sb.printJson(args.position))
  return true
end
