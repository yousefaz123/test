-- Bot bidders. Each has a personality from Economy.Bots and a private max bid.

local Shared = script.Parent
local Economy = require(Shared.Config.Economy)
local Valuation = require(Shared.Valuation)
local Listings = require(Shared.Listings)
local Util = require(Shared.Util)

local Bots = {}

-- The most this bot will pay. Dealers price off the hidden condition (net of fixing and shipping),
-- so they bail early on a lemon and chase a gem; everyone else prices off the guide.
function Bots.maxBid(personality, listing, rng)
	local cfg = Economy.Bots[personality]
	local tier = Economy.Tiers[listing.tier]
	local pct = Util.between(rng, cfg.valuePct)
	if cfg.heatChance and rng:NextNumber() < cfg.heatChance then
		pct = Util.between(rng, cfg.heatPct)
	end
	local base
	if cfg.knowsCondition then
		base = Valuation.fixedValue(Listings.trueCar(listing)) - listing.shipping
	else
		base = listing.guide * tier.botValueScale
	end
	return math.max(0, math.floor(base * pct))
end

-- Which bots show up to this listing's auction.
function Bots.pick(tierName, rng)
	local cfg = Economy.Tiers[tierName].bots
	local picked, used = {}, {}
	for i = 1, rng:NextInteger(cfg.count[1], cfg.count[2]) do
		local personality = Util.pickWeighted(rng, cfg.weights)
		local name = Util.pickOne(rng, Economy.BotNames[personality])
		if used[name] then
			name = name .. " " .. i
		end
		used[name] = true
		table.insert(picked, { name = name, personality = personality })
	end
	return picked
end

return Bots
