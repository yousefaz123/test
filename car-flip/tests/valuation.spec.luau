local Valuation = require(FlipShared.Valuation)
local Cars = require(FlipShared.Config.Cars)

test("mileage factor is 1 at typical miles", function()
	expect(Valuation.mileageFactor(142000, 142000)).toBe(1)
end)

test("10k miles over typical costs 3%", function()
	expect(Valuation.mileageFactor(152000, 142000)).toBeNear(0.97, 1e-9)
end)

test("mileage factor is clamped both ways", function()
	expect(Valuation.mileageFactor(900000, 142000)).toBe(0.5)
	expect(Valuation.mileageFactor(0, 142000)).toBe(1.25)
end)

test("the doc's example sedan guides at $4,200", function()
	expect(Valuation.guide(Cars.ById.HanzoCivet, 142000)).toBe(4200)
end)

test("prices round to readable steps", function()
	expect(Valuation.round(847)).toBe(850)
	expect(Valuation.round(4213)).toBe(4200)
	expect(Valuation.round(1234567)).toBe(1230000)
end)

test("shipping and inspection follow the doc's numbers", function()
	expect(Valuation.shipping(4200)).toBe(150)
	expect(Valuation.shipping(1000)).toBe(100)
	expect(Valuation.inspectionCost(4200)).toBe(80)
end)

test("buyers can't see an undisclosed mechanical problem", function()
	local car = { guide = 4000, condition = "MajorRepair", gemMult = 1 }
	expect(Valuation.buyerValue(car)).toBe(4000)
	car.disclosed = true
	expect(Valuation.buyerValue(car)).toBe(2200)
end)

test("buyers can see dirt", function()
	expect(Valuation.buyerValue({ guide = 4000, condition = "Dirty" })).toBeNear(3720, 1e-6)
end)

test("fixed value subtracts the repair", function()
	local car = { guide = 4200, condition = "MajorRepair", fixCost = 1400 }
	expect(Valuation.fixedValue(car)).toBe(2800)
	expect(Valuation.fixedValue({ guide = 4200, condition = "TotalLoss" })).toBeNear(840, 1e-6)
end)
