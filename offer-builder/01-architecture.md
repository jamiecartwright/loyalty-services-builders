# Offer Builder Architecture

This document describes the architecture of the Offer Builder system in benefits-svc.

## Overview

The Offer Builder is a **data-driven UI system** that renders forms for creating offers/rewards. It operates independently of Journey Builder but can be embedded within journeys.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Offer Builder Data Flow                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  synthetic_reward_types → offer_builder_flows → steps → elements    │
│       (what)                  (how)             (screens) (inputs)  │
│                                                                     │
│  Example: "Complimentary Item" → mobile/full_journey flow →         │
│           reward_selection step → menu item picker element          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Core Concepts

### Synthetic Reward Types
Define WHAT kind of reward can be created. Each type maps to a business concept:

| internal_name | Description | value_type | bilt_category |
|---------------|-------------|------------|---------------|
| `dining_complimentary_item` | Free menu item | `REDEEM_DOLLAR_CREDIT` | `DINING` |
| `neighborhood_discount` | % or $ discount | `EARN_DOLLAR_CREDIT` | `DINING` |
| `complimentary_rideshare_credit` | Ride credit | `REDEEM_DOLLAR_CREDIT` | `RIDESHARE` |
| `home_incentive_bundled_reward` | Property reward | `EARN_DOLLAR_CREDIT` | `HOME` |
| `home_incentive_earn_points` | Points reward | `EARN_POINTS` | `HOME` |

### Offer Builder Flows
Define HOW a reward type is configured for a specific context:
- **platform**: `mobile`, `web`
- **audience_type**: `full` (standalone), `full_journey` (within journey), `single_user_instant`, `single_user_deferred`

### Steps
Define the SCREENS in the offer creation flow:
- `reward_selection` - Pick item from menu
- `reward_creation` - Configure discount amount
- `program_settings` - Limits, duration
- `messaging` - Checkout message
- `item_messaging` - SMS for item delivery
- `confirmation` - Review before creating
- `success_handoff` - Success screen

### Elements
Define the INPUTS within each step:
- `switch` - Toggle options
- `number` - Numeric input
- `text`, `text_box` - Text input
- `select` - Dropdown
- `datetime` - Date picker
- `display_block` - Info display
- `button` - Action

## Database Schema

### Entity Relationship

```
┌────────────────────────┐
│ synthetic_reward_types │ ─────────────────────────┐
│   ├─ id                │                          │
│   ├─ internal_name     │                          │
│   ├─ external_label    │                          │
│   ├─ value_type        │                          │
│   ├─ bilt_category     │                          │
│   ├─ issuer_type       │ (DINING, HOME, RIDESHARE)│
│   ├─ is_enabled        │                          │
│   └─ display_rank      │                          │
└────────────────────────┘                          │
                                                    │
┌────────────────────────┐                          │
│  offer_builder_flows   │ ◀────────────────────────┘
│   ├─ id                │        synthetic_reward_type_id
│   ├─ synthetic_reward_ │
│   │   type_id          │
│   ├─ platform          │ (mobile, web)
│   └─ audience_type     │ (full, full_journey, single_user_*)
└──────────┬─────────────┘
           │ 1:N
           ▼
┌────────────────────────────┐      ┌────────────────────────┐
│ offer_builder_flow_steps   │ ───▶ │   offer_builder_steps  │
│   ├─ id                    │  N:1 │   ├─ id                │
│   ├─ flow_id               │      │   ├─ step_type         │
│   ├─ step_id ──────────────│──────│   └─ default_title     │
│   ├─ step_order            │      └────────────────────────┘
│   ├─ is_required           │
│   ├─ is_skip_allowed       │
│   └─ is_visible            │
└──────────┬─────────────────┘
           │ 1:N
           ▼
┌───────────────────────────────┐      ┌─────────────────────────┐
│ offer_builder_flow_step_      │ ───▶ │  offer_builder_elements │
│         elements              │  N:1 │   ├─ id                  │
│   ├─ id                       │      │   ├─ internal_name       │
│   ├─ flow_step_id             │      │   ├─ internal_type       │
│   ├─ element_id ──────────────│──────│   └─ default_label       │
│   ├─ element_order            │      └─────────────────────────┘
│   ├─ is_required              │
│   ├─ is_visible               │
│   ├─ default_value            │
│   └─ section                  │
└───────────────────────────────┘
                                       ┌───────────────────────────┐
                                       │ offer_builder_element_    │
                                       │         options           │
                                       │   ├─ id                   │
                                       │   ├─ element_id           │
                                       │   ├─ option_value         │
                                       │   ├─ option_order         │
                                       │   ├─ default_label        │
                                       │   └─ icon                 │
                                       └───────────────────────────┘
```

## API Endpoints

### Get Available Reward Types
```
GET /portal-gateway/v1/offer-builder/synthetic-reward-types?issuerType=DINING
```
Returns all enabled reward types for the issuer type. Frontend uses this to show reward type selection.

### Get Flow for Reward Type
```
GET /portal-gateway/v1/offer-builder/flows?rewardTypeId={uuid}&platform={platform}&audienceType={audienceType}
```
Returns the complete flow configuration with steps and elements. Frontend uses this to render the form.

## Backend Services

### OfferBuilderService
```java
// Get reward types for selection screen
SyntheticRewardTypesResponse getSyntheticRewardTypes(String issuerType)

// Get flow configuration for form rendering
OfferBuilderFlow getOfferBuilderFlow(UUID syntheticRewardTypeId, String platform, String audienceType)
```

### SyntheticRewardTypeRepository
- `getAllSyntheticRewards(issuerType)` - Filtered by `issuer_type` column
- Reward types are sorted by `display_rank`
- Only returns types where `is_enabled = true`

## Relationship with Journey Builder

Journey Builder references Offer Builder via:

1. **`builder_entrypoint` in `journey_builder_flow_steps`**:
   - Generic: `/portal-gateway/v1/offer-builder/synthetic-reward-types?issuerType=DINING` → user selects type
   - Specific: `/portal-gateway/v1/offer-builder/flows?rewardTypeId={uuid}&platform={platform}&audienceType=full_journey` → direct to specific builder

2. **`template_type = 'OFFER'`** in journey flow steps indicates this step creates an offer

3. **`audience_type = 'full_journey'`** in offer builder flows indicates the flow is designed for journey context (may have skip buttons, journey-specific guidance)

## Value Types and Categories

### value_type (how the reward is applied)
| Value | Meaning |
|-------|---------|
| `REDEEM_DOLLAR_CREDIT` | Guest redeems a dollar-value credit |
| `EARN_DOLLAR_CREDIT` | Guest earns credit on purchase |
| `EARN_POINTS` | Guest earns Bilt points |

### bilt_category (business domain)
| Value | Meaning |
|-------|---------|
| `DINING` | Restaurant/merchant rewards |
| `HOME` | Property/rent rewards |
| `RIDESHARE` | Transportation rewards |

### issuer_type (who creates offers)
| Value | Meaning |
|-------|---------|
| `DINING` | Merchants create dining offers |
| `HOME` | Properties create resident offers |
| `RIDESHARE` | Partners create ride offers |

## Frontend Integration

The mobile app (`bilt-frontend-mobile/apps/bilt-merchant-mobile/`) handles:

1. **Reward Type Selection** (`offer-select-type.tsx`)
   - Calls `GET /synthetic-reward-types`
   - Shows cards for each enabled type
   - User selects → navigates to flow

2. **Flow Rendering** (`offer-builder.tsx`)
   - Calls `GET /flows` with selected type
   - Renders steps in order
   - Each step shows its elements
   - Handles navigation between steps

3. **Element Rendering**
   - Maps `internal_type` to React Native components
   - Handles validation based on `is_required`
   - Populates defaults from `default_value`
