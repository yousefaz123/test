-- Price math shared by the server and the ValueCheck app.
-- A "car" here is any table with guide, condition and optionally gemMult, fixCost, disclosed
-- (an owned car from OwnedCar, or a listing's hidden fields).

local Shared = script.Parent
local Economy = require(Shared.Config.Economy)

local Valuation = {}

local function roundTo(x, step)
	return math.floor(x / step + 0.5) * step
end

-- Rounds to steps that read like real prices: $10 under $1K, up to $10K steps over $1M.
function Valuation.round(x)
	local a = math.abs(x)
	local step = if a < 1000 then 10 elseif a < 10000 then 50 elseif a < 100000 then 100 elseif a < 1000000 then 1000 else 10000
	return roundTo(x, step)
end

function Valuation.mileageFactor(miles, typicalMiles)
	local m = Economy.Mileage
	local steps = (typicalMiles - miles) / m.stepMiles
	local factor = if steps >= 0 then 1 + steps * m.bonusPerStep else 1 + steps * m.penaltyPerStep
	return math.clamp(factor, m.minFactor, m.maxFactor)
end

-- ValueCheck guide: average sale price for a clean example of this model at this mileage.
function Valuation.guide(carDef, miles)
	return Valuation.round(carDef.value * Valuation.mileageFactor(miles, carDef.typicalMiles))
end

local function pctCost(cfg, guide)
	return Valuation.round(math.clamp(guide * cfg.pct, cfg.min, cfg.max))
end

function Valuation.shipping(guide)
	return pctCost(Economy.Shipping, guide)
end

function Valuation.inspectionCost(guide)
	return pctCost(Economy.Inspection, guide)
end

-- What the car really sells for right now, as it stands.
function Valuation.marketValue(car)
	return car.guide * (car.gemMult or 1) * Economy.Conditions[car.condition].saleMult
end

-- What a buyer thinks it's worth: they see dirt and wear, but not a mechanical problem unless it's disclosed.
function Valuation.buyerValue(car)
	local cond = Economy.Conditions[car.condition]
	local mult = if cond.visible or car.disclosed then cond.saleMult else 1
	return car.guide * (car.gemMult or 1) * mult
end

-- Worth once every fixable problem is fixed, minus what fixing costs.
function Valuation.fixedValue(car)
	local cond = Economy.Conditions[car.condition]
	if cond.fix == nil then
		return Valuation.marketValue(car)
	end
	return car.guide * (car.gemMult or 1) - (car.fixCost or 0)
end

return Valuation
