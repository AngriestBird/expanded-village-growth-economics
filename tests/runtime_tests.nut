::stub_settings <- {
    tax_enable = 1, tax_rate = 10, tax_canal_rate = 20,
    tax_dock_rate = 30, tax_airport_rate = 40,
    tax_big_town_bonus = 25, tax_rating_discount = 50, tax_growth_rebate = 2,
    tax_growth_boost = 10, goal_scale_factor = 100, eternal_love = 0,
    town_size_threshold = 1000, limit_min_transport = 0, limiter_delay = 0,
    town_growth_factor = 100, exponentiality_factor = 2, supply_impacting_part = 50,
    lowest_town_growth_rate = 100, allow_0_days_growth = 0, town_monitoring_timeout = 365
};
::stub_date <- 1000;
::stub_month <- 2;
::stub_year <- 2040;
::stub_valid_companies <- { [0] = true, [1] = true };
::stub_infra <- { [0] = [100, 50, 10], [1] = [0, 0, 0] };
::stub_stations <- { [0] = [2, 1], [1] = [0, 0] };
::stub_ratings <- {};
::stub_payments <- [];
::stub_company <- 0;
::stub_deliveries <- {};
::stub_goal_progress <- {};
::stub_goal_id <- 0;
::stub_story_elements <- {};
::stub_story_id <- 0;
::stub_story_commands <- 0;

GSController.GetSetting <- function(name) {
    return ::stub_settings.rawin(name) ? ::stub_settings[name] : -1;
};
GSController.GetTick <- function() { return 0; };
GSTown.GetPopulation <- function(id) { return ::stub_population[id]; };
GSTown.GetLocation <- function(id) { return id; };
GSTown.GetRating <- function(town, company) { return 1; };
GSTown.GetDetailedRating <- function(town, company) { return ::stub_ratings[town]; };
GSTown.TOWN_RATING_NONE <- -1;
GSTown.TOWN_RATING_INVALID <- -2;

class GSDate
{
    static function GetCurrentDate() { return ::stub_date; }
    static function GetMonth(date) { return ::stub_month; }
    static function GetYear(date) { return ::stub_year; }
}

class GSCompany
{
    static COMPANY_INVALID = -1;
    static EXPENSES_OTHER = 0;
    static function ResolveCompanyID(id) {
        return ::stub_valid_companies.rawin(id) ? id : -1;
    }
    static function GetCompanyHQ(id) { return -1; }
    static function ChangeBankBalance(id, amount, expense, tile) {
        ::stub_payments.append({ id = id, amount = amount, tile = tile });
    }
    static function GetName(id) { return "company " + id; }
}

class GSCompanyMode
{
    constructor(id) { ::stub_company = id; }
}

class GSInfrastructure
{
    static INFRASTRUCTURE_RAIL = 0;
    static INFRASTRUCTURE_ROAD = 1;
    static INFRASTRUCTURE_CANAL = 2;
    static function GetInfrastructurePieceCount(id, type) { return ::stub_infra[id][type]; }
}

class GSStation
{
    static STATION_DOCK = 0;
    static STATION_AIRPORT = 1;
}

class GSStationList
{
    type = null;
    constructor(type) { this.type = type; }
    function Count() { return ::stub_stations[::stub_company][this.type]; }
}

class GSMap
{
    static function IsValidTile(tile) { return tile >= 0; }
}

class GSGameSettings
{
    static function GetValue(name) { return name == "construction.command_pause_level" ? 1 : 0; }
    static function SetValue(name, value) {}
}

class GSGame
{
    static function IsPaused() { return false; }
}

class GSGoal
{
    static GT_NONE = 0;
    static GT_STORY_PAGE = 1;
    static function IsValidGoal(id) { return id != null && id >= 0; }
    static function New(company, text, type, destination) { return ++::stub_goal_id; }
    static function SetProgress(id, text) { ::stub_goal_progress[id] <- text; }
    static function SetText(id, text) {}
    static function SetDestination(id, type, destination) {}
    static function Remove(id) {}
}

class GSText
{
    id = null;
    values = null;
    constructor(id, ...) { this.id = id; this.values = vargv; }
}

foreach (name in [
    "STR_NUM", "STR_COMMA", "STR_CURRENCY", "STR_STATISTICS_GROWTH_POINTS",
    "STR_STATISTICS_AVERAGE_CATEGORY", "STR_STATISTICS_NUM_TOWNS", "STR_STATISTICS_NOT_GROWING",
    "STR_STATISTICS_BIGGEST_TOWN", "STR_STATISTICS_GROWTH_TOWN", "STR_STATISTICS_TAX_PAID",
    "STR_STATISTICS_TAX_LAST_MONTH", "STR_STATISTICS_TAX_REBATE", "STR_STATISTICS_TAX_RAIL_ROAD_PAID",
    "STR_STATISTICS_TAX_DOCK_PAID", "STR_STATISTICS_TAX_RAIL_ROAD_LAST_MONTH",
    "STR_STATISTICS_TAX_DOCK_LAST_MONTH", "STR_STATISTICS_TAX_HISTORY", "STR_STATISTICS_TAX_HISTORY_OPEN",
    "STR_STATISTICS_TAX_FUNDING", "STR_STATISTICS_TAX_FUNDING_OPEN", "STR_SB_TAX_HISTORY_EMPTY",
    "STR_SB_TAX_HISTORY_SUMMARY", "STR_SB_TAX_HISTORY_ROW", "STR_SB_TAX_HISTORY_LINE",
    "STR_SB_TAX_HISTORY_OLDER", "STR_SB_TAX_HISTORY_NEWER", "STR_SB_TAX_FUNDING_EMPTY",
    "STR_SB_TAX_FUNDING_MONTH", "STR_SB_TAX_FUNDING_TOWN",
    "STR_SB_TAX_FUNDING_PREVIOUS_TOWNS", "STR_SB_TAX_FUNDING_MORE_TOWNS"
]) GSText[name] <- name;

max <- function(a, b) { return a > b ? a : b; };
GetColorText <- function(id) { return null; };
GSTown.IsValidTown <- function(id) { return ::stub_population.rawin(id); };
GSToyLib <- { function Check() {} };

class GSCargoMonitor
{
    static function GetTownPickupAmount(company, cargo, town, keep_monitoring) {
        return ::stub_pickups.rawin(town) ? ::stub_pickups[town] : 0;
    }
    static function GetTownDeliveryAmount(company, cargo, town, keep_monitoring) {
        return keep_monitoring && ::stub_deliveries.rawin(town) ? ::stub_deliveries[town] : 0;
    }
}

function GoalTown::DebugCargoSupplied(cargo, supplied) {}
function GoalTown::DebugCompanyCategorySupplied(company, category, supplied) {}
function GoalTown::DebugCargoCatInfo(category) {}
function GoalTown::DebugTgrArray() {}

class GSStoryPage
{
    static SPET_TEXT = 0;
    static SPET_BUTTON_PUSH = 1;
    static SPBC_ORANGE = 0;
    static SPBF_FLOAT_LEFT = 0;
    static SPBF_FLOAT_RIGHT = 1;
    static function IsValidStoryPage(page) { return page != null && page >= 0; }
    static function NewElement(page, type, reference, text) {
        ++::stub_story_commands;
        local id = ++::stub_story_id;
        ::stub_story_elements[id] <- { page = page, type = type, text = text };
        return id;
    }
    static function RemoveElement(id) {
        ++::stub_story_commands;
        delete ::stub_story_elements[id];
    }
    static function MakePushButtonReference(color, flags) { return flags; }
}

function GSStoryPageElementList(page)
{
    local elements = {};
    foreach (id, element in ::stub_story_elements) {
        if (element.page == page)
            elements[id] <- 0;
    }
    return elements;
}

class GSEventStoryPageButtonClick
{
    static function Convert(event) { return event; }
}

function PageButton(company, page, element)
{
    return {
        company = company, page = page, element = element,
        function GetCompanyID() { return this.company; },
        function GetStoryPageID() { return this.page; },
        function GetElementID() { return this.element; }
    };
}

function TestCompany(id)
{
    ::CompanyDataTable <- {};
    ::CompanyDataTable[id] <- { points = 0, global_goal = null, statistics = array(Statistics.END, -1) };
    return Company(id, true);
}

print("Company save/load and funding history\n");
local company = TestCompany(0);
CheckEqual("legacy company defaults missing tax totals", company.tax_paid, 0);
CheckEqual("legacy company defaults missing monthly growth", company.points_this_month, 0);
CheckEqual("legacy company defaults missing history", company.tax_history.len(), 0);
company.points = 100;
company.points_this_month = 20;
company.tax_paid = 1400;
company.tax_last_month = 400;
company.tax_rebate_last_month = 10;
company.tax_rail_road_paid = 1000;
company.tax_dock_paid = 400;
company.tax_rail_road_last_month = 300;
company.tax_dock_last_month = 100;
company.RecordTaxHistory(2040, 2, 300, 100, 10);
company.RecordTaxFunding(2040, 2, [{ id = 20, is_monitored = true }, { id = 21, is_monitored = false }], 400, 4);
CheckEqual("funding records only monitored towns", company.tax_history[0].town_funding.len(), 1);
CheckEqual("funding records town id", company.tax_history[0].town_funding[0].town_id, 20);
CheckEqual("funding records portion", company.tax_history[0].town_funding[0].portion, 400);
CheckEqual("funding records days", company.tax_history[0].town_funding[0].days, 4);
company.RecordTaxFunding(2040, 1, [], 100, 1);
CheckEqual("stale funding leaves current entry intact", company.tax_history[0].town_funding.len(), 1);
local saved_company = company.SavingCompanyData();
::CompanyDataTable[0] <- saved_company;
local restored = Company(0, true);
foreach (key, value in saved_company)
    CheckEqual("company round trip " + key, restored[key], value);
::CompanyDataTable[0] <- { points = 7, global_goal = 1, statistics = [2, 3] };
local old_company = Company(0, true);
CheckEqual("old statistics grow to current size", old_company.statistics.len(), Statistics.END);
CheckEqual("old statistics preserve goal ids", old_company.statistics[1], 3);
CheckEqual("new statistics slots are unset", old_company.statistics[Statistics.TAX_FUNDING], -1);
for (local i = 0; i < 40; ++i)
    company.RecordTaxHistory(2041, i, 10, 20, 1);
CheckEqual("history retains 36 entries", company.tax_history.len(), 36);
CheckEqual("history removes oldest entries", company.tax_history[0].month, 4);
CheckEqual("history keeps latest entry", company.tax_history[35].month, 39);
local empty_company = TestCompany(1);
empty_company.RecordTaxFunding(2040, 2, [], 10, 1);
CheckEqual("funding without tax history is ignored", empty_company.tax_history.len(), 0);

print("Small-town monitoring and missing subsidy contributors\n");
local check_settings = { landscape = 0, valid_companies = [0], monitoring_timeout = 365 };
::TownDataTable <- {};
local small_timeout = CheckedTown(50, 80, true);
small_timeout.contributor = 0;
Check("small town is not growth-managed", !small_timeout.MonthlyCheckTown(check_settings));
Check("small town still times out", !small_timeout.is_monitored);
CheckEqual("small town clears its contributor", small_timeout.contributor, -1);
CheckEqual("small town retains normal growth after timeout", ::stub_growth_rate[50], GSTown.TOWN_GROWTH_NORMAL);
local small_served = CheckedTown(51, 80, true);
small_served.contributor = 0;
::stub_pickups[51] <- 5;
small_served.MonthlyCheckTown(check_settings);
Check("small served town stays monitored", small_served.is_monitored);
CheckEqual("small served town refreshes last pickup date", small_served.last_delivery, 1000);
CheckEqual("small served town clears stale contributor", small_served.contributor, -1);
local no_timeout = CheckedTown(52, 80, true);
no_timeout.contributor = 0;
no_timeout.MonthlyCheckTown({ landscape = 0, valid_companies = [0], monitoring_timeout = 0 });
Check("small town honors disabled monitoring timeout", no_timeout.is_monitored);
CheckEqual("small town with timeout disabled has no contributor", no_timeout.contributor, -1);
local sorted = null;
try {
    sorted = SortTowns([{ id = 1, is_monitored = true, contributor = 9 },
                        { id = 2, is_monitored = true, contributor = 0 },
                        { id = 3, is_monitored = false, contributor = -1 }], [{ id = 0 }]);
} catch (error) {}
Check("subsidy sorting tolerates a removed company", sorted != null);
if (sorted != null) {
    CheckEqual("subsidy sorting keeps current contributor", sorted.contributed[0][0], 1);
    CheckEqual("subsidy sorting keeps unmonitored town", sorted.not_monitored[0], 3);
}

print("ChargeTaxes end to end\n");
::stub_population[60] <- 600;
::stub_population[61] <- 1000;
::stub_ratings[60] <- 500;
::stub_ratings[61] <- 0;
company = TestCompany(0);
company.points_this_month = 100;
empty_company = TestCompany(1);
local invalid_company = TestCompany(9);
ChargeTaxes([company, empty_company, invalid_company], {
    [0] = [{ id = 60, is_monitored = true }, { id = 61, is_monitored = false }]
}, 1000);
CheckEqual("tax combines rates, rating discount, surcharge and rebate", company.tax_last_month, 1487);
CheckEqual("tax records growth rebate", company.tax_rebate_last_month, 200);
CheckEqual("tax debits bank balance", ::stub_payments[0].amount, -1487);
CheckEqual("tax uses served town when HQ is absent", ::stub_payments[0].tile, 60);
CheckEqual("tax cumulative buckets sum to total", company.tax_rail_road_paid + company.tax_dock_paid, company.tax_paid);
CheckEqual("tax history records month charged", company.tax_history[0].month, 2);
CheckEqual("empty infrastructure records a zero bill", empty_company.tax_history[0].total, 0);
CheckEqual("invalid company gets no tax history", invalid_company.tax_history.len(), 0);
CheckEqual("only taxed company gets a bank debit", ::stub_payments.len(), 1);
company.points_this_month = 100000;
ChargeTaxes([company], { [0] = [{ id = 60, is_monitored = true }] }, 1000);
CheckEqual("full rebate produces zero net tax", company.tax_last_month, 0);
CheckEqual("full rebate creates no bank debit", ::stub_payments.len(), 1);
::stub_settings.tax_enable = 0;
company.tax_last_month = 999;
ChargeTaxes([company], {}, 1000);
CheckEqual("disabled tax clears monthly total", company.tax_last_month, 0);
CheckEqual("disabled tax creates no history entry", company.tax_history.len(), 2);
::stub_settings.tax_enable = 1;
::stub_settings.tax_airport_rate = -1;
CheckEqual("unknown tax setting cannot pay company", GetTaxRateSetting("tax_airport_rate"), 0);
::stub_settings.tax_airport_rate = 40;
::stub_population[62] <- 6000;
::stub_ratings[62] <- 1000;
company = TestCompany(0);
ChargeTaxes([company], { [0] = [{ id = 60, is_monitored = true }, { id = 62, is_monitored = true }] }, 1000);
CheckEqual("rating discount weighs towns by population", company.tax_last_month, 1411);

print("ManageTowns monthly wiring\n");
::CargoCatNum = 3;
::CargoMinPopDemand = [0, 1000, 4000];
::CargoPermille = [100, 100, 100];
::CargoDecay = [0.0, 0.0, 0.0];
::stub_infra[0] = [100, 0, 0];
::stub_stations[0] = [0, 0];
::stub_settings.tax_rating_discount = 0;
::stub_settings.tax_growth_rebate = 0;
local monthly = MainClass();
::SettingsTable.use_town_sign <- false;
::SettingsTable.randomization <- Randomization.INDUSTRY_ASC;
monthly.current_date = 999;
monthly.current_month = 1;
monthly.current_year = 2040;
monthly.story_editor = StoryEditor();
company = TestCompany(0);
company.points_this_month = 10;
monthly.companies = [company];
local active = CheckedTown(70, 600, true);
active.contributor = 0;
::stub_pickups[70] <- 5;
::stub_ratings[70] <- 0;
local timeout = CheckedTown(71, 600, true);
timeout.contributor = 0;
::stub_ratings[71] <- 0;
local small = CheckedTown(72, 80, true);
small.contributor = 0;
::stub_ratings[72] <- 0;
monthly.towns = [active, timeout, small];
monthly.ManageTowns();
CheckEqual("monthly tax uses settled monitoring state", company.tax_last_month, 1250);
CheckEqual("monthly funding contains just managed town", company.tax_history[0].town_funding.len(), 1);
CheckEqual("monthly funding matches taxed amount", company.tax_history[0].town_funding[0].portion, 1250);
CheckEqual("monthly funding is applied before growth update", active.tgr_array[0], 88);
CheckEqual("monthly pass clears previous growth points after tax", company.points_this_month, 0);
CheckEqual("monthly pass updates month", monthly.current_month, 2);
CheckEqual("monthly pass drops timed-out contributor", timeout.contributor, -1);
CheckEqual("monthly pass drops small-town contributor", small.contributor, -1);
CheckEqual("GUI excludes stale contributors", ::stub_goal_progress[company.statistics[Statistics.NUM_TOWNS]].values[0], 0);
monthly.ManageTowns();
CheckEqual("same day does not charge again", company.tax_history.len(), 1);
::stub_date = 1001;
monthly.ManageTowns();
CheckEqual("same month does not charge again", company.tax_history.len(), 1);
::stub_date = 1030;
::stub_month = 3;
::stub_deliveries[70] <- 10;
active.contributor = 0;
::stub_settings.tax_growth_boost = 0;
monthly.ManageTowns();
Check("boost off records no funding rows", !company.tax_history[1].rawin("town_funding"));
CheckEqual("boost off stores unboosted sample", active.tgr_array[1], 100);
CheckEqual("deliveries refresh contributor", active.contributor, 0);

print("Tax funding Story Book command workload\n");
company = TestCompany(0);
company.sp_tax_funding = 10;
for (local month = 1; month <= 12; ++month) {
    company.RecordTaxHistory(2040, month, 300000, 0, 0);
    local towns = [];
    for (local town = 0; town < 300; ++town)
        towns.append({ id = town, is_monitored = true });
    company.RecordTaxFunding(2040, month, towns, 1000, 10);
}
local editor = StoryEditor();
::stub_story_commands = 0;
editor.UpdateTaxFundingPage(company);
print("  funding initial commands (12 months, 300 towns): " + ::stub_story_commands + "\n");
::stub_story_commands = 0;
editor.UpdateTaxFundingPage(company);
print("  funding rebuild commands (same workload): " + ::stub_story_commands + "\n");
Check("funding rebuild stays below 50 story commands", ::stub_story_commands < 50);

function PageTexts(page, text_id)
{
    local texts = [];
    foreach (id, element in ::stub_story_elements) {
        if (element.page == page && element.text.id == text_id)
            texts.append(element.text);
    }
    return texts;
}

CheckEqual("funding page shows one month", PageTexts(10, GSText.STR_SB_TAX_FUNDING_MONTH).len(), 1);
CheckEqual("funding page starts with most recent funded month", PageTexts(10, GSText.STR_SB_TAX_FUNDING_MONTH)[0].values[1], 12);
CheckEqual("funding page caps visible towns at 20", PageTexts(10, GSText.STR_SB_TAX_FUNDING_TOWN).len(), 20);
local seen = {};
for (local page = 0; page < 15; ++page) {
    foreach (text in PageTexts(10, GSText.STR_SB_TAX_FUNDING_TOWN))
        seen[text.values[0]] <- true;
    if (page < 14) {
        ::stub_story_commands = 0;
        editor.HandleTaxButton([company], PageButton(0, 10, company.tax_funding_next_towns_button));
        Check("town page " + page + " has bounded commands", ::stub_story_commands <= 52);
    }
}
CheckEqual("paging preserves all 300 funding rows", seen.len(), 300);
CheckEqual("last town page has no more button", company.tax_funding_next_towns_button, -1);
editor.HandleTaxButton([company], PageButton(1, 10, company.tax_funding_previous_towns_button));
CheckEqual("another company cannot page funding", company.tax_funding_town_offset, 280);
editor.HandleTaxButton([company], PageButton(0, 999, company.tax_funding_previous_towns_button));
CheckEqual("another page cannot change funding offset", company.tax_funding_town_offset, 280);
local stale_button = company.tax_funding_previous_towns_button;
editor.HandleTaxButton([company], PageButton(0, 10, stale_button));
CheckEqual("previous towns moves back by 20", company.tax_funding_town_offset, 260);
editor.HandleTaxButton([company], PageButton(0, 10, stale_button));
CheckEqual("stale button ids are ignored", company.tax_funding_town_offset, 260);
editor.HandleTaxButton([company], PageButton(0, 10, company.tax_funding_previous_button));
CheckEqual("older funding month advances offset", company.tax_funding_offset, 1);
CheckEqual("changing funding month resets town offset", company.tax_funding_town_offset, 0);
CheckEqual("older funding month is displayed", PageTexts(10, GSText.STR_SB_TAX_FUNDING_MONTH)[0].values[1], 11);
editor.HandleTaxButton([company], PageButton(0, 10, company.tax_funding_next_button));
CheckEqual("newer funding month returns to latest", company.tax_funding_offset, 0);
company.tax_funding_offset = 99;
company.tax_funding_town_offset = 999;
editor.UpdateTaxFundingPage(company);
CheckEqual("trimmed history resets invalid month offset", company.tax_funding_offset, 0);
CheckEqual("smaller month resets invalid town offset", company.tax_funding_town_offset, 0);
company.RecordTaxHistory(2041, 1, 1000, 0, 0);
editor.UpdateTaxFundingPage(company);
CheckEqual("funding page skips unfunded months", PageTexts(10, GSText.STR_SB_TAX_FUNDING_MONTH)[0].values[1], 12);
company.tax_history = [{ year = 2040, month = 1, rail_road = 0, docks = 0, rebate = 0, total = 0 }];
editor.UpdateTaxFundingPage(company);
CheckEqual("old history without funding shows empty page", PageTexts(10, GSText.STR_SB_TAX_FUNDING_EMPTY).len(), 1);
CheckEqual("empty funding page clears buttons", company.tax_funding_previous_button, -1);
company.tax_history = [];
company.RecordTaxHistory(2040, 1, 21000, 0, 0);
local short_rows = [];
for (local i = 0; i < 21; ++i)
    short_rows.append({ id = i, is_monitored = true });
company.RecordTaxFunding(2040, 1, short_rows, 1000, 10);
editor.UpdateTaxFundingPage(company);
editor.HandleTaxButton([company], PageButton(0, 10, company.tax_funding_next_towns_button));
CheckEqual("partial final page shows remaining row", PageTexts(10, GSText.STR_SB_TAX_FUNDING_TOWN).len(), 1);
CheckEqual("partial final page keeps last town", PageTexts(10, GSText.STR_SB_TAX_FUNDING_TOWN)[0].values[0], 20);
company.sp_tax_history = 11;
for (local i = 0; i < 24; ++i)
    company.RecordTaxHistory(2041, i, 1000, 0, 0);
editor.UpdateTaxHistoryPage(company);
CheckEqual("tax history still shows 12 months", PageTexts(11, GSText.STR_SB_TAX_HISTORY_ROW).len(), 12);
editor.HandleTaxButton([company], PageButton(0, 11, company.tax_history_previous_button));
CheckEqual("tax history older button still pages by 12", company.tax_history_offset, 12);
editor.HandleTaxButton([company], PageButton(0, 11, company.tax_history_next_button));
CheckEqual("tax history newer button still returns to latest", company.tax_history_offset, 0);
