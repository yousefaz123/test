# Car flip tycoon

Core game logic for the car-flip auction tycoon. The design lives in the "Car flip tycoon" section of the Roblox Game Portfolio Plan doc; the numbers here follow it.

This folder is build step 1: the pure logic behind one flip, with no Studio parts or UI yet. Every module is plain Luau that takes a `Random` and an explicit clock, so the same code runs on the server and in the tests.

## What's here

| Module | What it does |
| --- | --- |
| `Config/Cars` | 27 fictional cars across five auction tiers, from a $1,500 hatchback to a $2.8M hypercar |
| `Config/Economy` | Every tunable number: conditions, clues, auction tiers, bots, shipping, customers |
| `Valuation` | ValueCheck guide price (mileage-adjusted), shipping, inspection, what buyers think a car is worth |
| `Listings` | Generates auction listings with a hidden condition, a problem, a possible gem, and clues. `Listings.public` strips the hidden part for clients |
| `Bots` | The four bot personalities and their private max bids. Dealers price off the hidden condition |
| `Auction` | One live auction: bids, bot turns, the 5-second anti-snipe reset, winner |
| `OwnedCar` | A won car on the lot: fixing it, what's been spent, profit |
| `Customers` | Walk-in customers, which car they pick, and the haggle (offers, counters, walking away) |
| `Tutorial` | The scripted first auction: a dirty hatchback and a lowballer who bids twice and drops out |

## Getting it into Studio

With [Rojo](https://rojo.space): `rojo serve` in this folder, then connect from the Rojo plugin in Studio. The modules land in `ReplicatedStorage.FlipShared`.

Or copy each file into a ModuleScript of the same name under `ReplicatedStorage.FlipShared` (the `Config` folder stays a Folder).

## Tests

Needs the [luau CLI](https://github.com/luau-lang/luau/releases) and Python 3.

```
python3 tests/run.py        # unit tests
python3 tests/run.py sim    # economy report: every tier at several bidding caps
```

`tests/run.py` wraps each module with a fake `script`/`require` so `require(script.Parent.X)` works outside Roblox.

## Economy check (Sept 28)

From `python3 tests/run.py sim`, 3,000 simulated flips per row. The player answers every outbid up to a cap, fixes everything, and sells for 90–100% of the buyer's max.

| Online auctions, bid cap | Auctions won | Profit per car | Cars that lost money |
| --- | --- | --- | --- |
| 80% of guide | 28% | $580 (14% of guide) | 9% |
| 90% of guide | 72% | $390 (9%) | 16% |
| 110% of guide | 89% | $276 (6%) | 28% |

With only bots bidding, online cars sell for about 74% of guide, and salvage for about 40%. The first pass had bots too weak (online cars went for 51% of guide, so even reckless bidding made 18% a car); Online now has 2–3 bots and salvage bots value cars at 70% of guide.

## Next: build step 2

First playable flip in Studio: the lot, the laptop UI, a live auction, truck delivery and unloading, the wash, a repair, and a customer sale.
