---
layout: ../layouts/DocsLayout.astro
title: Settings playbook
description: "Quick guide to EVGE settings and tuning"
---

# Settings playbook

## Start with these defaults

- Leave randomization on so nearby towns get plausible local cargo goals.
- Keep normal difficulty values unless you want faster or slower expansion.
- Set taxes conservative at first, then add pressure once your network is stable.

## Core settings

- **Difficulty level** changes all cargo targets.
- **Goal monitoring** and **minimum transport percent** decide how strict growth is.
- **Monitoring timeout** controls how long a town stays monitored after it stops shipping passengers.
- **Limiter delay** controls how long a town is allowed to fail requirement checks before growth pauses.

## Cargo shape

Use the randomization type to control local variety.

- Fixed modes lock each category to a fixed amount.
- Range modes vary the amount per category.
- Industry modes bias cargo choices around local industry composition.
- The nearby probability setting controls how strongly cargo acceptance follows nearby industry.

## Taxes and subsidies

- Taxes apply on owned rail/road infrastructure.
- Growth rebate can convert last month population gain into a partial refund.
- Subsidies can be enabled to spawn useful passenger or cargo routes toward contributed towns.

## Expert values

These are safe to tweak, but they can strongly change feel:

- town growth factor
- minimum fulfilled percentage
- exponentiality factor
- slowest growth rate floor

Use the full manual for exact value ranges and compatibility notes.
