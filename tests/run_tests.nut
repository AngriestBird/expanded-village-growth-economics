/* Unit tests for the pure helpers in src/.
 *
 * Run with tools/run_tests.py. Only files that are safe to load outside OpenTTD
 * are pulled in here: they must define functions and globals at file scope and
 * nothing else. Anything reaching for a GS API or `this` at load time belongs
 * in the game, not in a test.
 */

dofile("src/industry.nut", true);
dofile("src/cargo.nut", true);
dofile("src/taxes.nut", true);

tests_run <- 0;
tests_failed <- 0;

function Check(name, condition)
{
    tests_run++;
    if (condition) {
        print("  ok   " + name + "\n");
    } else {
        tests_failed++;
        print("  FAIL " + name + "\n");
    }
}

function CheckEqual(name, actual, expected)
{
    tests_run++;
    if (actual == expected) {
        print("  ok   " + name + "\n");
    } else {
        tests_failed++;
        print("  FAIL " + name + ": expected " + expected + ", got " + actual + "\n");
    }
}

/* Categories are arrays of arrays, so compare them by their printed form. */
function TableToString(categories)
{
    local text = "[";
    foreach (i, cat in categories) {
        if (i > 0) text += ", ";
        text += "[";
        foreach (j, value in cat) {
            if (j > 0) text += " ";
            text += value;
        }
        text += "]";
    }
    return text + "]";
}

function CheckTable(name, actual, expected)
{
    CheckEqual(name, TableToString(actual), TableToString(expected));
}

/* The single-integer encoding written by 1.2.0 and earlier. */
function LegacyIndustryHash(industry_cat)
{
    local hash = 0;
    local index = 0;
    foreach (cat in industry_cat) {
        local new_cat = 0x01;
        foreach (ind in cat) {
            hash = hash | ((((ind & 0xff) << 1) | new_cat) << index);
            index += 9;
            new_cat = 0x00;
        }
    }
    return hash;
}


print("GetIndustryHash / GetIndustryTable\n");

local simple = [[5], [7], [3, 9], [12]];
CheckTable("round trip, typical table", GetIndustryTable(GetIndustryHash(simple)), simple);

// The widest table RandomizeIndustry can emit: one industry for category II and
// up to two each for III, IV and V.
local widest = [[40], [41, 42], [43, 44], [45, 46]];
CheckTable("round trip, widest randomized table", GetIndustryTable(GetIndustryHash(widest)), widest);

CheckTable("round trip, industry id 0", GetIndustryTable(GetIndustryHash([[0], [0, 1], [2]])), [[0], [0, 1], [2]]);
CheckTable("round trip, empty category", GetIndustryTable(GetIndustryHash([[5], []])), [[5], []]);

// The old 8 bit id field could not represent these at all.
local high_ids = [[255], [256, 510]];
CheckTable("round trip, industry ids above 255", GetIndustryTable(GetIndustryHash(high_ids)), high_ids);
Check("legacy format could not hold ids above 255",
      TableToString(GetLegacyIndustryTable(LegacyIndustryHash(high_ids))) != TableToString(high_ids));

// Savegames from 1.2.0 store the old integer and must keep loading.
local legacy = [[5], [7], [3, 9]];
CheckTable("legacy integer hash still decodes", GetIndustryTable(LegacyIndustryHash(legacy)), legacy);


print("GetCargoHash / GetCargoTable\n");

::CargoCat <- [[0, 2], [5, 8], [11, 40, 55]];
::CargoCatNum <- 3;

CheckTable("cargo mask round trip", GetCargoTable(GetCargoHash(::CargoCat)), ::CargoCat);

local subset = [[0, 2], [8], [40]];
CheckTable("cargo mask round trip, subset", GetCargoTable(GetCargoHash(subset)), subset);

// OpenTTD has 64 cargo slots, so the mask has to survive ids past 31.
CheckTable("cargo mask round trip, high cargo ids",
           GetCargoTable(GetCargoHash([[], [], [40, 55]])), [[], [], [40, 55]]);


print("CalculateTaxBill\n");

CheckEqual("no infrastructure charges nothing", CalculateTaxBill(0, 0, 1.0, 0.0, 0, 1.0, 0, 0).total, 0);

local net_only = CalculateTaxBill(100, 0, 1.0, 0.0, 0, 1.0, 0, 0);
CheckEqual("network only, total", net_only.total, 100);
CheckEqual("network only, station bucket empty", net_only.stations, 0);

local stations_only = CalculateTaxBill(0, 60, 1.0, 0.0, 0, 1.0, 0, 0);
CheckEqual("stations only, total", stations_only.total, 60);
CheckEqual("stations only, network bucket empty", stations_only.network, 0);

local split = CalculateTaxBill(150, 50, 1.0, 0.0, 0, 1.0, 0, 0);
CheckEqual("split total", split.total, 200);
CheckEqual("split network share", split.network, 150);
CheckEqual("split station share", split.stations, 50);

// Whatever the rounding, the buckets have to add up to what the company is charged.
local odd = CalculateTaxBill(37, 13, 1.0, 0.0, 0, 1.0, 0, 0);
CheckEqual("buckets sum to total", odd.network + odd.stations, odd.total);

CheckEqual("difficulty scales the bill", CalculateTaxBill(100, 0, 1.5, 0.0, 0, 1.0, 0, 0).total, 150);
CheckEqual("big town bonus scales the bill", CalculateTaxBill(100, 0, 1.0, 0.25, 2, 1.0, 0, 0).total, 150);
CheckEqual("rating discount scales the bill", CalculateTaxBill(100, 0, 1.0, 0.0, 0, 0.5, 0, 0).total, 50);

CheckEqual("rebate reduces the bill", CalculateTaxBill(100, 0, 1.0, 0.0, 0, 1.0, 2, 10).total, 80);

local capped = CalculateTaxBill(100, 0, 1.0, 0.0, 0, 1.0, 5, 1000);
CheckEqual("rebate is capped at the gross tax", capped.rebate, 100);
CheckEqual("a fully rebated bill is zero, not negative", capped.total, 0);

local capped_split = CalculateTaxBill(70, 30, 1.0, 0.0, 0, 1.0, 5, 1000);
CheckEqual("fully rebated split leaves no negative network bucket", capped_split.network, 0);
CheckEqual("fully rebated split leaves no negative station bucket", capped_split.stations, 0);


print("SortCategoriesMinPopDemand\n");

::CargoCatNum <- 3;
::CargoCat <- [[1], [2], [3]];
::CargoCatList <- ["a", "b", "c"];
::CargoMinPopDemand <- [4000, 0, 1000];
::CargoPermille <- [40, 60, 10];
::CargoDecay <- [0.1, 0.4, 0.2];

SortCategoriesMinPopDemand();

CheckEqual("min pop demand is sorted ascending",
           ::CargoMinPopDemand[0] + "," + ::CargoMinPopDemand[1] + "," + ::CargoMinPopDemand[2], "0,1000,4000");
CheckTable("categories follow the sort", ::CargoCat, [[2], [3], [1]]);
CheckEqual("labels follow the sort", ::CargoCatList[0] + ::CargoCatList[1] + ::CargoCatList[2], "bca");
CheckEqual("permille follows the sort",
           ::CargoPermille[0] + "," + ::CargoPermille[1] + "," + ::CargoPermille[2], "60,10,40");


print("\n" + tests_run + " checks, " + tests_failed + " failed\n");
if (tests_failed == 0)
    print("ALL TESTS PASSED\n");
