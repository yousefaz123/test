-- Plays whole flips with a simple player strategy, for tests and the economy report.

local FlipShared = script.Parent.Parent.ReplicatedStorage.FlipShared
local Listings = require(FlipShared.Listings)
local Auction = require(FlipShared.Auction)
local OwnedCar = require(FlipShared.OwnedCar)
local Customers = require(FlipShared.Customers)

local FlipSim = {}

-- Runs an auction to the end. The player answers every outbid with the minimum bid, up to cap
-- (nil = the player sits out). Returns winner, price.
function FlipSim.runAuction(auction, rng, cap)
	local now = auction.startedAt
	local nextPlayerAt = now + rng:NextNumber(0.5, 2)
	while not auction.ended do
		auction:tick(now)
		if not auction.ended and cap and auction.leader ~= "player" and now >= nextPlayerAt then
			local need = auction:minNextBid()
			if need <= cap then
				auction:placeBid("player", need, now)
			end
			nextPlayerAt = now + rng:NextNumber(0.5, 2)
		end
		now += 0.25
		assert(now < auction.startedAt + 3600, "auction never ended")
	end
	return auction.winner, auction.price
end

-- One flip: bid up to capPct of guide, fix whatever's fixable, sell to a buyer who wants the car,
-- haggling to 90-100% of their max.
function FlipSim.flip(tierName, rng, capPct)
	local listing = Listings.generate(tierName, rng)
	local auction = Auction.new(listing, 0, rng)
	local winner, price = FlipSim.runAuction(auction, rng, if capPct then listing.guide * capPct else nil)
	local result = { won = winner == "player", hammer = price, guide = listing.guide, listing = listing }
	if not result.won then
		return result
	end
	local car = OwnedCar.fromListing(listing, price)
	OwnedCar.fix(car)
	local buyer = { type = "Sim", budget = math.huge, prefers = {}, lovesGems = false, stars = 3 }
	local sale = math.floor(Customers.maxPrice(buyer, car, rng) * rng:NextNumber(0.9, 1.0))
	result.sale = sale
	result.profit = OwnedCar.profit(car, sale)
	return result
end

-- Many flips summarized: win rate, average profit per win, share of wins that lost money.
function FlipSim.summarize(tierName, rng, capPct, count)
	local wins, losses, profit, profitPct, worst = 0, 0, 0, 0, 0
	for _ = 1, count do
		local r = FlipSim.flip(tierName, rng, capPct)
		if r.won then
			wins += 1
			profit += r.profit
			profitPct += r.profit / r.guide
			worst = math.min(worst, r.profit / r.guide)
			if r.profit < 0 then
				losses += 1
			end
		end
	end
	return {
		winRate = wins / count,
		avgProfit = if wins > 0 then profit / wins else 0,
		avgProfitPct = if wins > 0 then profitPct / wins else 0,
		lossRate = if wins > 0 then losses / wins else 0,
		worstPct = worst,
		wins = wins,
	}
end

return FlipSim
