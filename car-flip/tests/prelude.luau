-- Test prelude: a fake instance tree so `require(script.Parent.X)` works outside Roblox,
-- a seeded stand-in for Roblox's Random, and a tiny test framework.

-- Random: xorshift32 with the same method names as Roblox's Random.
Random = {}
Random.__index = Random

function Random.new(seed)
	local s = math.floor(seed or os.clock() * 1e6) % 4294967296
	if s == 0 then
		s = 2463534242
	end
	return setmetatable({ state = s }, Random)
end

function Random:_next()
	local x = self.state
	x = bit32.bxor(x, bit32.lshift(x, 13))
	x = bit32.bxor(x, bit32.rshift(x, 17))
	x = bit32.bxor(x, bit32.lshift(x, 5))
	self.state = x
	return x / 4294967296
end

function Random:NextNumber(min, max)
	local r = self:_next()
	if min == nil then
		return r
	end
	return min + (max - min) * r
end

function Random:NextInteger(min, max)
	return min + math.floor(self:_next() * (max - min + 1))
end

-- Fake instances
local Node = {}
Node.__index = function(self, key)
	local child = rawget(self, "__children")[key]
	if child == nil then
		error(("%s is not a valid member of %s"):format(tostring(key), rawget(self, "__path")), 2)
	end
	return child
end

local root = setmetatable({ __path = "game", __children = {}, Name = "game" }, Node)
local loaders, cache = {}, {}

local function node(path)
	local current = root
	for part in string.gmatch(path, "[^/]+") do
		local children = rawget(current, "__children")
		if children[part] == nil then
			local fullPath = rawget(current, "__path") .. "/" .. part
			children[part] = setmetatable({ __path = fullPath, __children = {}, Name = part, Parent = current }, Node)
		end
		current = children[part]
	end
	return current
end

local fakeRequire
fakeRequire = function(instance)
	local path = rawget(instance, "__path")
	if cache[path] == nil then
		local loader = loaders[path]
		assert(loader, "No module at " .. tostring(path))
		cache[path] = loader(instance, fakeRequire)
	end
	return cache[path]
end

function __module(path, loader)
	loaders["game/" .. path] = loader
	node(path)
end

-- Test framework
local tests = {}
local currentFile = "?"

function __file(name, body)
	currentFile = name
	body(fakeRequire, node("ReplicatedStorage/FlipShared"), node("Tests"))
end

function test(name, fn)
	table.insert(tests, { file = currentFile, name = name, fn = fn })
end

local function fail(message)
	error(message, 3)
end

function expect(actual)
	return {
		toBe = function(expected)
			if actual ~= expected then
				fail(("expected %s, got %s"):format(tostring(expected), tostring(actual)))
			end
		end,
		toBeNear = function(expected, tolerance)
			if math.abs(actual - expected) > tolerance then
				fail(("expected %s within %s, got %s"):format(tostring(expected), tostring(tolerance), tostring(actual)))
			end
		end,
		toBeAtLeast = function(bound)
			if not (actual >= bound) then
				fail(("expected >= %s, got %s"):format(tostring(bound), tostring(actual)))
			end
		end,
		toBeAtMost = function(bound)
			if not (actual <= bound) then
				fail(("expected <= %s, got %s"):format(tostring(bound), tostring(actual)))
			end
		end,
		toBeTruthy = function()
			if not actual then
				fail("expected a truthy value, got " .. tostring(actual))
			end
		end,
		toBeNil = function()
			if actual ~= nil then
				fail("expected nil, got " .. tostring(actual))
			end
		end,
	}
end

function __runTests()
	local passed, failed = 0, 0
	for _, t in tests do
		local ok, err = pcall(t.fn)
		if ok then
			passed += 1
		else
			failed += 1
			print(("FAIL  %s > %s\n      %s"):format(t.file, t.name, tostring(err)))
		end
	end
	print(("%d passed, %d failed"):format(passed, failed))
	if failed > 0 then
		error("tests failed", 0)
	end
end
