-- The scripted first flip: a cheap, dirty hatchback and one lowballer who bids twice and drops out.
-- Starting cash covers the winning bid plus shipping, and a wash makes it sellable at a profit.

local Shared = script.Parent
local Cars = require(Shared.Config.Cars)
local Economy = require(Shared.Config.Economy)
local Listings = require(Shared.Listings)
local Auction = require(Shared.Auction)

local Tutorial = {}

Tutorial.StartBid = 600
Tutorial.Duration = 45

function Tutorial.firstAuction(now, rng)
	local carDef = Cars.ById[Cars.TutorialCarId]
	local listing = Listings.generate("Online", rng, {
		carId = carDef.id,
		miles = carDef.typicalMiles,
		condition = "Dirty",
		gem = false,
		startBid = Tutorial.StartBid,
		duration = Tutorial.Duration,
		tutorial = true,
		clues = {
			{ kind = "photo", text = "Mud caked on the doors" },
			{ kind = "note", text = "Runs and drives" },
		},
	})
	-- opens, answers the player's first bid, then can't go higher
	local step = Auction.increment(listing.startBid)
	local lowballer = { name = "CheapCharlie", personality = "Lowballer", max = listing.startBid + 2 * step }
	return Auction.new(listing, now, rng, { bots = { lowballer } })
end

-- The most the tutorial can cost, so onboarding can check starting cash covers it.
function Tutorial.worstCaseCost(listing)
	local step = Auction.increment(listing.startBid)
	return listing.startBid + 3 * step + listing.shipping
end

Tutorial.StartingCash = Economy.StartingCash

return Tutorial
