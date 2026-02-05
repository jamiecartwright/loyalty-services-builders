# Complimentary Rideshare Offer Builder

**Status:** Planning  
**Linear:** [MR-2505](https://linear.app/bilt/issue/MR-2505/enable-complimentary-ride-in-offer-builder)

## Overview

Enable dining merchants to offer complimentary rideshare credits to guests, either:
- **To the merchant** - Help guests arrive
- **From the merchant** - Help guests get home safely

## Documentation

| Document | Description |
|----------|-------------|
| [PRD.md](./PRD.md) | Product Requirements Document |
| [FLOW_DIAGRAMS.md](./FLOW_DIAGRAMS.md) | Visual flow diagrams for validation |

## SQL Files

| File | Description | Status |
|------|-------------|--------|
| [sql/01_schema_changes.sql](./sql/01_schema_changes.sql) | Groups table, FK, seed data | Blocked on MR-2541 |
| [sql/02_offer_builder_configuration.sql](./sql/02_offer_builder_configuration.sql) | Flows, steps, elements | Partial - needs IDs |
| [sql/03_lookup_and_complete.sql](./sql/03_lookup_and_complete.sql) | Queries to find existing IDs | Reference |

### SQL Execution Order

1. **First**: Run `01_schema_changes.sql` (requires engineering PR for new table)
2. **Then**: Run lookup queries in `03_lookup_and_complete.sql` to find existing step/element IDs
3. **Finally**: Complete and run `02_offer_builder_configuration.sql` with actual IDs

## Linear Tickets

All work is tracked under [MR-2505](https://linear.app/bilt/issue/MR-2505):

### Backend
- [MR-2541](https://linear.app/bilt/issue/MR-2541) - Create `synthetic_reward_type_groups` table
- [MR-2542](https://linear.app/bilt/issue/MR-2542) - Seed rideshare group and types
- [MR-2543](https://linear.app/bilt/issue/MR-2543) - Update API to return groups
- [MR-2544](https://linear.app/bilt/issue/MR-2544) - Create offer builder flows

### Frontend
- [MR-2545](https://linear.app/bilt/issue/MR-2545) - Handle groups in selection screen
- [MR-2546](https://linear.app/bilt/issue/MR-2546) - Conditional element visibility
- [MR-2547](https://linear.app/bilt/issue/MR-2547) - Remove "Coming Soon" state
