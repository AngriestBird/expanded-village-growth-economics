/*
 * Infrastructure tax. Each month, companies pay a tax scaled by their
 * total rail, road, and dock infrastructure, with a bonus for each large town
 * they actively serve. Better town ratings reduce taxes. The money is a
 * sink and there is no solvency check, so companies may go into debt.
 */

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

function ChargeTaxes(companies, towns_by_contributor)
{
    // Clear the previous month's figure first so companies not charged this month show 0
    foreach (company in companies) {
        company.tax_last_month = 0;
        company.tax_rebate_last_month = 0;
    }

    if (!GSController.GetSetting("tax_enable"))
        return;

    local tax_rate = GSController.GetSetting("tax_rate");
    local dock_tax_rate = GSController.GetSetting("tax_dock_rate");
    if (tax_rate <= 0 && dock_tax_rate <= 0)
        return;

    // Reuse the same difficulty knob as cargo requirements
    local difficulty = GSController.GetSetting("goal_scale_factor") / 100.0;
    local big_town_bonus = GSController.GetSetting("tax_big_town_bonus") / 100.0;
    local rating_discount = GSController.GetSetting("tax_rating_discount") / 100.0;
    local rebate_rate = GSController.GetSetting("tax_growth_rebate");

    foreach (company in companies) {
        if (GSCompany.ResolveCompanyID(company.id) == GSCompany.COMPANY_INVALID)
            continue;

        // Whole-map rail + road infrastructure and dock stations the company owns
        local infra = GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_RAIL)
                    + GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_ROAD);
        local docks = 0;
        {
            local dummy = GSCompanyMode(company.id);
            docks = GSStationList(GSStation.STATION_DOCK).Count();
        }
        if (infra <= 0 && docks <= 0)
            continue;

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

        local infrastructure_tax = tax_rate * infra + dock_tax_rate * docks;
        local gross_tax = (infrastructure_tax * difficulty * (1.0 + big_town_bonus * num_big_towns) * rating_multiplier).tointeger();
        local rebate = (rebate_rate * difficulty * company.points_this_month).tointeger();
        if (rebate > gross_tax)
            rebate = gross_tax;
        company.tax_rebate_last_month = rebate;
        local tax = gross_tax - rebate;
        if (tax <= 0)
            continue;

        GSCompany.ChangeBankBalance(company.id, -tax, GSCompany.EXPENSES_PROPERTY, tile);
        company.AddTaxPaid(tax);
        company.tax_last_month = tax;

        Log.Info(GSCompany.GetName(company.id) + " paid " + tax + " infrastructure tax (pieces: "
                 + infra + ", docks: " + docks + ", big towns: " + num_big_towns + ", rating: x"
                 + rating_multiplier + ", rebate: " + rebate + ")", Log.LVL_DEBUG);
    }
}
