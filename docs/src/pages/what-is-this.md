---
layout: ../layouts/DocsLayout.astro
title: What is this?
description: "Expanded Village Growth + Economics taxation and town investment notes"
---

# What is this?

This script has two tax-related mechanics you can tune in Advanced Game Settings.

## Taxes

- Base infrastructure tax is charged on rail and road pieces, plus dock stations.
  - Formula: `(tax_rate * (rail + road) + tax_dock_rate * docks) *`
    `goal_scale_factor / 100 * (1 + big_town_bonus * contributed_towns)`.
  - A station with one or more docks is charged once.
- The bill is multiplied by the average of all contributed towns' local authority ratings.
  - With `tax_rating_discount = 30`, an excellent town rating gives ~30% off.
  - At low or missing ratings, no discount is applied.
- Population growth can also rebate part of this month's bill through `tax_growth_rebate`.

The script writes all of this to Goal stats as:

- Infrastructure taxes paid
- Infrastructure tax last month
- Infrastructure tax rebate last month

## Invest in an area

There is no direct GameScript button for a one-time area investment action.
You get tax impact through play:

- Keep towns supplied so your rating improves.
- Grow and contribute towns to keep contributors.
- Use subsidies and infrastructure decisions to shape where growth happens.

## Taxes-paid trend

OpenTTD's GameScript goal target types do not expose custom graph widgets.
There is no native taxes-paid graph in this script right now.
Use the monthly values in Goal stats for trend tracking, or export your own notes in separate tools if you need charts.
