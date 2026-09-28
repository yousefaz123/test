-- Small random helpers. Every function takes a Roblox Random so a seed replays exactly.

local Util = {}

function Util.between(rng, range)
	return rng:NextNumber(range[1], range[2])
end

-- Log-uniform pick, for wide ranges like budgets, so $5K and $500K buyers both show up.
function Util.logBetween(rng, range)
	return math.exp(rng:NextNumber(math.log(range[1]), math.log(range[2])))
end

function Util.pickOne(rng, list)
	return list[rng:NextInteger(1, #list)]
end

-- weights = { key = weight }. Keys are sorted first so a seeded rng always gives the same pick.
function Util.pickWeighted(rng, weights)
	local keys, total = {}, 0
	for key, weight in weights do
		if weight > 0 then
			table.insert(keys, key)
			total += weight
		end
	end
	assert(total > 0, "pickWeighted needs at least one positive weight")
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	local roll = rng:NextNumber() * total
	for _, key in keys do
		roll -= weights[key]
		if roll < 0 then
			return key
		end
	end
	return keys[#keys]
end

function Util.shuffle(rng, list)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

return Util
