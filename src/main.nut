require("src/version.nut");
require("src/cargo.nut");
require("src/industry.nut");
require("src/town.nut");
require("src/company.nut");
require("src/subsidies.nut")
require("src/taxes.nut");
require("src/story.nut");
require("src/strings.nut");

// Import SuperLib for GameScript
import("util.superlib", "SuperLib", 40);
Log <- SuperLib.Log;
Helper <- SuperLib.Helper;

// Import ToyLib
import("Library.GSToyLib", "GSToyLib", 2);
import("Library.SCPLib", "SCPLib", 45); // GSToyLib(null) instantiates SCPLib from the root table

enum Randomization {
    NONE = 1,
    INDUSTRY_DESC = 2,
    INDUSTRY_ASC = 3,
    FIXED_1 = 4,
    FIXED_2 = 5,
    FIXED_3 = 6,
    FIXED_5 = 7,
    FIXED_7 = 8,
    RANGE_1_2 = 9,
    RANGE_1_3 = 10,
    RANGE_2_3 = 11,
    RANGE_3_5 = 12,
    RANGE_3_7 = 13,
    DESCENDING = 14,
    ASCENDING = 15,
};

enum InitError {
    NONE,
    CARGO_LIST,
    INDUSTRY_LIST,
    TOWN_NUMBER,
    TOWN_GROWTH_RATE,
}

class MainClass extends GSController
{
    companies = null;
    towns = null;
    current_date = null;
    current_week = null;
    current_month = null;
    current_year = null;
    gs_init_done = null;
    load_saved_data = null;
    current_save_version = null;
    actual_town_info_mode = null;
    toy_lib = null;
    story_editor = null;

    constructor() {
        this.companies = [];
        this.towns = [];
        this.current_date = 0;
        this.current_week = 0;
        this.current_month = 0;
        this.current_year = 0;
        this.gs_init_done = false;
        this.current_save_version = SELF_MAJORVERSION;    // Ensures compatibility between revisions
        this.load_saved_data = false;
        this.actual_town_info_mode = 0;
        this.toy_lib = null;
        this.story_editor = null;
        ::TownDataTable <- {};
        ::CompanyDataTable <- {};
        ::SettingsTable <- {};
    }
}

function MainClass::Start()
{
    // Wait random number of ticks (less than one day) based on system time to ensure random number seed
    local sysdate = GSDate.GetSystemTime() % 70 + 1;
    this.Sleep(sysdate);

    // Initializing the script
    local start_tick = GSController.GetTick();

    // Read the openttd.cfg Town Growth Rate setting first.
    // If the map is set to disallow town growth at all, this script
    // won't do anything further.
    if (GSGameSettings.IsValid("town_growth_rate")) {
        if (! GSGameSettings.GetValue("town_growth_rate") ) {
            GSLog.Error("You must set town growth in advanced setting to something other than None. This script is now exiting!");
            this.story_editor = StoryEditor();
            this.story_editor.CreateStoryBook([], 0, InitError.TOWN_GROWTH_RATE);
            return;
        }
    }

    GSGame.Pause();
    Log.Info("Script initialisation...", Log.LVL_INFO);
    local init_error = this.Init();
    GSGame.Unpause();

    local setup_duration = GSController.GetTick() - start_tick;
    Log.Info("Game setup done.", Log.LVL_INFO);
    Log.Info("Setup took " + setup_duration + " ticks.", Log.LVL_DEBUG);
    Log.Info("Happy playing !", Log.LVL_INFO);

    // Wait for the game to start
    GSController.Sleep(1);

    // Create and fill StoryBook. This can't be done before OTTD is ready.
    this.story_editor = StoryEditor();
    this.story_editor.CreateStoryBook(this.companies, this.towns.len(), init_error);

    if (!this.gs_init_done) {
        GSLog.Error("Game initialisation failed. This script is now exiting!");
        return;
    }

    // Main loop
    local past_system_time = GSDate.GetSystemTime();
    while (true) {
        local town_info_mode = GSController.GetSetting("town_info_mode");
        if (this.actual_town_info_mode != town_info_mode) {
            this.actual_town_info_mode = town_info_mode;
            foreach (town in this.towns) {
                town.UpdateTownText(this.actual_town_info_mode);
            }
            continue;
        }

        local system_time = GSDate.GetSystemTime();
        if (1 == this.actual_town_info_mode && system_time - past_system_time > 3) {
            past_system_time = system_time;

            foreach (town in this.towns) {
                town.UpdateTownText(this.actual_town_info_mode);
            }
        }

        this.HandleEvents();
        this.ManageTowns();

        // Yield instead of busy-spinning; small enough to keep the 3s text scroll responsive
        GSController.Sleep(37);
    }
}

function MainClass::Init()
{
    this.toy_lib = GSToyLib(null); // Init ToyLib;

    // Check game settings
    GSGameSettings.SetValue("economy.town_growth_rate", 2);
    GSGameSettings.SetValue("economy.fund_buildings", 0);
    ::SettingsTable.wallclock_timekeeping <- GSGameSettings.GetValue("economy.timekeeping_units");

    if (!this.load_saved_data) { // Disallow changing these in a running game
        ::SettingsTable.use_town_sign <- GSController.GetSetting("use_town_sign");
        ::SettingsTable.randomization <- GSController.GetSetting("cargo_randomization");
        ::SettingsTable.display_cargo <- GSController.GetSetting("display_cargo");
        ::SettingsTable.cargo_6_category <- GSController.GetSetting("cargo_6_category");
        ::SettingsTable.category_min_pop <- [];
        for (local i = 1; i <= 6; i++)
            ::SettingsTable.category_min_pop.append(GSController.GetSetting("category_" + i + "_min_pop"));
    }

    // Set current date
    this.current_date = this.current_week = GSDate.GetCurrentDate();
    this.current_month = GSDate.GetMonth(this.current_date);
    this.current_year = GSDate.GetYear(this.current_date);

    if (::SettingsTable.randomization == Randomization.INDUSTRY_DESC
     || ::SettingsTable.randomization == Randomization.INDUSTRY_ASC) {
        if (!InitIndustryLists())
            return InitError.INDUSTRY_LIST;
    }
    else {
        // Initialize cargo lists and variables
        if (!InitCargoLists())
            return InitError.CARGO_LIST;
    }

    /* Check whether saved data are in the current save
     * format.
     */
    if (!this.load_saved_data) {
        Helper.ClearAllSigns();
    }

    // Create company list
    Log.Info("Creating company list ...", Log.LVL_INFO);
    this.companies = this.CreateCompanyList();

    // Create the towns list
    Log.Info("Creating town list ... (can take a while on large maps)", Log.LVL_INFO);
    this.towns = this.CreateTownList();
    if (this.towns.len() > SELF_MAX_TOWNS)
        return InitError.TOWN_NUMBER;
    Log.Info("Setup " + this.towns.len() + " towns", Log.LVL_INFO);

    // Run industry stabilizer
    Log.Info("Prospecting raw industries ... (can take a while on large maps)", Log.LVL_INFO);
    ProspectRawIndustry();

    // Ending initialization
    this.gs_init_done = true;

    return InitError.NONE;
}

function MainClass::HandleEvents()
{
    while (GSEventController.IsEventWaiting()) {
        local event = GSEventController.GetNextEvent();

        if (event == null)
            return;

        switch (event.GetEventType()) {
        // On town founding, add a new GoalTown instance
        case GSEvent.ET_TOWN_FOUNDED:
            event = GSEventTownFounded.Convert(event);
            local town_id = event.GetTownID();
            if (GSTown.IsValidTown(town_id)) this.UpdateTownList(town_id);
            break;

        case GSEvent.ET_COMPANY_NEW:
        case GSEvent.ET_COMPANY_BANKRUPT:
        case GSEvent.ET_COMPANY_MERGER:
            Log.Info("A company was created/bankrupt/merged => update company list", Log.LVL_INFO);
            this.UpdateCompanyList();
            break;

        case GSEvent.ET_STORYPAGE_BUTTON_CLICK:
            if (this.story_editor != null)
                this.story_editor.HandleTaxHistoryButton(this.companies, event);
            break;

        default: break;
        }
    }
}

function MainClass::Save()
{
    Log.Info("Saving data...", Log.LVL_INFO);
    local save_table = {};

    /* If the script isn't yet initialized, we can't retrieve data
     * from GoalTown instances. Thus, simply use the original
     * loaded table. Otherwise we build the table with town data.
     */
    save_table.company_data_table <- {};
    save_table.town_data_table <- {};
    if (!this.gs_init_done) {
        save_table.town_data_table <- ::TownDataTable;
    } else {
        // Save permanent settings (allows changing them in scenario editor)
        save_table.use_town_sign <- ::SettingsTable.use_town_sign;
        save_table.randomization <- ::SettingsTable.randomization;
        save_table.display_cargo <- ::SettingsTable.display_cargo;
        save_table.cargo_6_category <- ::SettingsTable.cargo_6_category;
        save_table.category_min_pop <- ::SettingsTable.category_min_pop;

        foreach (company in this.companies)
        {
            save_table.company_data_table[company.id] <- company.SavingCompanyData();
        }

        local start_opcodes = GSController.GetOpsTillSuspend();
        foreach (i, town in this.towns)
        {
            save_table.town_data_table[town.id] <- town.SavingTownData();
        }
        Log.Info("Opcodes per saved town = " + ((start_opcodes - GSController.GetOpsTillSuspend()) / this.towns.len()), Log.LVL_DEBUG);
        // Also store a savegame version flag
        save_table.save_version <- this.current_save_version;
    }

    return save_table;
}

function MainClass::Load(version, saved_data)
{
    Log.Info("Loading data...", Log.LVL_INFO);
    // Loading town data. Only load data if the savegame version matches.
    if ((saved_data.rawin("save_version") && saved_data.save_version == this.current_save_version)) {
        this.load_saved_data = true;
        ::SettingsTable.use_town_sign <- saved_data.use_town_sign;
        ::SettingsTable.randomization <- saved_data.randomization;
        ::SettingsTable.display_cargo <- saved_data.display_cargo;
        ::SettingsTable.cargo_6_category <- saved_data.cargo_6_category;
        ::SettingsTable.category_min_pop <- saved_data.category_min_pop;

        foreach (companyid, company_data in saved_data.company_data_table) {
            ::CompanyDataTable[companyid] <- company_data;
        }

        foreach (townid, town_data in saved_data.town_data_table) {
            ::TownDataTable[townid] <- town_data;
        }
    }
    else {
        Log.Info("Save data format doesn't match with current version (saved " + saved_data.save_version + " vs current " + this.current_save_version + "). Resetting.", Log.LVL_INFO);
    }
}

function MainClass::UpdateCompanyList()
{
    for(local c = GSCompany.COMPANY_FIRST; c <= GSCompany.COMPANY_LAST; c++)
    {
        local existing = null;
        local existing_idx = 0;
        foreach(index, company in this.companies)
        {
            if(company.id == c)
            {
                existing = company;
                existing_idx = index;
                break;
            }
        }

        if(GSCompany.ResolveCompanyID(c) == GSCompany.COMPANY_INVALID)
        {
            if(existing != null) {
                existing.RemoveGUIGoals();
                this.companies.remove(existing_idx);
            }

            continue;
        }

        // If the company can be resolved and exists => do anything
        if(existing != null) continue;

        // Initialize new company
        local company = Company(c, false);
        this.companies.append(company);

        if (this.story_editor != null)
            this.story_editor.CreateNewCompanyStoryBook(company);
    }
}

function MainClass::CreateCompanyList()
{
    this.companies = [];

    // Create company list from saved data
    if (this.load_saved_data && ::CompanyDataTable != null) {
        foreach (company_id, company_data in ::CompanyDataTable)
        {
            this.companies.append(Company(company_id, true));
        }
    }

    // Now we can free ::CompanyDataTable
    ::CompanyDataTable = null;

    // Update company list for created/bankrupted/merged
    this.UpdateCompanyList();

    return companies;
}

/* Make a squirrel array of GoalTown instances (towns_array). For each
 * town, an instance of GoalTown is created to store the data related
 * to that town.
 */
function MainClass::CreateTownList()
{
    // In multiplayer, pause level cannot be changed, so monthly update is forced at start to finish initialization
    // In single player, if it is not set, temporarily allow all non-construction actions during pause
    local pause_level = GSGameSettings.GetValue("construction.command_pause_level");
    if (GSGame.IsMultiplayer() && pause_level < 1)
        this.current_month -= 1;
    else if (pause_level < 1)
        GSGameSettings.SetValue("construction.command_pause_level", 1);

    // Create list of cargos/industries near each town
    local near_town;
    if (::SettingsTable.randomization == Randomization.INDUSTRY_DESC ||
        ::SettingsTable.randomization == Randomization.INDUSTRY_ASC)
        near_town = GetTownsNearbyIndustryPerCategory();
    else
        near_town = GetTownsNearbyCargoPerCategory();

    local towns_list = GSTownList();
    local towns_array = [];

    local min_transport = GSController.GetSetting("limit_min_transport");
    local near_cargo_probability = GSController.GetSetting("near_cargo_probability");
    foreach (t, _ in towns_list) {
        towns_array.append(GoalTown(t, this.load_saved_data, min_transport, near_town[t], near_cargo_probability));
    }

    // Reset to previous settings
    GSGameSettings.SetValue("construction.command_pause_level", pause_level);

    // Now we can free ::TownDataTable
    ::TownDataTable = null;

    return towns_array;
}

/* Function called on town creation. We need to add a now GoalTown
 * instance to the this.towns array. The array order doesn't matter,
 * since we never use the array index, only its values.
 */
function MainClass::UpdateTownList(town_id)
{
    // Compute cargos/industries near just this new town, not the whole map
    local near_town;
    if (::SettingsTable.randomization == Randomization.INDUSTRY_DESC ||
        ::SettingsTable.randomization == Randomization.INDUSTRY_ASC)
        near_town = GetTownNearbyIndustryPerCategory(town_id);
    else
        near_town = GetTownNearbyCargoPerCategory(town_id);

    local min_transport = GSController.GetSetting("limit_min_transport");
    local near_cargo_probability = GSController.GetSetting("near_cargo_probability");
    this.towns.append(GoalTown(town_id, false, min_transport, near_town, near_cargo_probability));
    Log.Info("New town founded: "+GSTown.GetName(town_id)+" (id: "+town_id+")", Log.LVL_DEBUG);
}

function MainClass::DailyManageTownPopulation()
{
    // Company id -> Company for O(1) contributor lookup instead of a linear scan per town
    local company_by_id = {};
    foreach (company in this.companies) {
        company_by_id[company.id] <- company;
    }

    foreach (town in this.towns) {
        local new_population = GSTown.GetPopulation(town.id);
        if (new_population > town.max_population) {
            if (company_by_id.rawin(town.contributor)) {
                local company = company_by_id[town.contributor];
                company.AddPoints(new_population - town.max_population);
                Log.Info(GSTown.GetName(town.id)
                         + " increased population by " + (new_population - town.max_population)
                         + " which was added to " + GSCompany.GetName(company.id), Log.LVL_DEBUG);
            }

            town.max_population = new_population;
        }
    }
}

/* Function called periodically (each 74 ticks) to manage
 * towns and other stuff.
 */
function MainClass::ManageTowns()
{
    // Run the daily functions
    local date = GSDate.GetCurrentDate();
    local diff_date = date - this.current_date;
    if (diff_date == 0) {
        return;
    } else {
        GSToyLib.Check();
        this.story_editor.CheckParameters(this.companies);
        DailyManageTownPopulation();

        this.current_date = date;
    }

    // Run the monthly functions
    local month = GSDate.GetMonth(date);
    local diff_month = month - this.current_month;
    if (diff_month == 0) {
        return;
    } else {
        local month_tick = GSController.GetTick();
        Log.Info("Starting Monthly Updates...", Log.LVL_INFO);

        local eternal_love = GSController.GetSetting("eternal_love");
        local eternal_love_rating = 0;
        switch (eternal_love) {
            case(1): // Outstanding
                eternal_love_rating = 1000;
                break;
            case(2): // Good
                eternal_love_rating = 400;
                break;
            case(3): // Poor
                eternal_love_rating = 0;
                break;
        }

        local threshold_setting = GSController.GetSetting("town_size_threshold");
        local min_transport = GSController.GetSetting("limit_min_transport");

        // Reuse the already-maintained company list instead of re-scanning company slots per town
        local valid_companies = [];
        foreach (company in this.companies)
            valid_companies.append(company.id);

        // Read per-month settings once here instead of once per town in MonthlyManageTown
        local monthly_settings = {
            d_factor = GSController.GetSetting("goal_scale_factor") / 100.0,
            g_factor = GSController.GetSetting("town_growth_factor"),
            e_factor = GSController.GetSetting("exponentiality_factor"),
            sup_imp_part = GSController.GetSetting("supply_impacting_part") / 100.0,
            lowest_tgr = GSController.GetSetting("lowest_town_growth_rate"),
            allow_0_days_growth = GSController.GetSetting("allow_0_days_growth"),
            landscape = GSGameSettings.GetValue("game_creation.landscape"),
            info_mode = this.actual_town_info_mode,
            valid_companies = valid_companies,
            monitoring_timeout = GSController.GetSetting("town_monitoring_timeout")
        };

        // Bucket towns by contributor so each company's GUI update is a single pass, not towns x companies
        local towns_by_contributor = {};
        foreach (town in this.towns) {
            town.ManageTownLimiting(threshold_setting, min_transport);
            town.MonthlyManageTown(monthly_settings);
            if (this.actual_town_info_mode > 1) {
                town.UpdateTownText(this.actual_town_info_mode);
            }

            if (eternal_love > 0) {
                town.EternalLove(eternal_love_rating);
            }

            if (!towns_by_contributor.rawin(town.contributor))
                towns_by_contributor[town.contributor] <- [];
            towns_by_contributor[town.contributor].append(town);
        }

        // Charge the infrastructure tax before updating the GUI so the stat reflects it
        ChargeTaxes(this.companies, towns_by_contributor, date);

        // Reset the monthly growth accumulator after the tax rebate has read it
        foreach (company in this.companies)
            company.points_this_month = 0;

        foreach (company in this.companies) {
            company.MonthlyUpdateGUIGoals(towns_by_contributor.rawin(company.id)
                                          ? towns_by_contributor[company.id] : []);
            this.story_editor.UpdateTaxHistoryPage(company);
        }

        this.current_month = month;
        local month_tick_duration = GSController.GetTick() - month_tick;
        Log.Info("Monthly Update took "+month_tick_duration+" ticks.", Log.LVL_DEBUG);
    }

    // Run the yearly functions - Nothing to do for now, so we leave it out
    local year = GSDate.GetYear(date);
    local diff_year = year - this.current_year;
    if ( diff_year == 0)
        return;
    else
    {
        Log.Info("Starting Yearly Updates...", Log.LVL_INFO);

        ProspectRawIndustry();
        CreateSubsidies(towns, companies);

        this.current_year = year;
    }
}

function Modulo(num, divisor) {
    return (num - divisor * (num / divisor));
}