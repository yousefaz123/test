local Listings = require(FlipShared.Listings)
local Economy = require(FlipShared.Config.Economy)
local Tutorial = require(FlipShared.Tutorial)

test("the same seed makes the same listing", function()
	local a = Listings.generate("Online", Random.new(42))
	local b = Listings.generate("Online", Random.new(42))
	expect(a.carId).toBe(b.carId)
	expect(a.miles).toBe(b.miles)
	expect(a.hidden.condition).toBe(b.hidden.condition)
	expect(#a.clues).toBe(#b.clues)
end)

test("public listings hide the condition", function()
	local listing = Listings.generate("Online", Random.new(1))
	expect(Listings.public(listing).hidden).toBeNil()
	expect(listing.hidden).toBeTruthy()
end)

test("salvage has no photos and no inspection", function()
	local rng = Random.new(7)
	for _ = 1, 500 do
		local listing = Listings.generate("Salvage", rng)
		for _, clue in listing.clues do
			expect(clue.kind).toBe("note")
		end
		expect(Listings.inspect(listing)).toBeNil()
	end
end)

test("online conditions follow the doc's odds", function()
	local rng = Random.new(3)
	local counts, n = {}, 20000
	for _ = 1, n do
		local c = Listings.generate("Online", rng).hidden.condition
		counts[c] = (counts[c] or 0) + 1
	end
	for condition, weight in Economy.Tiers.Online.conditions do
		expect((counts[condition] or 0) / n).toBeNear(weight / 100, 0.015)
	end
end)

test("about 2% of online listings are gems", function()
	local rng = Random.new(5)
	local gems, n = 0, 20000
	for _ = 1, n do
		if Listings.generate("Online", rng).hidden.gem then
			gems += 1
		end
	end
	expect(gems / n).toBeNear(0.02, 0.005)
end)

test("bidding opens under the guide", function()
	local rng = Random.new(9)
	for _, tier in Economy.TierOrder do
		for _ = 1, 200 do
			local listing = Listings.generate(tier, rng)
			expect(listing.startBid < listing.guide).toBe(true)
		end
	end
end)

test("inspection reveals the problem and fix cost", function()
	local listing = Listings.generate("Online", Random.new(2), { condition = "MajorRepair" })
	local report = Listings.inspect(listing)
	expect(report.condition).toBe("MajorRepair")
	expect(report.problem).toBeTruthy()
	expect(report.fixCost).toBeAtLeast(800)
end)

test("starting cash covers the tutorial car", function()
	local auction = Tutorial.firstAuction(0, Random.new(1))
	expect(Tutorial.worstCaseCost(auction.listing)).toBeAtMost(Tutorial.StartingCash)
end)
