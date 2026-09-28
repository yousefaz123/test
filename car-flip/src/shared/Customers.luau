-- Walk-in customers and the haggle. Each customer has a hidden max price per car; the player's
-- skill is countering just under it without running out their patience.

local Shared = script.Parent
local Cars = require(Shared.Config.Cars)
local Economy = require(Shared.Config.Economy)
local Valuation = require(Shared.Valuation)
local Util = require(Shared.Util)

local Customers = {}

local Negotiation = {}
Negotiation.__index = Negotiation

local FIRST_NAMES = {
	"Maya", "Jordan", "Luis", "Priya", "Dev", "Sam", "Aisha", "Tom",
	"Keiko", "Marco", "Grace", "Omar", "Nina", "Ben", "Zoe", "Carlos",
}

-- stars = the lot's reputation, 1 to 5.
function Customers.spawn(rng, stars)
	local cfg = Economy.Customers
	local weights = {}
	for typeName, t in cfg.Types do
		weights[typeName] = t.weight
	end
	local typeName = Util.pickWeighted(rng, weights)
	local t = cfg.Types[typeName]
	return {
		type = typeName,
		name = Util.pickOne(rng, FIRST_NAMES),
		budget = Valuation.round(Util.logBetween(rng, t.budget)),
		prefers = t.prefers,
		lovesGems = t.lovesGems == true,
		stars = stars or cfg.Reputation.neutralStars,
	}
end

local function affordable(customer, car)
	return Valuation.buyerValue(car) * Economy.Customers.minBudgetRatio <= customer.budget
end

-- The most this customer would pay for this car, or nil if it's out of their league.
function Customers.maxPrice(customer, car, rng)
	local cfg = Economy.Customers
	if not affordable(customer, car) then
		return nil
	end
	local mult = Util.between(rng, cfg.willingness)
	if customer.prefers[Cars.ById[car.carId].class] then
		mult *= cfg.preferredBonus
	end
	if customer.lovesGems and car.gemMult > 1 then
		mult *= cfg.gemBonus
	end
	mult *= 1 + cfg.Reputation.perStar * (customer.stars - cfg.Reputation.neutralStars)
	local max = math.min(Valuation.buyerValue(car) * mult, customer.budget)
	return math.floor(max)
end

-- Which car on the lot this customer walks up to (its index), or nil if nothing fits.
function Customers.chooseCar(customer, cars, rng)
	local weights = {}
	for i, car in cars do
		if affordable(customer, car) then
			local weight = 1
			if customer.prefers[Cars.ById[car.carId].class] then
				weight *= 3
			end
			if customer.lovesGems and car.gemMult > 1 then
				weight *= 2
			end
			weights[i] = weight
		end
	end
	if next(weights) == nil then
		return nil
	end
	return Util.pickWeighted(rng, weights)
end

-- Start haggling over a car with a sticker price. Nil if they can't afford it.
-- If the sticker is at or under their max they simply pay it (session.paysSticker).
function Customers.negotiate(customer, car, askingPrice, rng)
	local cfg = Economy.Customers
	local max = Customers.maxPrice(customer, car, rng)
	if max == nil then
		return nil
	end
	local self = setmetatable({
		customer = customer,
		car = car,
		max = max,
		patience = cfg.patience,
		rng = rng,
		done = false,
		final = false,
		paysSticker = askingPrice <= max,
	}, Negotiation)
	self.offer = if self.paysSticker
		then askingPrice
		else math.min(Valuation.round(max * Util.between(rng, cfg.firstOffer)), max)
	return self
end

function Negotiation:accept()
	if self.done then
		return { result = "Closed" }
	end
	self.done = true
	return { result = "Deal", price = self.offer }
end

-- Counter with a price. Returns Deal (at your price), Offer (they come up) or Walk.
function Negotiation:counter(amount)
	if self.done then
		return { result = "Closed" }
	end
	local cfg = Economy.Customers
	if amount <= self.max then
		self.done = true
		return { result = "Deal", price = amount }
	end
	self.patience -= if amount > self.max * cfg.insultRatio then 2 else 1
	if self.patience <= 0 or self.final then
		self.done = true
		return { result = "Walk" }
	end
	local raised = self.offer + (self.max - self.offer) * Util.between(self.rng, cfg.stepToward)
	self.offer = math.clamp(Valuation.round(raised), self.offer, self.max)
	self.final = self.patience == 1 -- they say it's their last offer
	return { result = "Offer", price = self.offer, final = self.final }
end

return Customers
