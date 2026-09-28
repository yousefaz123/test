-- Prints how flips play out per tier and bidding cap. Run: python3 tests/run.py sim
local FlipSim = require(Tests.FlipSim)
local Economy = require(FlipShared.Config.Economy)

local caps = {
	Online = { 0.6, 0.7, 0.8, 0.9, 1.0, 1.1 },
	Salvage = { 0.2, 0.3, 0.4, 0.5 },
	Dealer = { 0.6, 0.7, 0.8, 0.9, 1.0 },
	Classic = { 0.6, 0.7, 0.8, 0.9, 1.0 },
	Exotic = { 0.6, 0.7, 0.8, 0.9, 1.0 },
}

local function pct(x)
	return ("%5.1f%%"):format(x * 100)
end

print("tier      cap     win   profit/car   profit%   lost$   worst")
for _, tier in Economy.TierOrder do
	for _, cap in caps[tier] do
		local s = FlipSim.summarize(tier, Random.new(1234), cap, 3000)
		print(("%-8s %s  %s  %10.0f   %s  %s  %s"):format(
			tier, pct(cap), pct(s.winRate), s.avgProfit, pct(s.avgProfitPct), pct(s.lossRate), pct(s.worstPct)))
	end
end

-- Where auctions land with no player bidding: the bots' own market price.
print("\nhammer price with bots only (share of guide)")
for _, tier in Economy.TierOrder do
	local rng, total, sold = Random.new(99), 0, 0
	for _ = 1, 2000 do
		local r = FlipSim.flip(tier, rng, nil)
		if r.hammer then
			total += r.hammer / r.guide
			sold += 1
		end
	end
	print(("%-8s avg %s, %s of auctions get a bid"):format(tier, pct(total / sold), pct(sold / 2000)))
end
