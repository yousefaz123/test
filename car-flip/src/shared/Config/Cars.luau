-- Car catalog. Shapes can read as real-world cars, but every brand and model name is
-- fictional and models carry no real names, logos, badges or exact grilles (plan doc, IP lines).
--
-- value        ValueCheck guide price for a clean car at typicalMiles
-- typicalMiles mileage the guide assumes; listings roll around it
-- tier         which auction tier lists it (the salvage yard draws from several)
-- weight       how often it shows up within its tier
-- look         what the 3D model should read as, for picking models later

local Cars = {}

Cars.Brands = {
	Hanzo = { origin = "Japan", vibe = "Reliable everyday cars" },
	Kazuma = { origin = "Japan", vibe = "Tuner and sports cars" },
	Brandt = { origin = "Germany", vibe = "Luxury and fast hatchbacks" },
	Mesa = { origin = "USA", vibe = "Trucks, vans and muscle" },
	Norrland = { origin = "Sweden", vibe = "Boxy, safe wagons" },
	Vireo = { origin = "Italy", vibe = "Exotics" },
}

Cars.Classes = {
	"Hatchback",
	"Sedan",
	"Wagon",
	"Minivan",
	"SUV",
	"Pickup",
	"Sports",
	"Muscle",
	"Luxury",
	"Classic",
	"Exotic",
}

Cars.List = {
	-- Online auctions: commons, $800 to $8K
	{ id = "KazumaMinnow", brand = "Kazuma", name = "Minnow", class = "Hatchback", tier = "Online", years = { 1998, 2006 }, value = 1500, typicalMiles = 190000, weight = 10, look = "Tiny '00s budget hatchback" },
	{ id = "HanzoPip", brand = "Hanzo", name = "Pip", class = "Hatchback", tier = "Online", years = { 2004, 2012 }, value = 2600, typicalMiles = 150000, weight = 10, look = "Tall Japanese city hatchback" },
	{ id = "HanzoCivet", brand = "Hanzo", name = "Civet", class = "Sedan", tier = "Online", years = { 2004, 2011 }, value = 4200, typicalMiles = 142000, weight = 12, look = "'00s Japanese compact sedan" },
	{ id = "MesaHomestead", brand = "Mesa", name = "Homestead", class = "Minivan", tier = "Online", years = { 2003, 2010 }, value = 2900, typicalMiles = 175000, weight = 8, look = "American family minivan" },
	{ id = "NorrlandBrick", brand = "Norrland", name = "Brick", class = "Wagon", tier = "Online", years = { 1988, 1995 }, value = 3200, typicalMiles = 210000, weight = 6, look = "Boxy '80s Swedish wagon" },
	{ id = "BrandtR3", brand = "Brandt", name = "R3", class = "Sedan", tier = "Online", years = { 2002, 2008 }, value = 5200, typicalMiles = 160000, weight = 7, look = "'00s German sport sedan" },
	{ id = "MesaPioneer", brand = "Mesa", name = "Pioneer", class = "Pickup", tier = "Online", years = { 2001, 2009 }, value = 6500, typicalMiles = 185000, weight = 8, look = "'00s full-size American pickup" },
	{ id = "HanzoTrekker", brand = "Hanzo", name = "Trekker", class = "SUV", tier = "Online", years = { 2006, 2013 }, value = 7500, typicalMiles = 145000, weight = 7, look = "Japanese compact crossover" },

	-- Dealer auctions: $5K to $40K
	{ id = "KazumaKaze", brand = "Kazuma", name = "Kaze", class = "Sports", tier = "Dealer", years = { 1994, 2004 }, value = 12000, typicalMiles = 110000, weight = 8, look = "Small Japanese roadster" },
	{ id = "KazumaSlide", brand = "Kazuma", name = "Slide 200", class = "Sports", tier = "Dealer", years = { 1992, 1998 }, value = 15000, typicalMiles = 150000, weight = 6, look = "'90s rear-drive drift coupe" },
	{ id = "BrandtBlitz", brand = "Brandt", name = "Blitz", class = "Hatchback", tier = "Dealer", years = { 2012, 2018 }, value = 16000, typicalMiles = 80000, weight = 8, look = "German hot hatch" },
	{ id = "MesaStallion", brand = "Mesa", name = "Stallion", class = "Muscle", tier = "Dealer", years = { 2011, 2017 }, value = 18000, typicalMiles = 80000, weight = 8, look = "Modern American muscle coupe" },
	{ id = "NorrlandFjord", brand = "Norrland", name = "Fjord", class = "Wagon", tier = "Dealer", years = { 2014, 2019 }, value = 19000, typicalMiles = 90000, weight = 6, look = "Modern Swedish estate" },
	{ id = "BrandtKaiser", brand = "Brandt", name = "Kaiser", class = "Luxury", tier = "Dealer", years = { 2013, 2018 }, value = 22000, typicalMiles = 70000, weight = 7, look = "German executive sedan" },
	{ id = "HanzoCrag", brand = "Hanzo", name = "Crag", class = "SUV", tier = "Dealer", years = { 2012, 2019 }, value = 26000, typicalMiles = 120000, weight = 7, look = "Body-on-frame off-road SUV" },
	{ id = "MesaLonghaul", brand = "Mesa", name = "Longhaul", class = "Pickup", tier = "Dealer", years = { 2015, 2020 }, value = 34000, typicalMiles = 90000, weight = 6, look = "Heavy-duty crew-cab pickup" },

	-- Classic & collector: $20K to $250K
	{ id = "MesaWoodie", brand = "Mesa", name = "Woodie", class = "Classic", tier = "Classic", years = { 1948, 1953 }, value = 38000, typicalMiles = 100000, weight = 7, look = "Wood-paneled '50s wagon" },
	{ id = "KazumaRonin", brand = "Kazuma", name = "Ronin Z", class = "Classic", tier = "Classic", years = { 1970, 1978 }, value = 45000, typicalMiles = 110000, weight = 8, look = "'70s Japanese long-hood sports coupe" },
	{ id = "MesaBrawler", brand = "Mesa", name = "Brawler", class = "Muscle", tier = "Classic", years = { 1967, 1972 }, value = 65000, typicalMiles = 90000, weight = 8, look = "Late-'60s American muscle car" },
	{ id = "KazumaRaijin", brand = "Kazuma", name = "Raijin", class = "Classic", tier = "Classic", years = { 1993, 1998 }, value = 85000, typicalMiles = 70000, weight = 6, look = "'90s twin-turbo Japanese GT" },
	{ id = "HanzoApex", brand = "Hanzo", name = "Apex", class = "Classic", tier = "Classic", years = { 1991, 2001 }, value = 110000, typicalMiles = 50000, weight = 4, look = "'90s Japanese mid-engine sports car" },
	{ id = "BrandtFlugel", brand = "Brandt", name = "Flugel", class = "Classic", tier = "Classic", years = { 1954, 1957 }, value = 180000, typicalMiles = 60000, weight = 2, look = "'50s German gullwing coupe" },

	-- Exotic: $150K to $3M
	{ id = "MesaRattler", brand = "Mesa", name = "Rattler", class = "Exotic", tier = "Exotic", years = { 2013, 2017 }, value = 180000, typicalMiles = 20000, weight = 8, look = "American V10 sports car" },
	{ id = "VireoRosso", brand = "Vireo", name = "Rosso", class = "Exotic", tier = "Exotic", years = { 2015, 2020 }, value = 310000, typicalMiles = 15000, weight = 7, look = "Italian mid-engine V8" },
	{ id = "VireoFuria", brand = "Vireo", name = "Furia", class = "Exotic", tier = "Exotic", years = { 2012, 2020 }, value = 420000, typicalMiles = 12000, weight = 5, look = "Angular Italian V12 wedge" },
	{ id = "BrandtNachtfalke", brand = "Brandt", name = "Nachtfalke", class = "Exotic", tier = "Exotic", years = { 2019, 2024 }, value = 1200000, typicalMiles = 3000, weight = 2, look = "German hypercar" },
	{ id = "VireoEclisse", brand = "Vireo", name = "Eclisse", class = "Exotic", tier = "Exotic", years = { 2014, 2016 }, value = 2800000, typicalMiles = 1000, weight = 1, look = "Italian hybrid hypercar" },
}

Cars.ById = {}
for _, car in Cars.List do
	Cars.ById[car.id] = car
end

-- The easy car every new player wins in the tutorial.
Cars.TutorialCarId = "KazumaMinnow"

function Cars.displayName(car)
	return car.brand .. " " .. car.name
end

return Cars
