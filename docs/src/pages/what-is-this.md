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
    `goal_scale_factor / 100 * (1 + big_town_bonus * big_towns)`, where
    `big_towns` counts your monitored towns over 500 population.
  - A station with one or more docks is charged once.
- The bill is multiplied by the average of all contributed towns' local authority ratings.
  - With `tax_rating_discount = 30`, an excellent town rating gives ~30% off.
  - At low or missing ratings, no discount is applied.
- Population growth can also rebate part of this month's bill through `tax_growth_rebate`.

The Goal list shows total, rail/road, and dock taxes paid, plus each amount for
last month and the rebate. Its Tax history entry opens a company StoryBook page
with a 36-month history, a relative text line graph, and Older/Newer buttons.

## Invest in an area

There is no direct GameScript button for a one-time area investment action.
You get tax impact through play:

- Keep towns supplied so your rating improves.
- Grow and contribute towns to keep contributors.
- Use subsidies and infrastructure decisions to shape where growth happens.

## Taxes-paid trend

OpenTTD's GameScript API has no custom graph widget. The Tax history StoryBook
page draws a 12-month text line graph instead: each month plots a # marker on a
dotted scale, so reading down the page traces the trend. Older and Newer buttons
browse up to 36 months.
