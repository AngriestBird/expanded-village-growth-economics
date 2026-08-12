/*
 * Infrastructure tax. Each month, companies pay a tax scaled by their rail,
 * road and canal network plus their dock and airport stations, with a bonus for
 * each large town they actively serve. Better town ratings reduce taxes. The
 * money is a sink and there is no solvency check, so companies may go into debt.
 *
 * The two buckets are stored under the historic tax_rail_road_* and tax_dock_*
 * names so that savegames from 1.2.0 keep loading.
 */

/* Split a month's tax between the network and station buckets. Kept free of GS
 * API calls so tests/ can exercise the arithmetic without a running game.
 */
function CalculateTaxBill(network_base, station_base, difficulty, big_town_bonus,
                          num_big_towns, rating_multiplier, rebate_rate, growth_points)
{
    local bill = { network = 0, stations = 0, rebate = 0, total = 0 };

    local taxable = network_base + station_base;
    if (taxable <= 0)
        return bill;

    local gross = (taxable * difficulty * (1.0 + big_town_bonus * num_big_towns) * rating_multiplier).tointeger();
    if (gross <= 0)
        return bill;

    local rebate = (rebate_rate * difficulty * growth_points).tointeger();
    if (rebate < 0)
        rebate = 0;
    else if (rebate > gross)
        rebate = gross;

    local network_gross = (gross * network_base.tofloat() / taxable).tointeger();
    local station_gross = gross - network_gross;
    local network_rebate = (rebate * network_gross.tofloat() / gross).tointeger();
    local station_rebate = rebate - network_rebate;

    bill.network = network_gross - network_rebate;
    bill.stations = station_gross - station_rebate;
    bill.rebate = rebate;
    bill.total = bill.network + bill.stations;

    return bill;
}

/* Split a company's net tax between its contributed towns and convert each
 * share into town growth days. Kept free of GS API calls so tests/ can
 * exercise the arithmetic without a running game.
 */
function CalculateGrowthFunding(net_tax, town_count, boost_per_1000)
{
    if (net_tax <= 0 || town_count <= 0 || boost_per_1000 <= 0)
        return 0;

    return (net_tax.tofloat() / town_count / 1000.0 * boost_per_1000).tointeger();
}

/* Apply a tax-funded boost to a town growth rate. The boost shaves days off
 * the rate, which never drops below 1 day unless 0 day growth is allowed,
 * in which case it floors at 0. Kept free of GS API calls so tests/ can
 * exercise the arithmetic without a running game.
 */
function ApplyGrowthFunding(base_rate, funding, allow_0_days_growth)
{
    local rate = base_rate - funding;
    if (rate < 0)
        rate = 0;
    if (rate < 1 && !allow_0_days_growth)
        rate = 1;

    return rate;
}

/* GSController.GetSetting hands back -1 for a setting the running config does
 * not know, which happens for a rate added after the savegame was made. A
 * negative rate would pay the company instead of charging it.
 */
function GetTaxRateSetting(name)
{
    local value = GSController.GetSetting(name);
    return value < 0 ? 0 : value;
}

function GetTownTaxMultiplier(town_id, company_id, rating_discount)
{
    local rating_class = GSTown.GetRating(town_id, company_id);
    if (rating_class == GSTown.TOWN_RATING_NONE || rating_class == GSTown.TOWN_RATING_INVALID)
        return 1.0;

    local rating = GSTown.GetDetailedRating(town_id, company_id);
    if (rating < 0)
        rating = 0;
    else if (rating > 1000)
        rating = 1000;

    local multiplier = 1.0 - (rating.tofloat() / 1000.0) * rating_discount;
    if (multiplier < 0.0)
        multiplier = 0.0;

    return multiplier;
}

function ChargeTaxes(companies, towns_by_contributor, date)
{
    // Clear the previous month's figure first so companies not charged this month show 0
    foreach (company in companies) {
        company.tax_last_month = 0;
        company.tax_rebate_last_month = 0;
        company.tax_rail_road_last_month = 0;
        company.tax_dock_last_month = 0;
    }

    if (!GSController.GetSetting("tax_enable"))
        return;

    local tax_rate = GetTaxRateSetting("tax_rate");
    local dock_tax_rate = GetTaxRateSetting("tax_dock_rate");
    local airport_tax_rate = GetTaxRateSetting("tax_airport_rate");
    local canal_tax_rate = GetTaxRateSetting("tax_canal_rate");
    if (tax_rate <= 0 && dock_tax_rate <= 0 && airport_tax_rate <= 0 && canal_tax_rate <= 0)
        return;

    // Reuse the same difficulty knob as cargo requirements
    local difficulty = GSController.GetSetting("goal_scale_factor") / 100.0;
    local big_town_bonus = GSController.GetSetting("tax_big_town_bonus") / 100.0;
    local rating_discount = GSController.GetSetting("tax_rating_discount") / 100.0;
    local rebate_rate = GSController.GetSetting("tax_growth_rebate");
    local year = GSDate.GetYear(date);
    local month = GSDate.GetMonth(date);

    foreach (company in companies) {
        if (GSCompany.ResolveCompanyID(company.id) == GSCompany.COMPANY_INVALID)
            continue;

        // Whole-map network pieces and the terminal stations the company owns
        local infra = GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_RAIL)
                    + GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_ROAD);
        local canals = GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_CANAL);
        local docks = 0;
        local airports = 0;
        {
            local dummy = GSCompanyMode(company.id);
            docks = GSStationList(GSStation.STATION_DOCK).Count();
            airports = GSStationList(GSStation.STATION_AIRPORT).Count();
        }
        if (infra <= 0 && canals <= 0 && docks <= 0 && airports <= 0) {
            company.RecordTaxHistory(year, month, 0, 0, 0);
            continue;
        }

        // Bonus for each large town the company actively serves (monitored, above the raw-food threshold)
        local num_big_towns = 0;
        local rating_multiplier = 1.0;
        local town_rating_total = 0.0;
        local rated_towns = 0;
        local tile = GSCompany.GetCompanyHQ(company.id);
        if (towns_by_contributor.rawin(company.id)) {
            foreach (town in towns_by_contributor[company.id]) {
                if (town.is_monitored && GSTown.GetPopulation(town.id) > 500)
                    ++num_big_towns;
                town_rating_total += GetTownTaxMultiplier(town.id, company.id, rating_discount);
                ++rated_towns;
                if (!GSMap.IsValidTile(tile))
                    tile = GSTown.GetLocation(town.id);
            }

            if (rated_towns > 0)
                rating_multiplier = town_rating_total / rated_towns;
        }

        local network_base = tax_rate * infra + canal_tax_rate * canals;
        local station_base = dock_tax_rate * docks + airport_tax_rate * airports;
        local bill = CalculateTaxBill(network_base, station_base, difficulty, big_town_bonus,
                                      num_big_towns, rating_multiplier, rebate_rate,
                                      company.points_this_month);

        company.tax_rebate_last_month = bill.rebate;
        company.tax_rail_road_last_month = bill.network;
        company.tax_dock_last_month = bill.stations;
        company.tax_last_month = bill.total;
        company.RecordTaxHistory(year, month, bill.network, bill.stations, bill.rebate);
        if (bill.total <= 0)
            continue;

        GSCompany.ChangeBankBalance(company.id, -bill.total, GSCompany.EXPENSES_OTHER, tile);
        company.tax_rail_road_paid += bill.network;
        company.tax_dock_paid += bill.stations;
        company.tax_paid += bill.total;

        Log.Info(GSCompany.GetName(company.id) + " paid " + bill.total + " infrastructure tax (network: "
                 + bill.network + ", stations: " + bill.stations + ", pieces: " + infra + ", canals: "
                 + canals + ", dock stations: " + docks + ", airports: " + airports + ", big towns: "
                 + num_big_towns + ", rating: x" + rating_multiplier + ", rebate: " + bill.rebate + ")",
                 Log.LVL_DEBUG);
    }
}
