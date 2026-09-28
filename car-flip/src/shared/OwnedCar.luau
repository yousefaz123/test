-- A car on the player's lot, from the moment an auction is won to the sale.

local Shared = script.Parent
local Economy = require(Shared.Config.Economy)

local OwnedCar = {}

function OwnedCar.fromListing(listing, price)
	local h = listing.hidden
	return {
		listingId = listing.id,
		carId = listing.carId,
		year = listing.year,
		miles = listing.miles,
		guide = listing.guide,
		condition = h.condition,
		fixCost = h.fixCost,
		problem = h.problem,
		gemLabel = if h.gem then h.gem.label else nil,
		gemMult = if h.gem then h.gem.mult else 1,
		paid = price,
		spent = price + listing.shipping, -- everything sunk into it so far
		revealed = false, -- flips to true when it comes off the truck
		disclosed = false, -- seller disclosed a mechanical problem (sell as-is)
	}
end

-- The fix this car needs, or nil (clean, or a total loss that can't be fixed).
function OwnedCar.fixNeeded(car)
	return Economy.Conditions[car.condition].fix
end

-- Pay for the fix and mark the car clean. Returns the cost.
function OwnedCar.fix(car)
	local fix = OwnedCar.fixNeeded(car)
	if fix == nil then
		return 0
	end
	local cost = car.fixCost
	car.spent += cost
	car.condition = "Clean"
	car.fixCost = 0
	car.problem = nil
	return cost
end

function OwnedCar.profit(car, salePrice)
	return salePrice - car.spent
end

return OwnedCar
