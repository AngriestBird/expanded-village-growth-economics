enum Statistics
{
    GROWTH_POINTS,
    BIGGEST_TOWN,
    FASTEST_GROWING_TOWN,
    AVERAGE_CATEGORY,
    NUM_TOWNS,
    NUM_NOT_GROWING_TOWNS,
    TAX_PAID,
    TAX_PAID_LAST_MONTH,
    TAX_REBATE_LAST_MONTH,
    TAX_RAIL_ROAD_PAID,
    TAX_DOCK_PAID,
    TAX_RAIL_ROAD_LAST_MONTH,
    TAX_DOCK_LAST_MONTH,
    TAX_HISTORY,
    END
}

class Company
{
    id = null;              // company id
    points = null;          // achieved points from growing towns
    tax_paid = null;        // cumulative infrastructure tax paid
    tax_last_month = null;  // infrastructure tax charged in the most recent month
    tax_rebate_last_month = null; // infrastructure tax rebate in the most recent month
    tax_rail_road_paid = null;
    tax_dock_paid = null;
    tax_rail_road_last_month = null;
    tax_dock_last_month = null;
    tax_history = null;
    points_this_month = null; // population gained by contributed towns this month
    statistics = null;      // contains texts for statistics in goal gui
    global_goal = null;     // global goal showing achieved points in the goal gui
    sp_welcome = null;      // story page welcome
    sp_tax_history = null;
    tax_history_offset = null;
    tax_history_previous_button = null;
    tax_history_next_button = null;

    constructor(id, load_data)
    {
        this.id = id;
        this.sp_tax_history = null;
        this.tax_history_offset = 0;
        this.tax_history_previous_button = -1;
        this.tax_history_next_button = -1;

        if (!load_data)
        {
            this.points = 0;
            this.tax_paid = 0;
            this.tax_last_month = 0;
            this.tax_rebate_last_month = 0;
            this.tax_rail_road_paid = 0;
            this.tax_dock_paid = 0;
            this.tax_rail_road_last_month = 0;
            this.tax_dock_last_month = 0;
            this.tax_history = [];
            this.points_this_month = 0;
            this.InitGUIGoals();
        }
        else
        {
            local company_data = ::CompanyDataTable[this.id];
            this.points = company_data.points;
            this.tax_paid = company_data.rawin("tax_paid") ? company_data.tax_paid : 0;
            this.tax_last_month = company_data.rawin("tax_last_month") ? company_data.tax_last_month : 0;
            this.tax_rebate_last_month = company_data.rawin("tax_rebate_last_month") ? company_data.tax_rebate_last_month : 0;
            this.tax_rail_road_paid = company_data.rawin("tax_rail_road_paid") ? company_data.tax_rail_road_paid : 0;
            this.tax_dock_paid = company_data.rawin("tax_dock_paid") ? company_data.tax_dock_paid : 0;
            this.tax_rail_road_last_month = company_data.rawin("tax_rail_road_last_month") ? company_data.tax_rail_road_last_month : 0;
            this.tax_dock_last_month = company_data.rawin("tax_dock_last_month") ? company_data.tax_dock_last_month : 0;
            this.tax_history = company_data.rawin("tax_history") ? company_data.tax_history : [];
            this.points_this_month = company_data.rawin("points_this_month") ? company_data.points_this_month : 0;
            this.global_goal = company_data.global_goal;
            this.statistics = company_data.statistics;
            // Older saves predate newer statistics slots; pad so they can be created lazily instead of indexing out of range
            while (this.statistics.len() < Statistics.END)
                this.statistics.append(-1);
        }
    }
}

function Company::SavingCompanyData()
{
    local company_data = {};
    company_data.points <- this.points;
    company_data.tax_paid <- this.tax_paid;
    company_data.tax_last_month <- this.tax_last_month;
    company_data.tax_rebate_last_month <- this.tax_rebate_last_month;
    company_data.tax_rail_road_paid <- this.tax_rail_road_paid;
    company_data.tax_dock_paid <- this.tax_dock_paid;
    company_data.tax_rail_road_last_month <- this.tax_rail_road_last_month;
    company_data.tax_dock_last_month <- this.tax_dock_last_month;
    company_data.tax_history <- this.tax_history;
    company_data.points_this_month <- this.points_this_month;
    company_data.global_goal <- this.global_goal;
    company_data.statistics <- this.statistics;

    return company_data;
}

function Company::InitGUIGoals()
{
    // In multiplayer, pause level cannot be changed, so skip initialization of Goals GUI
    local pause_level = GSGameSettings.GetValue("construction.command_pause_level");
    if (GSGame.IsPaused() && GSGame.IsMultiplayer() && pause_level < 1)
        return false;

    // If it is not set, temporarily allow all non-construction actions during pause
    if (pause_level < 1)
        GSGameSettings.SetValue("construction.command_pause_level", 1);

    // global goal
    this.global_goal = GSGoal.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STATISTICS_GROWTH_POINTS, GetColorText(this.id), this.id), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.global_goal, GSText(GSText.STR_NUM, this.points));

    // statistics
    this.statistics = array(Statistics.END, -1);

    this.statistics[Statistics.GROWTH_POINTS] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_GROWTH_POINTS, GetColorText(this.id), this.id), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.GROWTH_POINTS], GSText(GSText.STR_NUM, this.points));

    this.statistics[Statistics.AVERAGE_CATEGORY] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_AVERAGE_CATEGORY), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.AVERAGE_CATEGORY], GSText(GSText.STR_COMMA, 0));

    this.statistics[Statistics.NUM_TOWNS] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_NUM_TOWNS), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.NUM_TOWNS], GSText(GSText.STR_NUM, 0));

    this.statistics[Statistics.NUM_NOT_GROWING_TOWNS] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_NOT_GROWING), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.NUM_NOT_GROWING_TOWNS], GSText(GSText.STR_NUM, 0));

    this.statistics[Statistics.TAX_PAID] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_PAID), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_PAID], GSText(GSText.STR_CURRENCY, this.tax_paid));

    this.statistics[Statistics.TAX_PAID_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_LAST_MONTH), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_PAID_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_last_month));

    this.statistics[Statistics.TAX_REBATE_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_REBATE), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_REBATE_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_rebate_last_month));

    this.statistics[Statistics.TAX_RAIL_ROAD_PAID] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_RAIL_ROAD_PAID), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_RAIL_ROAD_PAID], GSText(GSText.STR_CURRENCY, this.tax_rail_road_paid));

    this.statistics[Statistics.TAX_DOCK_PAID] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_DOCK_PAID), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_DOCK_PAID], GSText(GSText.STR_CURRENCY, this.tax_dock_paid));

    this.statistics[Statistics.TAX_RAIL_ROAD_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_RAIL_ROAD_LAST_MONTH), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_RAIL_ROAD_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_rail_road_last_month));

    this.statistics[Statistics.TAX_DOCK_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_DOCK_LAST_MONTH), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_DOCK_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_dock_last_month));

    this.statistics[Statistics.TAX_HISTORY] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_HISTORY), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_HISTORY], GSText(GSText.STR_STATISTICS_TAX_HISTORY_OPEN));

    // Reset to previous settings
    GSGameSettings.SetValue("construction.command_pause_level", pause_level);

    return true;
}

function Company::RemoveGUIGoals()
{
    // global goal
    GSGoal.Remove(this.global_goal);
}

function Company::AddPoints(points)
{
    local gain = points > 0 ? points : 0;
    this.points += gain;
    this.points_this_month += gain;
}

function Company::AddTaxPaid(rail_road, docks)
{
    this.tax_rail_road_paid += rail_road > 0 ? rail_road : 0;
    this.tax_dock_paid += docks > 0 ? docks : 0;
    this.tax_paid += rail_road + docks;
}

function Company::RecordTaxHistory(year, month, rail_road, docks, rebate)
{
    this.tax_history.append({
        year = year,
        month = month,
        rail_road = rail_road,
        docks = docks,
        rebate = rebate,
        total = rail_road + docks
    });

    if (this.tax_history.len() > 36)
        this.tax_history.remove(0);
}

function Company::MonthlyUpdateGUIGoals(towns)
{
    // Check if Goals GUI is initialized and can be initialized
    if (this.statistics == null || this.global_goal == null) {
        if (!this.InitGUIGoals()) {
            return;
        }
    }

    local biggest_town = -1;
    local biggest_town_population = 0;
    local fastest_growth_town = -1;
    local fastest_growth = 1000;
    local average_category_total = 0;
    local num_towns = 0;
    local num_not_growing_towns = 0;

    foreach (town in towns) {
        local population = GSTown.GetPopulation(town.id);
        if (population > biggest_town_population) {
            biggest_town_population = population;
            biggest_town = town.id;
        }

        if (town.tgr_average != null && town.tgr_average > 0 && town.tgr_average < fastest_growth && town.allowGrowth) {
            fastest_growth = town.tgr_average;
            fastest_growth_town = town.id;
        }

        local max_cat = 0;
        while (max_cat < ::CargoCatNum-1) {
            if (town.town_goals_cat[max_cat + 1] == 0) break;
            max_cat++;
        }
        average_category_total += max_cat + 1;

        ++num_towns;
        if (!town.allowGrowth)
            ++num_not_growing_towns;
    }

    // Global
    GSGoal.SetText(this.global_goal, GSText(GSText.STR_STATISTICS_GROWTH_POINTS, GetColorText(this.id), this.id));
    GSGoal.SetProgress(this.global_goal, GSText(GSText.STR_NUM, this.points));

    // Statistics
    GSGoal.SetText(this.statistics[Statistics.GROWTH_POINTS], GSText(GSText.STR_STATISTICS_GROWTH_POINTS, GetColorText(this.id), this.id));
    GSGoal.SetProgress(this.statistics[Statistics.GROWTH_POINTS], GSText(GSText.STR_NUM, this.points));

    if (GSTown.IsValidTown(biggest_town)) {
        if (!GSGoal.IsValidGoal(this.statistics[Statistics.BIGGEST_TOWN]))
            this.statistics[Statistics.BIGGEST_TOWN] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_BIGGEST_TOWN, biggest_town), GSGoal.GT_NONE, 0);
        else
            GSGoal.SetText(this.statistics[Statistics.BIGGEST_TOWN], GSText(GSText.STR_STATISTICS_BIGGEST_TOWN, biggest_town));
        GSGoal.SetProgress(this.statistics[Statistics.BIGGEST_TOWN], GSText(GSText.STR_NUM, biggest_town_population));
    }
    else if (GSGoal.IsValidGoal(this.statistics[Statistics.BIGGEST_TOWN])) {
        GSGoal.Remove(this.statistics[Statistics.BIGGEST_TOWN]);
        this.statistics[Statistics.BIGGEST_TOWN] = -1;
    }

    if (GSTown.IsValidTown(fastest_growth_town)) {
        if (!GSGoal.IsValidGoal(this.statistics[Statistics.FASTEST_GROWING_TOWN]))
            this.statistics[Statistics.FASTEST_GROWING_TOWN] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_GROWTH_TOWN, fastest_growth_town), GSGoal.GT_NONE, 0);
        else
            GSGoal.SetText(this.statistics[Statistics.FASTEST_GROWING_TOWN], GSText(GSText.STR_STATISTICS_GROWTH_TOWN, fastest_growth_town));
        GSGoal.SetProgress(this.statistics[Statistics.FASTEST_GROWING_TOWN], GSText(GSText.STR_NUM, fastest_growth));
    }
    else if (GSGoal.IsValidGoal(this.statistics[Statistics.FASTEST_GROWING_TOWN])) {
        GSGoal.Remove(this.statistics[Statistics.FASTEST_GROWING_TOWN]);
        this.statistics[Statistics.FASTEST_GROWING_TOWN] = -1;
    }

    local average_category = num_towns > 0 ? (average_category_total.tofloat() / num_towns * 1000).tointeger() : 0;
    GSGoal.SetProgress(this.statistics[Statistics.AVERAGE_CATEGORY], GSText(GSText.STR_COMMA, average_category));
    GSGoal.SetProgress(this.statistics[Statistics.NUM_TOWNS], GSText(GSText.STR_NUM, num_towns));
    GSGoal.SetProgress(this.statistics[Statistics.NUM_NOT_GROWING_TOWNS], GSText(GSText.STR_NUM, num_not_growing_towns));
    GSGoal.SetProgress(this.statistics[Statistics.TAX_PAID], GSText(GSText.STR_CURRENCY, this.tax_paid));

    // Created lazily so saves that predate this stat get the row on their first month tick
    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_PAID_LAST_MONTH]))
        this.statistics[Statistics.TAX_PAID_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_LAST_MONTH), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_PAID_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_last_month));

    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_REBATE_LAST_MONTH]))
        this.statistics[Statistics.TAX_REBATE_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_REBATE), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_REBATE_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_rebate_last_month));

    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_RAIL_ROAD_PAID]))
        this.statistics[Statistics.TAX_RAIL_ROAD_PAID] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_RAIL_ROAD_PAID), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_RAIL_ROAD_PAID], GSText(GSText.STR_CURRENCY, this.tax_rail_road_paid));

    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_DOCK_PAID]))
        this.statistics[Statistics.TAX_DOCK_PAID] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_DOCK_PAID), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_DOCK_PAID], GSText(GSText.STR_CURRENCY, this.tax_dock_paid));

    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_RAIL_ROAD_LAST_MONTH]))
        this.statistics[Statistics.TAX_RAIL_ROAD_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_RAIL_ROAD_LAST_MONTH), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_RAIL_ROAD_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_rail_road_last_month));

    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_DOCK_LAST_MONTH]))
        this.statistics[Statistics.TAX_DOCK_LAST_MONTH] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_DOCK_LAST_MONTH), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_DOCK_LAST_MONTH], GSText(GSText.STR_CURRENCY, this.tax_dock_last_month));

    if (!GSGoal.IsValidGoal(this.statistics[Statistics.TAX_HISTORY]))
        this.statistics[Statistics.TAX_HISTORY] = GSGoal.New(this.id, GSText(GSText.STR_STATISTICS_TAX_HISTORY), GSGoal.GT_NONE, 0);
    GSGoal.SetProgress(this.statistics[Statistics.TAX_HISTORY], GSText(GSText.STR_STATISTICS_TAX_HISTORY_OPEN));
    if (this.sp_tax_history != null && GSStoryPage.IsValidStoryPage(this.sp_tax_history))
        GSGoal.SetDestination(this.statistics[Statistics.TAX_HISTORY], GSGoal.GT_STORY_PAGE, this.sp_tax_history);
}

function GetColorText(company_id)
{
    if (GSCompany.ResolveCompanyID(company_id) == GSCompany.COMPANY_INVALID)
        return GSText(GSText.STR_SILVER);

    local dummy = GSCompanyMode(company_id);
    local color = GSCompany.GetPrimaryLiveryColour(GSCompany.LS_DEFAULT);
    switch (color)
    {
        case GSCompany.COLOUR_DARK_BLUE:
            return GSText(GSText.STR_DARK_BLUE);
        case GSCompany.COLOUR_PALE_GREEN:
            return GSText(GSText.STR_PALE_GREEN);
        case GSCompany.COLOUR_PINK:
            return GSText(GSText.STR_PINK);
        case GSCompany.COLOUR_YELLOW:
            return GSText(GSText.STR_YELLOW);
        case GSCompany.COLOUR_RED:
            return GSText(GSText.STR_RED);
        case GSCompany.COLOUR_LIGHT_BLUE:
            return GSText(GSText.STR_LIGHT_BLUE);
        case GSCompany.COLOUR_GREEN:
            return GSText(GSText.STR_GREEN);
        case GSCompany.COLOUR_DARK_GREEN:
            return GSText(GSText.STR_DARK_GREEN);
        case GSCompany.COLOUR_BLUE:
            return GSText(GSText.STR_BLUE);
        case GSCompany.COLOUR_CREAM:
            return GSText(GSText.STR_CREAM);
        case GSCompany.COLOUR_MAUVE:
            return GSText(GSText.STR_MAUVE);
        case GSCompany.COLOUR_PURPLE:
            return GSText(GSText.STR_PURPLE);
        case GSCompany.COLOUR_ORANGE:
            return GSText(GSText.STR_ORANGE);
        case GSCompany.COLOUR_BROWN:
            return GSText(GSText.STR_BROWN);
        case GSCompany.COLOUR_GREY:
            return GSText(GSText.STR_GREY);
        case GSCompany.COLOUR_WHITE:
            return GSText(GSText.STR_WHITE);
        default:
            return GSText(GSText.STR_SILVER);
    }
}