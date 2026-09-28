local Customers = require(FlipShared.Customers)

local function buyer(overrides)
	local b = { type = "Test", name = "Sam", budget = 100000, prefers = {}, lovesGems = false, stars = 3 }
	for k, v in overrides or {} do
		b[k] = v
	end
	return b
end

local sedan = { carId = "HanzoCivet", guide = 4200, condition = "Clean", gemMult = 1 }

test("a sticker under their max sells at the sticker", function()
	local deal = Customers.negotiate(buyer(), sedan, 3000, Random.new(1))
	expect(deal.paysSticker).toBe(true)
	local result = deal:accept()
	expect(result.result).toBe("Deal")
	expect(result.price).toBe(3000)
end)

test("a counter at or under their max closes the deal", function()
	local deal = Customers.negotiate(buyer(), sedan, 9000, Random.new(2))
	expect(deal.paysSticker).toBe(false)
	local result = deal:counter(deal.max)
	expect(result.result).toBe("Deal")
	expect(result.price).toBe(deal.max)
end)

test("offers climb toward their max and never pass it", function()
	local deal = Customers.negotiate(buyer(), sedan, 9000, Random.new(3))
	local last = deal.offer
	local result = deal:counter(deal.max + 100)
	expect(result.result).toBe("Offer")
	expect(result.price).toBeAtLeast(last)
	expect(result.price).toBeAtMost(deal.max)
end)

test("pushing too hard makes them walk", function()
	local deal = Customers.negotiate(buyer(), sedan, 9000, Random.new(4))
	local result
	for _ = 1, 3 do
		result = deal:counter(deal.max + 100)
		if result.result == "Walk" then
			break
		end
	end
	expect(result.result).toBe("Walk")
end)

test("an insulting counter burns two patience", function()
	local deal = Customers.negotiate(buyer(), sedan, 9000, Random.new(5))
	deal:counter(deal.max * 2)
	expect(deal.patience).toBe(1)
end)

test("customers skip cars they can't afford", function()
	local broke = buyer({ budget = 1000 })
	expect(Customers.negotiate(broke, sedan, 4200, Random.new(6))).toBeNil()
	expect(Customers.chooseCar(broke, { sedan }, Random.new(6))).toBeNil()
end)

test("customers lean toward the kind of car they came for", function()
	local rng = Random.new(7)
	local family = buyer({ prefers = { SUV = true } })
	local suv = { carId = "HanzoTrekker", guide = 4200, condition = "Clean", gemMult = 1 }
	local picks = 0
	for _ = 1, 2000 do
		if Customers.chooseCar(family, { sedan, suv }, rng) == 2 then
			picks += 1
		end
	end
	expect(picks / 2000).toBeNear(0.75, 0.04)
end)
