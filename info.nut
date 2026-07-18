/*
 * This file is part of Renewed Village Growth, a GameScript for OpenTTD.
 * Credits Firrel (original Renewed Village Growth), keoz (Renewed City Growth), Sylf (City Growth Limiter)
 *
 * It's free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the
 * Free Software Foundation, version 2 of the License.
 *
 */


require("version.nut");

class MainClass extends GSInfo
    {
    function GetAuthor()                { return "AngriestBird"; }
    function GetName()                  { return "Expanded Village Growth + Economics"; }
    function GetShortName()             { return "EVGE"; }
    function GetDescription()           { return "Towns require various cargo deliveries to grow. Required cargos can be randomized. Town growth is limited by percentage of transported specific cargos. Supporting most Industry NewGRF sets."; }
    function GetURL()                   { return "https://angriestbird.github.io/expanded-village-growth-economics/"; }
    function GetVersion()               { return SELF_VERSION; }
    function GetDate()                  { return SELF_DATE; }
    function GetAPIVersion()            { return "14"; }
    function MinVersionToLoad()         { return SELF_MINLOADVERSION; }
    function CreateInstance()           { return "MainClass"; }
    function GetSettings() {

        AddSetting({ name = "town_info_mode",
                description = "Town info display mode",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_INGAME, min_value = 1, max_value = 5 });
        AddLabels("town_info_mode", {
                    _1 = "Automatic",
                    _2 = "Category deliveries",
                    _3 = "Cargo list",
                    _4 = "Combined",
                    _5 = "Full cargo list" });

        AddSetting({ name = "goal_scale_factor",
                description = "Difficulty level (easy = 60, normal = 100, hard = 140)",
                easy_value = 60,
                medium_value = 100,
                hard_value = 140,
                custom_value = 100,
                flags = CONFIG_INGAME, min_value = 1, max_value = 50000, step_size = 20 });

        AddSetting({ name = "use_town_sign",
                description = "Show growth rate text under town names",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_BOOLEAN | CONFIG_INGAME });

        AddSetting({ name = "eternal_love",
                description = "Eternal love from towns",
                easy_value = 1,
                medium_value = 3,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_INGAME, min_value = 0, max_value = 3 });
        AddLabels("eternal_love", { _0 = "Off",
                    _1 = "Outstanding",
                    _2 = "Good",
                    _3 = "Poor" });

        AddSetting({
                name = "cargo_6_category",
                description = "Cargo: Use 6 cargo categories for supported economies",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_BOOLEAN | CONFIG_INGAME });

        // Values map 1:1 to the Economies enum in cargo.nut; the last value forces generated categories
        AddSetting({ name = "force_economy",
                description = "Cargo: Force economy (instead of auto detection)",
                easy_value = 0,
                medium_value = 0,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_INGAME, min_value = 0, max_value = 49 });
        AddLabels("force_economy", {
                _0 = "Auto detect",
                _1 = "Base Temperate",
                _2 = "Base Arctic",
                _3 = "Base Tropical",
                _4 = "Base Toyland",
                _5 = "FIRS 1 FIRS",
                _6 = "FIRS 1 Temperate",
                _7 = "FIRS 1 Arctic",
                _8 = "FIRS 1 Tropic",
                _9 = "FIRS 1 Hearth Of Darkness",
                _10 = "ECS",
                _11 = "FIRS 2 Temperate",
                _12 = "FIRS 2 Arctic",
                _13 = "FIRS 2 Tropic",
                _14 = "FIRS 2 In A Hot Country",
                _15 = "FIRS 2 Extreme",
                _16 = "YETI",
                _17 = "FIRS 3 Temperate",
                _18 = "FIRS 3 Arctic",
                _19 = "FIRS 3 Tropic",
                _20 = "FIRS 3 Steeltown",
                _21 = "FIRS 3 In A Hot Country",
                _22 = "FIRS 3 Extreme",
                _23 = "NAIS North America",
                _24 = "Improved Town Industries",
                _25 = "FIRS 4 Temperate",
                _26 = "FIRS 4 Arctic",
                _27 = "FIRS 4 Tropic",
                _28 = "FIRS 4 Steeltown",
                _29 = "FIRS 4 In A Hot Country",
                _30 = "FIRS 5 Temperate",
                _31 = "FIRS 5 Arctic",
                _32 = "FIRS 5 Tropic",
                _33 = "FIRS 5 Steeltown",
                _34 = "FIRS 5 In A Hot Country",
                _35 = "FIRS Forked: Oil Town",
                _36 = "XIS The Lot",
                _37 = "AXIS Steel City",
                _38 = "AXIS Tropical Paradise",
                _39 = "AXIS Extreme Classic",
                _40 = "OTIS",
                _41 = "Industries of the Caribbean",
                _42 = "Lumberjack Industries",
                _43 = "Wannaroo Basic Industries",
                _44 = "Improved Town Industries 2",
                _45 = "Real Industries",
                _46 = "Minimalist Industries",
                _47 = "Pikka's Industries Redux Set (PIRS 2022)",
                _48 = "DefaultIndustriesPlus Temperate",
                _49 = "Generated categories" });

        AddSetting({ name = "cargo_randomization",
                description = "Randomization: Type",
                easy_value = 1,
                medium_value = 7,
                hard_value = 10,
                custom_value = 10,
                flags = CONFIG_INGAME, min_value = 1, max_value = 15 });
        AddLabels("cargo_randomization", {
                    _1 = "None",
                    _2 = "Industry descending",
                    _3 = "Industry ascending",
                    _4 = "1 per category",
                    _5 = "2 per category",
                    _6 = "3 per category",
                    _7 = "5 per category",
                    _8 = "7 per category",
                    _9 = "1-2 per category",
                    _10 = "1-3 per category",
                    _11 = "2-3 per category",
                    _12 = "3-5 per category",
                    _13 = "3-7 per category",
                    _14 = "Descending",
                    _15 = "Ascending" });

        AddSetting({ name = "near_cargo_probability",
                    description = "Randomization: Probability to use nearby cargo types [%]",
                    easy_value = 100,
                    medium_value = 50,
                    hard_value = 0,
                    custom_value = 50,
                    flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 10});

        AddSetting({ name = "display_cargo",
                description = "Randomization: Show town cargos from start",
                easy_value = 1,
                medium_value = 0,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_BOOLEAN | CONFIG_INGAME});

        AddSetting({ name = "raw_industry_density",
                description = "Industry stabilizer: Raw industry density",
                easy_value = 0,
                medium_value = 0,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_INGAME, min_value = 0, max_value = 5});
        AddLabels("raw_industry_density", {
                    _0 = "Funding only",
                    _1 = "Minimal",
                    _2 = "Very Low",
                    _3 = "Low",
                    _4 = "Normal",
                    _5 = "High" });

        AddSetting({
            name = "limit_min_transport",
            description = "Limit Growth: Minimum percentage of transported cargo from town",
            easy_value = 40,
            medium_value = 50,
            hard_value = 65,
            custom_value = 50,
            flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 5});

        AddSetting({
            name = "town_size_threshold",
            description = "Limit Growth: Minimum size of town before the limit rules kicks in",
            easy_value = 800,
            medium_value = 550,
            hard_value = 350,
            custom_value = 350,
            flags = CONFIG_INGAME, min_value = 0, max_value = 50000, step_size = 25});

        AddSetting({
            name = "limiter_delay",
            description = "Limit Growth: Stop growth after set amount of months",
            easy_value = 3,
            medium_value = 1,
            hard_value = 0,
            custom_value = 1,
            flags = CONFIG_INGAME, min_value = 0, max_value = 12, step_size = 1});

        AddSetting({
            name = "subsidies_type",
            description = "Subsidies: Create subsidies for contributed towns",
            easy_value = 1,
            medium_value = 1,
            hard_value = 1,
            custom_value = 1,
            flags = CONFIG_INGAME, min_value = 0, max_value = 3});
        AddLabels("subsidies_type", {
                _0 = "None",
                _1 = "All",
                _2 = "Passenger",
                _3 = "Cargo"});

        AddSetting({
            name = "tax_enable",
            description = "Taxes: Charge companies a monthly infrastructure tax",
            easy_value = 0,
            medium_value = 0,
            hard_value = 0,
            custom_value = 0,
            flags = CONFIG_BOOLEAN | CONFIG_INGAME});

        AddSetting({
            name = "tax_rate",
            description = "Taxes: Rate per rail/road infrastructure piece",
            easy_value = 2,
            medium_value = 3,
            hard_value = 5,
            custom_value = 3,
            flags = CONFIG_INGAME, min_value = 0, max_value = 1000, step_size = 1});

        AddSetting({
            name = "tax_big_town_bonus",
            description = "Taxes: Extra percentage per contributed town over 500 population",
            easy_value = 5,
            medium_value = 5,
            hard_value = 10,
            custom_value = 5,
            flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 1});

        AddSetting({
            name = "tax_rating_discount",
            description = "Taxes: Max rating-based discount from contributed towns",
            easy_value = 30,
            medium_value = 30,
            hard_value = 30,
            custom_value = 30,
            flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 1});

        AddSetting({
            name = "tax_growth_rebate",
            description = "Taxes: Rebate per population your towns gained last month",
            easy_value = 0,
            medium_value = 0,
            hard_value = 0,
            custom_value = 0,
            flags = CONFIG_INGAME, min_value = 0, max_value = 1000, step_size = 1});

        for (local i = 1; i <= 6; i++) {
            AddSetting({
                name = "category_" + i + "_min_pop",
                description = "Category " + i + ": Minimum population demand (-1 = default)",
                easy_value = -1,
                medium_value = -1,
                hard_value = -1,
                custom_value = -1,
                flags = CONFIG_INGAME, min_value = -1, max_value = 100000, step_size = 100});
        }

        AddSetting({ name = "town_growth_factor",
                description = "Expert: town growth factor",
                easy_value = 50,
                medium_value = 100,
                hard_value = 200,
                custom_value = 100,
                flags = CONFIG_INGAME, min_value = 20, max_value = 50000, step_size = 20 });

        AddSetting({ name = "supply_impacting_part",
                description = "Expert: minimum fulfilled percentage for TGR growth",
                easy_value = 30,
                medium_value = 50,
                hard_value = 70,
                custom_value = 50,
                flags = CONFIG_INGAME, min_value = 0, max_value = 100, step_size = 5 });

        AddSetting({ name = "exponentiality_factor",
                description = "Expert: TGR growth exponentiality factor",
                easy_value = 3,
                medium_value = 3,
                hard_value = 3,
                custom_value = 3,
                flags = CONFIG_INGAME, min_value = 1, max_value = 5 });

        AddSetting({ name = "lowest_town_growth_rate",
                description = "Expert: slowest TGR if requirements are not met",
                easy_value = 365,
                medium_value = 550,
                hard_value = 880,
                custom_value = 550,
                flags = CONFIG_INGAME, min_value = 0, max_value = 880, step_size = 10 });

        AddSetting({ name = "allow_0_days_growth",
                description = "Expert: allow 0 days growth",
                easy_value = 0,
                medium_value = 0,
                hard_value = 0,
                custom_value = 0,
                flags = CONFIG_BOOLEAN | CONFIG_INGAME});

        AddSetting({ name = "log_level",
                description = "Debug: Log level (higher = print more)",
                easy_value = 1,
                medium_value = 1,
                hard_value = 1,
                custom_value = 1,
                flags = CONFIG_INGAME, min_value = 1, max_value = 3 });
        AddLabels("log_level", { _1 = "1: Info", _2 = "2: Cargo", _3 = "3: Debug" });
    }
}

RegisterGS(MainClass());
