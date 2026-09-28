-- Generates auction listings. A listing's `hidden` table (true condition, problem, gem) stays on
-- the server; send clients Listings.public(listing).

local Shared = script.Parent
local Cars = require(Shared.Config.Cars)
local Economy = require(Shared.Config.Economy)
local Valuation = require(Shared.Valuation)
local Util = require(Shared.Util)

local Listings = {}

local nextId = 0

local function pickCar(tierName, tier, rng)
	local tiers = tier.carTiers or { tierName }
	local weights = {}
	for _, car in Cars.List do
		if table.find(tiers, car.tier) then
			weights[car.id] = car.weight
		end
	end
	return Cars.ById[Util.pickWeighted(rng, weights)]
end

local function rollMiles(carDef, rng)
	local m = Economy.Mileage
	local roll = rng:NextNumber()
	local range = if roll < m.lowMilesChance
		then m.lowMiles
		elseif roll < m.lowMilesChance + m.highMilesChance then m.highMiles
		else m.spread
	local miles = carDef.typicalMiles * Util.between(rng, range)
	return math.max(100, math.floor(miles / 100 + 0.5) * 100)
end

-- Higher mileage reads as an older year, so the listing is believable.
local function rollYear(carDef, miles, rng)
	local first, last = carDef.years[1], carDef.years[2]
	local wear = math.clamp(miles / (carDef.typicalMiles * 2), 0, 1)
	local year = last - (last - first) * wear + rng:NextInteger(-1, 1)
	return math.clamp(math.floor(year + 0.5), first, last)
end

local function buildClues(condition, hasGem, photos, rng)
	local odds = Economy.ClueOdds
	local pools = Economy.Clues
	local clues = {}

	local function draw(pool)
		local options = {}
		for _, entry in pool do
			local usable = photos or entry.kind ~= "photo"
			local duplicate = false
			for _, existing in clues do
				if existing.text == entry.text then
					duplicate = true
				end
			end
			if usable and not duplicate then
				table.insert(options, entry)
			end
		end
		if #options > 0 then
			local entry = Util.pickOne(rng, options)
			table.insert(clues, { kind = entry.kind, text = entry.text })
		end
	end

	local mechanical = condition == "MinorRepair" or condition == "MajorRepair"
	local truth = odds.truth[condition]
	if truth and rng:NextNumber() < truth then
		draw(pools[condition])
	end
	if mechanical and rng:NextNumber() < odds.spin then
		draw(pools.Spin)
	end
	if not mechanical and condition ~= "TotalLoss" and rng:NextNumber() < odds.falseAlarm then
		draw(pools.MinorRepair)
	end
	if condition == "Clean" and photos and rng:NextNumber() < odds.shinyPhoto then
		draw(pools.Shiny)
	end
	if hasGem and rng:NextNumber() < odds.gem then
		draw(pools.Gem)
	end
	for _ = 1, rng:NextInteger(odds.neutral[1], odds.neutral[2]) do
		draw(pools.Neutral)
	end
	-- so the telling clue isn't always first
	return Util.shuffle(rng, clues)
end

-- opts (all optional): carId, miles, condition, gem (boolean), startBid, duration, clues, tutorial
function Listings.generate(tierName, rng, opts)
	opts = opts or {}
	local tier = Economy.Tiers[tierName]
	assert(tier, "Unknown auction tier " .. tostring(tierName))
	local carDef = if opts.carId then Cars.ById[opts.carId] else pickCar(tierName, tier, rng)
	assert(carDef, "Unknown car " .. tostring(opts.carId))

	local miles = opts.miles or rollMiles(carDef, rng)
	local guide = Valuation.guide(carDef, miles)
	local condition = opts.condition or Util.pickWeighted(rng, tier.conditions)
	local isGem = if opts.gem ~= nil then opts.gem else rng:NextNumber() < tier.gemChance

	local gem = nil
	if isGem then
		gem = {
			label = Util.pickOne(rng, Economy.Gem.labels),
			mult = math.floor(Util.between(rng, Economy.Gem.mult) * 20 + 0.5) / 20,
		}
	end

	local cond = Economy.Conditions[condition]
	local fixCost = 0
	if cond.fix then
		fixCost = Valuation.round(math.max(cond.fix.minCost, guide * Util.between(rng, cond.fix.costPct)))
	end
	local problems = Economy.Problems[condition]
	local problem = if problems then Util.pickOne(rng, problems) else nil

	nextId += 1
	return {
		id = "L" .. nextId,
		tier = tierName,
		carId = carDef.id,
		brand = carDef.brand,
		name = carDef.name,
		class = carDef.class,
		year = rollYear(carDef, miles, rng),
		miles = miles,
		guide = guide,
		startBid = opts.startBid or Valuation.round(guide * Util.between(rng, tier.startPct)),
		duration = opts.duration or rng:NextInteger(tier.duration[1], tier.duration[2]),
		photos = tier.photos,
		inspectable = tier.inspection,
		inspectionCost = Valuation.inspectionCost(guide),
		shipping = Valuation.shipping(guide),
		clues = opts.clues or buildClues(condition, isGem, tier.photos, rng),
		tutorial = opts.tutorial == true,
		hidden = {
			condition = condition,
			fixCost = fixCost,
			problem = problem,
			gem = gem,
		},
	}
end

-- What a client may see: everything except the hidden condition, problem and gem.
function Listings.public(listing)
	local copy = table.clone(listing)
	copy.hidden = nil
	return copy
end

-- Paid inspection: reveals the condition, the fix and any gem. Nil where the tier allows none.
function Listings.inspect(listing)
	if not listing.inspectable then
		return nil
	end
	local h = listing.hidden
	return {
		condition = h.condition,
		label = Economy.Conditions[h.condition].label,
		problem = h.problem,
		fixCost = h.fixCost,
		gem = if h.gem then h.gem.label else nil,
	}
end

-- The listing's hidden fields in the shape Valuation expects.
function Listings.trueCar(listing)
	local h = listing.hidden
	return {
		guide = listing.guide,
		condition = h.condition,
		fixCost = h.fixCost,
		gemMult = if h.gem then h.gem.mult else 1,
	}
end

return Listings
