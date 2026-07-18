/*
 * Infrastructure tax. Each month, companies pay a tax scaled by their
 * total rail and road infrastructure, with a bonus for each large town
 * they actively serve. The money is a sink and there is no solvency
 * check, so companies may go into debt.
 */

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
    if (tax_rate <= 0)
        return;

    // Reuse the same difficulty knob as cargo requirements
    local difficulty = GSController.GetSetting("goal_scale_factor") / 100.0;
    local big_town_bonus = GSController.GetSetting("tax_big_town_bonus") / 100.0;
    local rebate_rate = GSController.GetSetting("tax_growth_rebate");

    foreach (company in companies) {
        if (GSCompany.ResolveCompanyID(company.id) == GSCompany.COMPANY_INVALID)
            continue;

        // Whole-map rail + road infrastructure the company owns
        local infra = GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_RAIL)
                    + GSInfrastructure.GetInfrastructurePieceCount(company.id, GSInfrastructure.INFRASTRUCTURE_ROAD);
        if (infra <= 0)
            continue;

        // Bonus for each large town the company actively serves (monitored, above the raw-food threshold)
        local num_big_towns = 0;
        local tile = GSCompany.GetCompanyHQ(company.id);
        if (towns_by_contributor.rawin(company.id)) {
            foreach (town in towns_by_contributor[company.id]) {
                if (town.is_monitored && GSTown.GetPopulation(town.id) > 500)
                    ++num_big_towns;
                if (!GSMap.IsValidTile(tile))
                    tile = GSTown.GetLocation(town.id);
            }
        }

        local gross_tax = (tax_rate * difficulty * infra * (1.0 + big_town_bonus * num_big_towns)).tointeger();
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
                 + infra + ", big towns: " + num_big_towns + ", rebate: " + rebate + ")", Log.LVL_DEBUG);
    }
}
