---
layout: ../layouts/DocsLayout.astro
title: Town growth mechanics
description: "How EVGE decides when and how fast towns grow"
---

# Town growth mechanics

## Core flow

- Towns are monitored only after passengers are delivered from that town.
- Every in-game month, EVGE checks each monitored town and calculates cargo goals.
- Cargo goals scale by population and by the current difficulty setting.
- Supplied cargo is compared against the goal for each category.
- Surplus cargo can carry over into next month as stockpile.
- A per-town growth rate is computed from fulfilled demand and then smoothed over recent months.

## Demand categories

Every supported economy defines cargo categories. For a new town, only the earliest categories are active. More categories unlock as population grows.

Categories can be randomized in different modes so nearby industries can be emphasized.

## Why some towns do not grow

- If passengers from a town stop for too long, the town leaves monitoring unless you increase the monitoring timeout setting.
- If the limiter setting is enabled, towns below the transport target can be blocked for a while before growth is fully paused.
- If category demand is not met, growth drops toward the slowest allowed rate but does not instantly die.

## Limiter and contributor

The active company that supplies the most useful cargo mix for a town is marked as the contributor. That value is shown in town boxes and used by tax and subsidy systems.

The limiter checks shipped cargo percentages for essential cargoes and only pauses growth after sustained under-delivery for the configured delay window.

## Growth pacing window

The script keeps a short moving average of recent growth rates so changes are smoother over time. The average only uses meaningful history slots and keeps a fixed-length window.
