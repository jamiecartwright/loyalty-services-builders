# Journey Template Configuration Guide

This guide documents how to add and configure journey templates in the Journey Builder system. Journey templates define the blueprint for automated guest/resident engagement workflows.

## Table of Contents

| Document | Description |
|----------|-------------|
| [Architecture](./01-architecture.md) | Backend and frontend system architecture |
| [Adding a Template](./02-adding-a-template.md) | Step-by-step guide for adding new templates |
| [Configuration Reference](./03-configuration-reference.md) | Complete reference for all configurable options |
| [Frontend Integration](./04-frontend-integration.md) | Mobile app integration patterns |
| [CSV Data Entry](./csv/) | CSV templates for defining journey templates |

## CSV Data Entry

For defining new journey templates, use the CSV templates in `./csv/`:

```
csv/
├── 00-instructions.md         # How to use these files
├── FIELD-REFERENCE.md         # Complete field documentation
├── templates/                 # Blank templates to copy
│   ├── 01-journey-template.csv
│   ├── 02-builder-flow.csv
│   ├── 03-builder-flow-steps.csv
│   ├── 04-audience-template.csv
│   ├── 05-audience-rules.csv
│   ├── 06-offer-templates.csv
│   ├── 07-sms-campaign-templates.csv
│   └── 08-email-campaign-templates.csv
└── 01-08*.csv                 # Example: "Win Back Guests" template
```

**Workflow:**
1. Copy blank templates from `csv/templates/`
2. Fill in data using `FIELD-REFERENCE.md` as guide
3. Generate SQL migration from completed CSVs

## Quick Overview

### What is a Journey Template?

A journey template defines:
- **Audience** - Who receives the journey (tag-based targeting rules)
- **Offers** - What reward/experience guests receive
- **Campaigns** - How guests are notified (SMS/Email)
- **Builder Flow** - The UI steps for creating instances of this journey

### Current Journey Types

| Type | Portal | Description |
|------|--------|-------------|
| `FIRST_TIME_GUESTS` | merchant | Convert first-time guests to repeat customers |
| `LOW_REVIEW_ENGAGEMENT` | merchant | Win back guests who left negative reviews |
| `BUSINESS_ACROSS_LOCATIONS` | merchant | Drive guests to other locations |
| `NEW_LEASE` | property | Welcome new residents |
| `FIRST_THIRTY_DAYS` | property | Onboard residents in first month |
| `RESIDENT_LIFECYCLE` | property | Engage residents throughout their lease |
| `RENEWAL_REENGAGEMENT` | property | Re-engage residents nearing renewal |

### Example: Adding `FLEXIBLE_JOURNEY`

The `FLEXIBLE_JOURNEY` type demonstrates adding a fully configurable template that allows merchants to define their own audience rules, offers, and messaging. See [Adding a Template](./02-adding-a-template.md) for the complete walkthrough.

## Key Concepts

### Template vs Instance

- **Template** - Blueprint defining the journey type and default configuration
- **Instance (Journey)** - A merchant's specific journey created from a template

### Step Types

| Step Type | Description | Required |
|-----------|-------------|----------|
| `audience` | Define who receives the journey | Yes |
| `offer` | Configure the reward/experience | Yes |
| `message` | Set up SMS campaign | Depends on template |
| `email` | Set up Email campaign | Depends on template |

### Tag Rule Engine

Audience targeting uses a composable rule tree with 25+ node types:

```
Dining: VISIT_COUNT, REVIEW_RATING, SPEND_AMOUNT, BOOKING_WINDOW, etc.
Property: LEASE_STATUS, RENT_AMOUNT, TENURE, RESIDENT_LOYALTY_STATUS, etc.
General: BILT_LOYALTY_STATUS, TIMEFRAME, MERCHANT, etc.
```

## File Locations

### Backend (benefits-svc)

```
benefits-svc/app/src/main/
├── java/com/biltrewards/benefits/journeys/
│   ├── model/
│   │   ├── JourneyType.java              # Enum of journey types
│   │   ├── JourneyTemplate.java          # Template model
│   │   ├── JourneyBuilderFlow.java       # UI flow configuration
│   │   └── JourneyBuilderStep.java       # Individual step config
│   ├── JourneyService.java               # Business logic
│   ├── JourneyTemplateService.java       # Template management
│   └── api/
│       └── docs/journey-template-openapi.yaml
└── resources/db/migration/schema/benefits/spanner/common/
    ├── V105__add_journey_template_tables.sql
    ├── V109__recreate_journey_builder_tables.sql
    └── V110__backfill_reusable_journey_builder_data.sql
```

### Frontend (bilt-frontend-mobile)

```
bilt-frontend-mobile/apps/bilt-merchant-mobile/
├── app/main/
│   ├── (dashboard)/(store)/(tabs)/journeys.tsx    # Journey list
│   ├── journeys/templates/[id].tsx                 # Template details
│   └── modals/journeys/[id]/                       # Step configuration modals
├── components/journeys/
│   └── cards/
│       ├── JourneyCard.tsx
│       ├── JourneyStepCard.tsx
│       └── JourneyTemplateCard.tsx
├── hooks/api/journeys/
│   ├── useJourneys.ts
│   ├── useJourneyTemplates.ts
│   ├── useJourneyTemplateById.ts
│   └── useCreateJourney.ts
├── store/journeyStore.ts
└── types/journeys.ts
```
