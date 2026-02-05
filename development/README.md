# Development - Work in Progress

This folder contains documentation and SQL for features currently in development. Once features are complete and shipped, their documentation should be moved to the appropriate stable folder (e.g., `offer-builder/`, `journey-templates/`).

## Current Development Projects

### Complimentary Rideshare Offer Builder
**Status:** Planning  
**Folder:** `complimentary-rideshare/`

Adding a new reward type for gifting rideshare credits to guests. This involves:
- New "Reward Type Groups" architecture to group multiple reward types under one selection card
- Two new reward types: "Ride to restaurant" and "Ride from restaurant"
- New offer builder flows for both types

See [complimentary-rideshare/README.md](./complimentary-rideshare/README.md) for details.

---

## Development Workflow

1. Create a subfolder for your feature
2. Add a README.md explaining the feature
3. Include:
   - Architecture/design docs
   - Draft SQL migrations
   - Implementation checklists
   - Tickets/issues to create
4. Once shipped, move stable docs to appropriate folders
