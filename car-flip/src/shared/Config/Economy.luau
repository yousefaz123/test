-- Every tunable number in the flip loop. Starting values from the plan doc; tune in playtests.
-- Percentages are fractions of the car's ValueCheck guide price unless noted.

local Economy = {}

Economy.StartingCash = 1000

Economy.Mileage = {
	stepMiles = 10000, -- the guide moves one step per 10k miles away from typical
	penaltyPerStep = 0.03, -- over typical: -3% per step
	bonusPerStep = 0.03, -- under typical: +3% per step
	minFactor = 0.5,
	maxFactor = 1.25, -- low-mile examples top out at +25%
	spread = { 0.6, 1.4 }, -- most listings land at typical x this
	lowMilesChance = 0.08,
	lowMiles = { 0.2, 0.5 },
	highMilesChance = 0.10,
	highMiles = { 1.5, 2.1 },
}

-- saleMult: what the car sells for unfixed, as a share of guide.
-- visible: buyers can see it without being told (dirt, wear). Mechanical problems are hidden unless disclosed.
-- returnChance: odds a buyer brings back a car sold with this problem undisclosed (reputation, build step 4).
Economy.Conditions = {
	Clean = { label = "Clean", saleMult = 1.0, visible = true },
	Dirty = {
		label = "Needs a wash",
		saleMult = 0.93,
		visible = true,
		fix = { kind = "Wash", costPct = { 0, 0 }, minCost = 0, seconds = 5 },
	},
	Worn = {
		label = "Needs detailing",
		saleMult = 0.86,
		visible = true,
		fix = { kind = "Detail", costPct = { 0.03, 0.05 }, minCost = 150, seconds = 20 },
	},
	MinorRepair = {
		label = "Minor mechanical problem",
		saleMult = 0.75,
		visible = false,
		returnChance = 0.35,
		fix = { kind = "Repair", costPct = { 0.08, 0.14 }, minCost = 250, seconds = 30 },
	},
	MajorRepair = {
		label = "Major mechanical problem",
		saleMult = 0.55,
		visible = false,
		returnChance = 0.7,
		fix = { kind = "Repair", costPct = { 0.28, 0.40 }, minCost = 800, seconds = 60 },
	},
	TotalLoss = { label = "Total loss, parts only", saleMult = 0.2, visible = true },
}

Economy.Problems = {
	MinorRepair = {
		"Worn brake pads",
		"Dead battery",
		"Bad oxygen sensor",
		"Leaking valve cover gasket",
		"Broken AC blower",
		"Noisy wheel bearing",
	},
	MajorRepair = {
		"Slipping transmission",
		"Blown head gasket",
		"Rod knock",
		"Cracked radiator, overheating",
		"Failed turbo",
		"Bent frame rail",
	},
	TotalLoss = { "Flood damage", "Frame bent beyond repair", "Engine fire" },
}

-- Listing clues. kind = "photo" only appears where the tier has photos.
Economy.Clues = {
	Dirty = {
		{ kind = "photo", text = "Mud caked on the doors" },
		{ kind = "note", text = "Sat outside all winter" },
		{ kind = "photo", text = "Bird droppings all over the hood" },
	},
	Worn = {
		{ kind = "photo", text = "Faded, peeling paint" },
		{ kind = "note", text = "Previous owner smoked in it" },
		{ kind = "photo", text = "Torn driver's seat" },
		{ kind = "photo", text = "Curb rash on every wheel" },
	},
	MinorRepair = {
		{ kind = "note", text = "Check engine light is on" },
		{ kind = "note", text = "Brakes squeak a little" },
		{ kind = "note", text = "Needs a jump sometimes" },
		{ kind = "photo", text = "Oil spot under the engine" },
	},
	MajorRepair = {
		{ kind = "note", text = "Runs rough" },
		{ kind = "note", text = "Shifts hard between gears" },
		{ kind = "photo", text = "Blue smoke on startup" },
		{ kind = "note", text = "Overheats in traffic" },
		{ kind = "note", text = "Sold as-is, no returns" },
	},
	TotalLoss = {
		{ kind = "note", text = "Does not start" },
		{ kind = "note", text = "Towed in, no keys" },
		{ kind = "photo", text = "Water line on the seats" },
	},
	-- Sellers covering for a mechanical problem
	Spin = {
		{ kind = "note", text = "Just needs a little TLC" },
		{ kind = "note", text = "Easy fix, I just don't have time" },
		{ kind = "note", text = "Was running when parked" },
	},
	Neutral = {
		{ kind = "note", text = "Clean title" },
		{ kind = "note", text = "Runs and drives" },
		{ kind = "note", text = "Recent oil change" },
		{ kind = "note", text = "Two keys" },
		{ kind = "note", text = "Priced to sell" },
		{ kind = "note", text = "Serious buyers only" },
	},
	Shiny = {
		{ kind = "photo", text = "Fresh wash, shiny paint" },
		{ kind = "photo", text = "Spotless interior" },
	},
	Gem = {
		{ kind = "note", text = "Original owner, garage kept" },
		{ kind = "note", text = "Rare factory option" },
		{ kind = "note", text = "Numbers-matching engine" },
		{ kind = "note", text = "Only a few made in this color" },
	},
}

Economy.ClueOdds = {
	-- chance the listing shows a true clue for its condition
	truth = { Dirty = 0.8, Worn = 0.7, MinorRepair = 0.55, MajorRepair = 0.65, TotalLoss = 0.9 },
	spin = 0.35, -- a mechanical car also gets a seller-spin line
	falseAlarm = 0.08, -- a car with no mechanical problem shows a harmless mechanical-sounding note
	shinyPhoto = 0.5, -- a clean car shows it off
	gem = 0.6, -- a gem shows its clue
	neutral = { 1, 2 },
}

Economy.Gem = {
	mult = { 2.0, 3.0 },
	labels = { "Rare trim", "Collector spec", "Barn find", "Low-production color" },
}

-- Auction tiers. conditions = weights; bots.weights = how often each personality shows up.
-- botValueScale: non-Dealer bots value salvage cars at guide x this.
Economy.Tiers = {
	Online = {
		label = "Online auctions",
		unlock = nil,
		conditions = { Clean = 40, Dirty = 25, Worn = 10, MinorRepair = 20, MajorRepair = 5 },
		gemChance = 0.02,
		photos = true,
		inspection = true,
		startPct = { 0.30, 0.45 },
		duration = { 60, 90 },
		bots = { count = { 2, 3 }, weights = { Lowballer = 2, Dealer = 3, Hothead = 2, Sniper = 3 } },
		botValueScale = 1,
	},
	Salvage = {
		label = "Salvage yard",
		unlock = { earned = 25000 },
		carTiers = { "Online", "Dealer" },
		conditions = { Clean = 5, Dirty = 10, Worn = 15, MinorRepair = 25, MajorRepair = 35, TotalLoss = 10 },
		gemChance = 0.05,
		photos = false,
		inspection = false, -- the salvage yard is the gamble
		startPct = { 0.10, 0.18 },
		duration = { 45, 75 },
		bots = { count = { 1, 3 }, weights = { Lowballer = 3, Dealer = 4, Hothead = 3, Sniper = 2 } },
		botValueScale = 0.7,
	},
	Dealer = {
		label = "Dealer auctions",
		unlock = { lot = "UsedLot", stars = 3 },
		conditions = { Clean = 35, Dirty = 25, Worn = 15, MinorRepair = 18, MajorRepair = 7 },
		gemChance = 0.02,
		photos = true,
		inspection = true,
		startPct = { 0.35, 0.50 },
		duration = { 75, 105 },
		bots = { count = { 2, 3 }, weights = { Lowballer = 2, Dealer = 4, Hothead = 2, Sniper = 3 } },
		botValueScale = 1,
	},
	Classic = {
		label = "Classic & collector",
		unlock = { lot = "Dealership", stars = 4 },
		conditions = { Clean = 20, Dirty = 20, Worn = 25, MinorRepair = 25, MajorRepair = 10 },
		gemChance = 0.04,
		photos = true,
		inspection = true,
		startPct = { 0.35, 0.50 },
		duration = { 90, 120 },
		bots = { count = { 2, 3 }, weights = { Lowballer = 1, Dealer = 4, Hothead = 3, Sniper = 3 } },
		botValueScale = 1,
	},
	Exotic = {
		label = "Exotic",
		unlock = { lot = "Showroom", stars = 4.5 },
		conditions = { Clean = 45, Dirty = 25, Worn = 10, MinorRepair = 15, MajorRepair = 5 },
		gemChance = 0.02,
		photos = true,
		inspection = true,
		startPct = { 0.40, 0.55 },
		duration = { 90, 120 },
		bots = { count = { 2, 4 }, weights = { Lowballer = 1, Dealer = 4, Hothead = 3, Sniper = 4 } },
		botValueScale = 1,
	},
}
Economy.TierOrder = { "Online", "Salvage", "Dealer", "Classic", "Exotic" }

Economy.Shipping = { pct = 0.035, min = 100, max = 5000 }
Economy.Inspection = { pct = 0.02, min = 50, max = 10000 }

Economy.BidIncrements = {
	{ below = 1000, step = 50 },
	{ below = 5000, step = 100 },
	{ below = 25000, step = 250 },
	{ below = 100000, step = 1000 },
	{ below = 500000, step = 5000 },
	{ below = math.huge, step = 25000 },
}

Economy.Auction = {
	snipeWindow = 5, -- a bid with less than this many seconds left...
	extendTo = 5, -- ...resets the clock to this many seconds
}

-- Bot personalities. valuePct = share of value they'll pay; opening = delay before a first bid;
-- reaction = delay before answering someone else's bid; jump = bid increments per bid.
Economy.Bots = {
	Lowballer = {
		valuePct = { 0.50, 0.70 },
		opening = { 1, 4 },
		reaction = { 2, 5 },
		jump = { 1, 1 },
	},
	Dealer = {
		valuePct = { 0.78, 0.90 },
		knowsCondition = true, -- prices off the hidden condition, so an early Dealer exit is a warning
		opening = { 3, 10 },
		reaction = { 1.5, 4 },
		jump = { 1, 2 },
	},
	Hothead = {
		valuePct = { 0.60, 0.95 },
		heatChance = 0.35, -- sometimes gets emotional and bids past guide
		heatPct = { 1.00, 1.25 },
		opening = { 2, 8 },
		reaction = { 0.5, 1.5 },
		jump = { 1, 4 },
	},
	Sniper = {
		valuePct = { 0.72, 0.92 },
		lastSeconds = 4, -- only bids in the final seconds
		reaction = { 0.3, 1.2 },
		jump = { 1, 2 },
	},
}

Economy.BotNames = {
	Lowballer = { "CheapCharlie", "LowballLarry", "BargainBev", "PennyPete" },
	Dealer = { "Ridgeway Motors", "Sal's Auto Sales", "Northside Imports", "Premier Pre-Owned" },
	Hothead = { "TurboTony", "RevLimiterRay", "BigBidBrenda", "FullSendFrank" },
	Sniper = { "LastSecondLou", "QuietQuinn", "ClockWatcherKai", "ZeroHourZoe" },
}

Economy.Customers = {
	Types = {
		Student = { weight = 5, budget = { 1500, 6000 }, prefers = { Hatchback = true, Sedan = true, Sports = true } },
		Commuter = { weight = 5, budget = { 3000, 20000 }, prefers = { Sedan = true, Hatchback = true, Wagon = true } },
		Family = { weight = 4, budget = { 4000, 40000 }, prefers = { SUV = true, Minivan = true, Wagon = true } },
		Contractor = { weight = 3, budget = { 5000, 45000 }, prefers = { Pickup = true, SUV = true } },
		Executive = { weight = 2, budget = { 15000, 250000 }, prefers = { Luxury = true, Sedan = true, Exotic = true } },
		Enthusiast = { weight = 3, budget = { 8000, 400000 }, prefers = { Sports = true, Muscle = true, Classic = true } },
		Collector = { weight = 1, budget = { 30000, 3500000 }, prefers = { Classic = true, Exotic = true }, lovesGems = true },
	},
	willingness = { 0.95, 1.12 }, -- most they'll pay, as a share of what they think it's worth
	preferredBonus = 1.05, -- the kind of car they came for
	gemBonus = 1.10, -- collectors on a gem
	minBudgetRatio = 0.8, -- they won't look at a car worth more than budget / this
	firstOffer = { 0.82, 0.92 }, -- opening offer, as a share of their max
	patience = 3, -- counteroffers before they walk
	insultRatio = 1.25, -- a counter this far over their max costs 2 patience
	stepToward = { 0.4, 0.6 }, -- each raise closes this share of the gap to their max
	Reputation = { perStar = 0.03, neutralStars = 3 },
}

return Economy
