/* Unit and save/load integration tests for src/.
 *
 * Run with tools/run_tests.py. GS API stubs keep the runtime wiring executable
 * under the standalone Squirrel interpreter.
 */

require <- function(path) {};
import <- function(library, name, version) {};

class GSController
{
    static function GetSetting(name) { return 0; }
    static function GetOpsTillSuspend() { return 100000; }
}

class GSTown
{
    static function GetPopulation(id) { throw "saved town entered fresh initialization"; }
}

class GSIndustryType
{
    static function GetAcceptedCargo(id)
    {
        local cargo_by_industry = { _5 = 10, _7 = 11, _9 = 12, _256 = 13, _510 = 14 };
        local cargo_list = {};
        local key = "_" + id;
        if (cargo_by_industry.rawin(key))
            cargo_list[cargo_by_industry[key]] <- 0;
        return cargo_list;
    }
}

SuperLib <- {
    Log = {
        LVL_INFO = 0,
        LVL_DEBUG = 0,
        function Info(message, level) {}
    },
    Helper = {}
};

dofile("src/version.nut", true);
dofile("src/industry.nut", true);
dofile("src/cargo.nut", true);
dofile("src/taxes.nut", true);
dofile("src/main.nut", true);
Randomization <- { INDUSTRY_DESC = 2, INDUSTRY_ASC = 3 };
dofile("src/town.nut", true);

function GoalTown::DebugCargoTable(cargo_table) {}

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

function SavedTown(max_population, cargo_hash)
{
    return {
        sign_id = -1,
        contributor = -1,
        max_population = max_population,
        is_monitored = false,
        allowGrowth = true,
        last_delivery = null,
        town_goals_cat = [0, 0, 0],
        town_supplied_cat = [0, 0, 0],
        town_stockpiled_cat = [0, 0, 0],
        tgr_array = array(8, 0),
        limit_transported = 0,
        limit_delay = 0,
        cargo_hash = cargo_hash
    };
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


print("MainClass save/load and GoalTown reconstruction\n");

local saved_data = {
    save_version = SELF_MAJORVERSION,
    use_town_sign = false,
    randomization = Randomization.INDUSTRY_ASC,
    display_cargo = true,
    cargo_6_category = false,
    category_min_pop = [0, 1000, 4000],
    company_data_table = {},
    town_data_table = {}
};
saved_data.town_data_table[3] <- SavedTown(300, LegacyIndustryHash([[5], [7, 9]]));
saved_data.town_data_table[900] <- SavedTown(90000, GetIndustryHash([[256], [510]]));

local controller = MainClass();
controller.Load(0, saved_data);
Check("load keeps sparse town id 3", ::TownDataTable.rawin(3));
Check("load keeps sparse town id 900", ::TownDataTable.rawin(900));

local legacy_town = GoalTown(3, true, 0, null, 0);
local sparse_town = GoalTown(900, true, 0, null, 0);
CheckEqual("sparse town restores saved population", sparse_town.max_population, 90000);
CheckTable("constructor decodes legacy industry hash", legacy_town.town_cargo_cat,
           [[0, 2], [10], [11, 12]]);
CheckTable("constructor decodes array industry hash", sparse_town.town_cargo_cat,
           [[0, 2], [13], [14]]);

controller.towns = [legacy_town, sparse_town];
controller.gs_init_done = true;
local resaved_data = controller.Save();
CheckEqual("save keeps both sparse town entries", resaved_data.town_data_table.len(), 2);
Check("save indexes town id 3", resaved_data.town_data_table.rawin(3));
Check("save indexes town id 900", resaved_data.town_data_table.rawin(900));
CheckEqual("save keeps legacy hash type", typeof resaved_data.town_data_table[3].cargo_hash, "integer");
CheckEqual("save keeps array hash type", typeof resaved_data.town_data_table[900].cargo_hash, "array");

local reloaded_controller = MainClass();
reloaded_controller.Load(0, resaved_data);
local reloaded_town = GoalTown(900, true, 0, null, 0);
CheckTable("resaved sparse town reconstructs", reloaded_town.town_cargo_cat,
           [[0, 2], [13], [14]]);


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
