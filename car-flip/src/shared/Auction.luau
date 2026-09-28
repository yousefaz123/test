-- One live auction: the player and bots bidding on a listing. Pure logic with an explicit clock,
-- so the server calls tick(now) every step and the same code runs in tests.
--
-- The server is responsible for checking a player can afford a bid before calling placeBid.

local Shared = script.Parent
local Economy = require(Shared.Config.Economy)
local Listings = require(Shared.Listings)
local Bots = require(Shared.Bots)
local Util = require(Shared.Util)

local Auction = {}
Auction.__index = Auction

function Auction.increment(price)
	for _, row in Economy.BidIncrements do
		if price < row.below then
			return row.step
		end
	end
	return Economy.BidIncrements[#Economy.BidIncrements].step
end

-- opts.bots: list of { name, personality, max? } to use instead of a random pick (max overrides the rolled one).
function Auction.new(listing, now, rng, opts)
	opts = opts or {}
	local self = setmetatable({
		listing = listing,
		rng = rng,
		startedAt = now,
		endsAt = now + listing.duration,
		currentBid = nil,
		leader = nil,
		ended = false,
		winner = nil,
		price = nil,
		history = {},
		bots = {},
	}, Auction)
	for _, pick in opts.bots or Bots.pick(listing.tier, rng) do
		local cfg = Economy.Bots[pick.personality]
		table.insert(self.bots, {
			id = "bot:" .. pick.name,
			name = pick.name,
			personality = pick.personality,
			max = pick.max or Bots.maxBid(pick.personality, listing, rng),
			nextActionAt = now + Util.between(rng, cfg.opening or cfg.reaction),
			out = false,
			hasBid = false,
		})
	end
	return self
end

function Auction:minNextBid()
	if self.currentBid == nil then
		return self.listing.startBid
	end
	return self.currentBid + Auction.increment(self.currentBid)
end

function Auction:timeLeft(now)
	return math.max(0, self.endsAt - now)
end

local function record(self, bidderId, amount, now, events)
	self.currentBid = amount
	self.leader = bidderId
	table.insert(self.history, { bidder = bidderId, amount = amount, at = now })
	table.insert(events, { type = "Bid", bidder = bidderId, amount = amount })

	local rules = Economy.Auction
	if self.endsAt - now < rules.snipeWindow then
		self.endsAt = now + rules.extendTo
		table.insert(events, { type = "Extended", endsAt = self.endsAt })
	end

	-- everyone else takes a moment to react
	for _, bot in self.bots do
		if bot.id ~= bidderId then
			bot.nextActionAt = now + Util.between(self.rng, Economy.Bots[bot.personality].reaction)
		end
	end
end

-- A player bid. Returns true, events or false, reason.
function Auction:placeBid(bidderId, amount, now)
	if self.ended or now >= self.endsAt then
		return false, "This auction has ended"
	end
	if self.leader == bidderId then
		return false, "You're already the top bidder"
	end
	local need = self:minNextBid()
	if amount < need then
		return false, ("The minimum bid is $%d"):format(need)
	end
	local events = {}
	record(self, bidderId, amount, now, events)
	return true, events
end

local function botAct(self, bot, now, events)
	local cfg = Economy.Bots[bot.personality]
	local need = self:minNextBid()
	if need > bot.max then
		bot.out = true
		table.insert(events, { type = "Dropped", bidder = bot.id, name = bot.name, hadBid = bot.hasBid })
	elseif cfg.lastSeconds and self.endsAt - now > cfg.lastSeconds then
		bot.nextActionAt = self.endsAt - cfg.lastSeconds + Util.between(self.rng, cfg.reaction)
	else
		local amount = need
		for _ = 2, self.rng:NextInteger(cfg.jump[1], cfg.jump[2]) do
			local raised = amount + Auction.increment(amount)
			if raised > bot.max then
				break
			end
			amount = raised
		end
		bot.hasBid = true
		record(self, bot.id, amount, now, events)
	end
end

-- Advance bots and the clock. Returns what happened, for the UI.
function Auction:tick(now)
	local events = {}
	if self.ended then
		return events
	end
	-- one bot at a time, earliest first, so two bots never bid in the same instant
	for _ = 1, 32 do
		if now >= self.endsAt then
			break
		end
		local actor = nil
		for _, bot in self.bots do
			local due = not bot.out and self.leader ~= bot.id and bot.nextActionAt <= now
			if due and (actor == nil or bot.nextActionAt < actor.nextActionAt) then
				actor = bot
			end
		end
		if actor == nil then
			break
		end
		botAct(self, actor, now, events)
	end
	if now >= self.endsAt then
		self.ended = true
		self.winner = self.leader
		self.price = self.currentBid
		table.insert(events, { type = "Ended", winner = self.winner, price = self.price })
	end
	return events
end

-- Everything a client may see about this auction.
function Auction:snapshot(now)
	local bidders = {}
	for _, bot in self.bots do
		table.insert(bidders, { id = bot.id, name = bot.name, personality = bot.personality, out = bot.out })
	end
	return {
		listing = Listings.public(self.listing),
		currentBid = self.currentBid,
		leader = self.leader,
		minNextBid = self:minNextBid(),
		endsAt = self.endsAt,
		timeLeft = self:timeLeft(now),
		ended = self.ended,
		bidders = bidders,
		history = self.history,
	}
end

return Auction
