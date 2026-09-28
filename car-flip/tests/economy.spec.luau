-- Checks the plan doc's economy claims with simulated flips.
local FlipSim = require(Tests.FlipSim)

test("bidding up to 80% of guide on online cars makes money over time, with some losses", function()
	local s = FlipSim.summarize("Online", Random.new(100), 0.8, 2000)
	expect(s.avgProfitPct).toBeAtLeast(0.05)
	expect(s.lossRate).toBeAtLeast(0.02)
	expect(s.lossRate).toBeAtMost(0.35)
	expect(s.winRate).toBeAtLeast(0.15)
	expect(s.winRate).toBeAtMost(0.9)
end)

test("chasing bids past guide earns less per car", function()
	local careful = FlipSim.summarize("Online", Random.new(200), 0.8, 2000)
	local reckless = FlipSim.summarize("Online", Random.new(200), 1.1, 2000)
	expect(reckless.avgProfitPct < careful.avgProfitPct).toBe(true)
end)

test("the salvage yard swings harder than online auctions", function()
	local online = FlipSim.summarize("Online", Random.new(300), 0.8, 2000)
	local salvage = FlipSim.summarize("Salvage", Random.new(300), 0.5, 2000)
	expect(salvage.lossRate > online.lossRate).toBe(true)
end)
