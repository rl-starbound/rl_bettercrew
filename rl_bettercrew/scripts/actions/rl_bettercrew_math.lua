-- param name
-- output number
function rl_bettercrew_incrementCounter(args, board)
  if args.name == nil then return false end
  local counter = (board:getNumber(args.name) or 0) + 1
  board:setNumber(args.name, counter)
  return true, {number = counter}
end

-- param name
function rl_bettercrew_resetCounter(args, board)
  if args.name == nil then return false end
  board:setNumber(args.name, 0)
  return true
end

-- param first
-- param second
-- output number
function rl_bettercrew_max(args)
  if args.first == nil or args.second == nil then return false end
  return true, {result = math.max(args.first, args.second)}
end

-- param first
-- param second
-- output number
function rl_bettercrew_min(args)
  if args.first == nil or args.second == nil then return false end
  return true, {result = math.min(args.first, args.second)}
end

