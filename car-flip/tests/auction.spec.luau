local Auction = require(FlipShared.Auction)
local Listings = require(FlipShared.Listings)
local Bots = require(FlipShared.Bots)
local Tutorial = require(FlipShared.Tutorial)
local FlipSim = require(Tests.FlipSim)

local function quietAuction(seed)
	local rng = Random.new(seed)
	local listing = Listings.generate("Online", rng, { carId = "HanzoCivet", miles = 142000 })
	return Auction.new(listing, 0, rng, { bots = { { name = "Idle", personality = "Lowballer", max = 0 } } }), listing
end

test("bid increments step up with price", function()
	expect(Auction.increment(600)).toBe(50)
	expect(Auction.increment(4200)).toBe(100)
	expect(Auction.increment(30000)).toBe(1000)
	expect(Auction.increment(2000000)).toBe(25000)
end)

test("bids under the minimum are rejected", function()
	local auction, listing = quietAuction(1)
	local ok = auction:placeBid("player", listing.startBid - 10, 1)
	expect(ok).toBe(false)
	expect((auction:placeBid("player", listing.startBid, 1))).toBe(true)
end)

test("the top bidder can't bid against themselves", function()
	local auction, listing = quietAuction(2)
	auction:placeBid("player", listing.startBid, 1)
	expect((auction:placeBid("player", auction:minNextBid(), 2))).toBe(false)
end)

test("a late bid resets the clock to 5 seconds", function()
	local auction, listing = quietAuction(3)
	local lateAt = auction.endsAt - 2
	auction:placeBid("player", listing.startBid, lateAt)
	expect(auction.endsAt).toBe(lateAt + 5)
end)

test("an auction with no bids ends with no winner", function()
	local auction = quietAuction(4)
	auction:tick(auction.endsAt + 1)
	expect(auction.ended).toBe(true)
	expect(auction.winner).toBeNil()
end)

test("bots never bid over their max", function()
	local rng = Random.new(11)
	for _ = 1, 300 do
		local listing = Listings.generate("Dealer", rng)
		local auction = Auction.new(listing, 0, rng)
		FlipSim.runAuction(auction, rng, listing.guide * 0.8)
		local maxById = {}
		for _, bot in auction.bots do
			maxById[bot.id] = bot.max
		end
		for _, bid in auction.history do
			if maxById[bid.bidder] then
				expect(bid.amount).toBeAtMost(maxById[bid.bidder])
			end
		end
	end
end)

test("tutorial: the lowballer bids twice, drops out, and the player wins", function()
	local rng = Random.new(1)
	local auction = Tutorial.firstAuction(0, rng)
	local winner, price = FlipSim.runAuction(auction, rng, 1000)
	local botBids = 0
	for _, bid in auction.history do
		if bid.bidder ~= "player" then
			botBids += 1
		end
	end
	expect(winner).toBe("player")
	expect(botBids).toBeAtMost(2)
	expect(price).toBeAtMost(750)
end)

test("dealers value a lemon far below a clean car", function()
	local rng = Random.new(21)
	local clean, lemon = 0, 0
	for _ = 1, 500 do
		local c = Listings.generate("Online", rng, { carId = "HanzoCivet", miles = 142000, condition = "Clean", gem = false })
		local m = Listings.generate("Online", rng, { carId = "HanzoCivet", miles = 142000, condition = "MajorRepair", gem = false })
		clean += Bots.maxBid("Dealer", c, rng) / c.guide
		lemon += Bots.maxBid("Dealer", m, rng) / m.guide
	end
	expect(clean / 500 - lemon / 500).toBeAtLeast(0.2)
end)
