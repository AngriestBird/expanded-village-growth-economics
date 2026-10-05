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
dofile("src/company.nut", true);
dofile("src/subsidies.nut", true);
dofile("src/story.nut", true);
dofile("src/main.nut", true);
dofile("src/town.nut", true);
// Enums compile into the constant table, so this file, compiled earlier, reads them at runtime
TaxSplit <- getconsttable().TaxSplit;
Randomization <- getconsttable().Randomization;

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

// A quick save or autosave can land after a load but before Init has finished.
resaved_data.company_data_table[4] <- { tax_paid = 123 };
local early_controller = MainClass();
early_controller.Load(0, resaved_data);
::TownDataTable = null;    // Init frees both tables part way through
::CompanyDataTable = null;
local early_data = early_controller.Save();
Check("save before init keeps the save version", early_data.rawin("save_version"));
CheckEqual("save before init keeps the settings", early_data.randomization, Randomization.INDUSTRY_ASC);
CheckEqual("save before init keeps both towns", early_data.town_data_table.len(), 2);
CheckEqual("save before init keeps company data", early_data.company_data_table[4].tax_paid, 123);

CheckEqual("a new game saved before init has no version to load",
           MainClass().Save().rawin("save_version"), false);

// Loaded last so later sections see the loaded settings and tables again.
local early_reloaded = MainClass();
early_reloaded.Load(0, early_data);
Check("save before init loads again", early_reloaded.load_saved_data);
Check("save before init reloads town id 900", ::TownDataTable.rawin(900));
Check("save before init reloads company id 4", ::CompanyDataTable.rawin(4));


print("GetCargoHash / GetCargoTable\n");

::CargoCat <- [[0, 2], [5, 8], [11, 40, 55]];
::CargoCatNum <- 3;

CheckTable("cargo mask round trip", GetCargoTable(GetCargoHash(::CargoCat)), ::CargoCat);

local subset = [[0, 2], [8], [40]];
CheckTable("cargo mask round trip, subset", GetCargoTable(GetCargoHash(subset)), subset);

// OpenTTD has 64 cargo slots, so the mask has to survive ids past 31.
CheckTable("cargo mask round trip, high cargo ids",
           GetCargoTable(GetCargoHash([[], [], [40, 55]])), [[], [], [40, 55]]);


print("Town contributor reset\n");

GSTown.TOWN_GROWTH_NONE <- 0;
GSTown.SetGrowthRate <- function(id, rate) {};
GSTown.SetText <- function(id, text) {};
GSTown.GetName <- function(id) { return "town " + id; };

class GSDate
{
    static function GetCurrentDate() { return 100; }
}

class GSCargoMonitor
{
    static function GetTownPickupAmount(company, cargo, town, keep_monitoring) { return 0; }
    static function GetTownDeliveryAmount(company, cargo, town, keep_monitoring) { return 0; }
}

function GoalTown::TownBoxText(growth_enabled, text_mode, redraw=false) { return null; }

::CargoLimiter <- [0, 2];
::CargoIDList <- ["PASS", null, "MAIL"];

local stale_saved = SavedTown(500, GetIndustryHash([[5], [7]]));
stale_saved.contributor = 2;
::TownDataTable[21] <- stale_saved;
CheckEqual("unmonitored saved town drops its stale contributor",
           GoalTown(21, true, 0, null, 0).contributor, -1);

local served_saved = SavedTown(500, GetIndustryHash([[5], [7]]));
served_saved.contributor = 2;
served_saved.is_monitored = true;
served_saved.last_delivery = 10;
::TownDataTable[22] <- served_saved;
local served_town = GoalTown(22, true, 0, null, 0);
CheckEqual("monitored saved town keeps its contributor", served_town.contributor, 2);

// The date stub is 90 days past the last delivery, well over the 30 day timeout.
Check("timed out town reports it is not monitored", !served_town.CheckMonitoring(true, [2], 30));
CheckEqual("timed out town stops being monitored", served_town.is_monitored, false);
CheckEqual("timed out town clears its contributor", served_town.contributor, -1);


print("CalculateRatingMultiplier\n");

CheckEqual("no rated towns leaves the bill undiscounted", CalculateRatingMultiplier([]), 1.0);
CheckEqual("one town sets the multiplier", CalculateRatingMultiplier([{ multiplier = 0.7, weight = 500 }]), 0.7);
CheckEqual("equal towns average evenly",
           CalculateRatingMultiplier([{ multiplier = 0.5, weight = 1000 }, { multiplier = 1.0, weight = 1000 }]), 0.75);
local weighted = CalculateRatingMultiplier([{ multiplier = 0.5, weight = 9000 }, { multiplier = 1.0, weight = 1000 }]);
Check("big towns dominate the average", weighted > 0.54 && weighted < 0.56);
local diluted = CalculateRatingMultiplier([{ multiplier = 1.0, weight = 9000 },
                                           { multiplier = 0.5, weight = 100 }, { multiplier = 0.5, weight = 100 },
                                           { multiplier = 0.5, weight = 100 }, { multiplier = 0.5, weight = 100 }]);
Check("villages cannot hide a poorly rated city", diluted > 0.97);
CheckEqual("empty towns still count once",
           CalculateRatingMultiplier([{ multiplier = 0.5, weight = 0 }, { multiplier = 1.0, weight = 0 }]), 0.75);


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


print("SplitTaxFunding\n");

function FundedTown(id, population, stopped = false)
{
    return { id = id, population = population, stopped = stopped };
}

function SumPortions(rows)
{
    local sum = 0;
    foreach (row in rows)
        sum += row.portion;
    return sum;
}

local pair = [FundedTown(1, 3000), FundedTown(2, 1000)];

CheckEqual("no tax funds no towns", SplitTaxFunding(0, pair, 10, TaxSplit.EQUAL).len(), 0);
CheckEqual("negative tax funds no towns", SplitTaxFunding(-100, pair, 10, TaxSplit.EQUAL).len(), 0);
CheckEqual("zero boost splits nothing, so nothing is recorded", SplitTaxFunding(2000, pair, 0, TaxSplit.EQUAL).len(), 0);
CheckEqual("no towns funds nothing", SplitTaxFunding(2000, [], 10, TaxSplit.EQUAL).len(), 0);

local even = SplitTaxFunding(2000, pair, 10, TaxSplit.EQUAL);
CheckEqual("equal split gives every town the same portion", even[0].portion, 1000);
CheckEqual("equal split keeps town ids", even[1].town_id, 2);
CheckEqual("each portion buys its growth days", even[1].days, 10);

local odd = SplitTaxFunding(1000, [FundedTown(1, 500), FundedTown(2, 500), FundedTown(3, 500)], 10, TaxSplit.EQUAL);
CheckEqual("portions add up to the tax", SumPortions(odd), 1000);
CheckEqual("odd units go to the first of equal towns", odd[0].portion, 334);
CheckEqual("other towns round down", odd[1].portion, 333);
CheckEqual("odd portions round growth days down", odd[1].days, 3);

local by_population = SplitTaxFunding(2000, pair, 10, TaxSplit.POPULATION);
CheckEqual("population split favours the big town", by_population[0].portion, 1500);
CheckEqual("population split leaves the rest to the small town", by_population[1].portion, 500);
CheckEqual("population split buys days from each portion", by_population[0].days, 15);

local underdog = SplitTaxFunding(2000, pair, 10, TaxSplit.UNDERDOG);
CheckEqual("underdog split favours the small town", underdog[1].portion, 1500);
CheckEqual("underdog split leaves the rest to the big town", underdog[0].portion, 500);

local uneven = SplitTaxFunding(1000, [FundedTown(1, 700), FundedTown(2, 200), FundedTown(3, 100)], 10, TaxSplit.POPULATION);
CheckEqual("weighted portions add up to the tax", SumPortions(uneven), 1000);
CheckEqual("rounding remainder goes to the heaviest town", uneven[0].portion, 700);

local stopped = SplitTaxFunding(2000, [FundedTown(1, 500), FundedTown(2, 500, true)], 10, TaxSplit.EQUAL);
CheckEqual("stopped towns are left out of the split", stopped.len(), 1);
CheckEqual("stopped town's share moves to the others", stopped[0].portion, 2000);
CheckEqual("redistributed share buys more days", stopped[0].days, 20);
CheckEqual("all towns stopped funds nothing", SplitTaxFunding(2000, [FundedTown(1, 500, true)], 10, TaxSplit.EQUAL).len(), 0);

local empty_town = SplitTaxFunding(2000, [FundedTown(1, 0), FundedTown(2, 1000)], 10, TaxSplit.POPULATION);
CheckEqual("a town without population still takes part", empty_town.len(), 2);
CheckEqual("a town without population weighs one resident", empty_town[0].portion, 1);

local tiny = SplitTaxFunding(2, [FundedTown(1, 500)], 10, TaxSplit.EQUAL);
CheckEqual("tiny tax splits but buys no growth", tiny[0].portion, 2);
CheckEqual("tiny tax buys no growth days", tiny[0].days, 0);
CheckEqual("unknown mode splits equally", SplitTaxFunding(2000, pair, 10, 99)[0].portion, 1000);


print("ApplyGrowthFunding\n");

CheckEqual("no funding leaves the rate unchanged", ApplyGrowthFunding(100, 0, false), 100);
CheckEqual("funding shaves days off the rate", ApplyGrowthFunding(100, 40, false), 60);
CheckEqual("funding is capped at half the rate", ApplyGrowthFunding(40, 40, false), 20);
CheckEqual("half the rate is the maximum boost", ApplyGrowthFunding(100, 1000, false), 50);
CheckEqual("odd rates cap to half rounded down", ApplyGrowthFunding(5, 40, false), 3);
CheckEqual("single day rates cannot be boosted", ApplyGrowthFunding(1, 10, true), 1);
CheckEqual("negative funding never slows growth", ApplyGrowthFunding(10, -5, false), 10);
CheckEqual("zero rate stays at zero with daily growth", ApplyGrowthFunding(0, 0, true), 0);


print("MonthlyCheckTown and the funding split\n");

class GSDate
{
    static function GetCurrentDate() { return 1000; }
}

class GSCargoMonitor
{
    static function GetTownPickupAmount(company, cargo, town, keep_monitoring)
    {
        return ::stub_pickups.rawin(town) ? ::stub_pickups[town] : 0;
    }
    static function GetTownDeliveryAmount(company, cargo, town, keep_monitoring) { return 0; }
}

::CargoLimiter <- [0, 2];
::CargoIDList <- ["PASS", null, "MAIL"];
::stub_population <- {};
::stub_pickups <- {};
::stub_growth_rate <- {};

// The shared stub throws on purpose, so it is swapped for this section only
local throwing_get_population = GSTown.GetPopulation;
GSTown.GetPopulation <- function(id) { return ::stub_population[id]; };
GSTown.TOWN_GROWTH_NONE <- 0xFFFF;
GSTown.TOWN_GROWTH_NORMAL <- 0x10000;
GSTown.SetGrowthRate <- function(id, rate) { ::stub_growth_rate[id] <- rate; };
GSTown.SetText <- function(id, text) {};
GSTown.GetName <- function(id) { return "town " + id; };
function GoalTown::TownBoxText(growth_enabled, text_mode, redraw=false) { return null; }

function CheckedTown(id, population, monitored)
{
    ::TownDataTable[id] <- SavedTown(population, GetIndustryHash([[5]]));
    ::stub_population[id] <- population;
    local town = GoalTown(id, true, 0, null, 0);
    town.is_monitored = monitored;
    town.last_delivery = 0;
    return town;
}

local check_settings = { landscape = 0, valid_companies = [0], monitoring_timeout = 365 };

// One company contributed to all three towns last month
local active_town = CheckedTown(20, 500, true);
local timed_out_town = CheckedTown(21, 500, true);
local small_town = CheckedTown(22, 80, true);
::stub_pickups[20] <- 5;

local managed = {};
local managed_towns = [];
foreach (town in [active_town, timed_out_town, small_town]) {
    managed[town.id] <- town.MonthlyCheckTown(check_settings);
    if (managed[town.id])
        managed_towns.append(town);
}

Check("monitored town with pickups is growth-managed", managed[20]);
Check("town whose monitoring times out is not growth-managed", !managed[21]);
Check("timed out town is no longer monitored", !timed_out_town.is_monitored);
CheckEqual("timed out town stops growing", ::stub_growth_rate[21], GSTown.TOWN_GROWTH_NONE);
Check("town under 100 population is not growth-managed", !managed[22]);
CheckEqual("town under 100 population grows normally", ::stub_growth_rate[22], GSTown.TOWN_GROWTH_NORMAL);

local settled = SplitTaxFunding(2000, TownFundingEntries(managed_towns), 10, TaxSplit.EQUAL);
CheckEqual("only the growth-managed town is funded", settled.len(), 1);
CheckEqual("whole tax goes to the growth-managed town", settled[0].portion, 2000);
CheckEqual("growth-managed town gets the whole boost", settled[0].days, 20);

local resumed_town = CheckedTown(23, 500, false);
::stub_pickups[23] <- 3;
Check("unmonitored town with new pickups is growth-managed", resumed_town.MonthlyCheckTown(check_settings));
Check("resumed town counts in the split", resumed_town.is_monitored);

local starting_town = CheckedTown(24, 500, true);
starting_town.initialized = false;
::stub_pickups[24] <- 5;
Check("town still initializing is not growth-managed", !starting_town.MonthlyCheckTown(check_settings));
Check("town finishes initializing", starting_town.initialized);

GSTown.GetPopulation <- throwing_get_population;


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


dofile("tests/runtime_tests.nut", true);

print("\n" + tests_run + " checks, " + tests_failed + " failed\n");
if (tests_failed == 0)
    print("ALL TESTS PASSED\n");
