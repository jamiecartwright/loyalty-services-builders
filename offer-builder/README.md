# Offer Builder Documentation

This folder contains documentation for the Offer Builder system - a data-driven UI framework for creating offers/rewards.

## Documents

| File | Description |
|------|-------------|
| `01-architecture.md` | System overview, database schema, API endpoints |
| `02-adding-a-reward-type.md` | Step-by-step guide for adding new reward types |

## Quick Start

If you need to:
- **Understand how offer builder works** → Start with `01-architecture.md`
- **Add a new reward type** (e.g., complimentary rides) → Follow `02-adding-a-reward-type.md`
- **Modify existing flow** (change steps/elements) → See SQL patterns in `01-architecture.md`

## Related

- **Journey Builder** - Uses offer builder for `template_type = 'OFFER'` steps
- See `../journey-templates/` for journey-specific documentation
- See `../.cursor/rules/offer-builder-system.mdc` for Cursor AI context
