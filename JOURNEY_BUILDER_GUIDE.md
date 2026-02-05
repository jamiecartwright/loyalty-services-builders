# Journey Builder System - AI Agent Guide

This guide explains how the journey builder system works, including database schema, relationships, and how to make updates.

## Overview

Journeys are configured primarily via **backend database tables** in `benefits-svc`. The frontend renders based on this configuration. There are two main systems:

1. **Journey Templates** - Define the steps a merchant goes through to create a journey
2. **Offer Builder Flows** - Define the steps for creating specific offer types (see `offer-builder/` folder)

---

## Database Schema

### Journey Templates Tables

```
journey_templates
├── id (PK)
├── journey_type (e.g., 'FLEXIBLE_JOURNEY', 'FIRST_TIME_GUESTS')
├── portal ('merchant')
├── name
└── description

journey_builder_flows
├── id (PK)
├── journey_template_id (FK → journey_templates)
├── title
└── description

journey_builder_flow_steps
├── id (PK)
├── flow_id (FK → journey_builder_flows)
├── step_id (FK → journey_steps)
├── step_order
├── is_required
├── badge_label (display text)
├── badge_icon
├── default_body (JSONB - description bullets)
├── body (JSONB - populated state)
├── builder_entrypoint (API endpoint or route)
├── template_type ('AUDIENCE', 'SMS_CAMPAIGN', 'OFFER')
├── template_id (FK to specific template)
├── show_merchant_selector
└── group_id (FK → journey_builder_groups)

journey_builder_groups
├── id (PK)
├── title (e.g., 'Before visit', 'During visit')
└── description
```

For Offer Builder tables, see `offer-builder/01-architecture.md`.

---

## Key Concepts

### 1. Journey Step Types

| template_type | Description |
|---------------|-------------|
| `AUDIENCE` | Filter/select target guests |
| `SMS_CAMPAIGN` | Configure messaging campaign |
| `OFFER` | Configure an offer (comped item, discount, etc.) |

### 2. builder_entrypoint

This field controls **where the step navigates** and **what data it fetches**.

**For OFFER steps:**
- Shows reward type selection: `/portal-gateway/v1/offer-builder/synthetic-reward-types?issuerType=DINING`
- Goes directly to specific offer type: `/portal-gateway/v1/offer-builder/flows?rewardTypeId={uuid}&platform={platform}&audienceType=full_journey`

**For SMS_CAMPAIGN steps:**
- Usually empty - frontend handles routing based on journey type
- Can specify: `/main/modals/journeys/{id}/messaging-campaign-type` or `/main/modals/journeys/{id}/messaging-schedule`

### 3. Offer Builder Flow Selection

When the frontend needs offer builder steps, it calls:
```
GET /portal-gateway/v1/offer-builder/flows?rewardTypeId=X&platform=mobile&audienceType=full_journey
```

This returns the steps/elements for building that specific offer type. The flow is selected by:
- `synthetic_reward_type_id` - Which offer type (comped item vs discount)
- `platform` - mobile or web
- `audience_type` - full_journey (for journeys), single_user_instant, etc.

### 4. Step Types in Offer Flows

| step_type | Used For |
|-----------|----------|
| `reward_selection` | Selecting comped item from menu |
| `reward_creation` | Configuring discount amount |
| `program_settings` | Redemption limits, duration |
| `messaging` | Checkout message (for discounts) |
| `item_messaging` | SMS when comped item delivered |
| `messaging_sms` | SMS configuration |
| `confirmation` | Review before creating |
| `success_handoff` | Success screen |

---

## Common Updates

### Update Journey Step Copy

```sql
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'New Label',
  default_body = '[{"icon": null, "order": 1, "value": "New description text"}]'::jsonb
WHERE id = 'step-uuid';
```

### Add a New Journey Step

```sql
INSERT INTO journey_builder_flow_steps
  (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon, 
   default_body, body, builder_entrypoint, template_type, template_id, 
   show_merchant_selector, group_id)
VALUES
  (
    'new-uuid',
    'flow-uuid',
    'step-type-uuid',  -- from journey_steps table
    4,  -- step order
    false,
    'Step Label',
    'icon-name-bold',
    '[{"icon": null, "order": 1, "value": "Description"}]'::jsonb,
    '[{"icon": "icon-regular", "order": 1, "value": "{variable}"}]'::jsonb,
    '/api/endpoint',
    'OFFER',
    null,
    false,
    'group-uuid'
  );
```

### Change Offer Step to Go Directly to Specific Type

```sql
-- Make step go directly to comped item (skip type selection)
UPDATE journey_builder_flow_steps
SET builder_entrypoint = '/portal-gateway/v1/offer-builder/flows?rewardTypeId=dce31367-c854-41ba-b855-541bdcfd5874&platform={platform}&audienceType=full_journey'
WHERE id = 'step-uuid';

-- Make step go directly to discount
UPDATE journey_builder_flow_steps
SET builder_entrypoint = '/portal-gateway/v1/offer-builder/flows?rewardTypeId=2d74ce67-a928-4ffd-9536-dc7d2f14ba30&platform={platform}&audienceType=full_journey'
WHERE id = 'step-uuid';
```

### Change Offer Builder Flow Step

```sql
-- Change which step type is used in a flow (e.g., item_messaging → messaging)
UPDATE offer_builder_flow_steps
SET step_id = 'new-step-uuid'
WHERE flow_id = 'flow-uuid'
  AND step_order = 3;
```

### Update Group Titles

```sql
UPDATE journey_builder_groups
SET title = 'New Group Name'
WHERE id = 'group-uuid';
```

---

## Key UUIDs Reference

### Synthetic Reward Types (DINING)
| internal_name | id |
|---------------|-----|
| dining_complimentary_item | `dce31367-c854-41ba-b855-541bdcfd5874` |
| neighborhood_discount | `2d74ce67-a928-4ffd-9536-dc7d2f14ba30` |

### Offer Builder Step Types
| step_type | id |
|-----------|-----|
| messaging | `36e0873f-d3f7-4824-9e8a-a3f14ee9efb5` |
| item_messaging | `62a9e2bb-12e5-4cea-a3b9-174204804e50` |

### Flexible Journey
| Entity | id |
|--------|-----|
| Template | `c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f` |
| Flow | `d2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a` |

### Groups
| title | id |
|-------|-----|
| Before visit | `g1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c` |
| During visit | `g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d` |
| Checkout + Post visit | `g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e` |
| Next Visit | `g4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f` |

---

## Diagnostic Queries

### Check all steps for a journey
```sql
SELECT fs.step_order, fs.badge_label, fs.template_type, fs.builder_entrypoint, fs.group_id
FROM journey_builder_flow_steps fs
JOIN journey_builder_flows f ON fs.flow_id = f.id
JOIN journey_templates jt ON f.journey_template_id = jt.id
WHERE jt.journey_type = 'FLEXIBLE_JOURNEY'
ORDER BY fs.step_order;
```

### Check offer builder flows for a reward type
```sql
SELECT f.platform, f.audience_type, fs.step_order, s.step_type, s.default_title
FROM offer_builder_flows f
JOIN offer_builder_flow_steps fs ON f.id = fs.flow_id
JOIN offer_builder_steps s ON fs.step_id = s.id
WHERE f.synthetic_reward_type_id = 'reward-type-uuid'
ORDER BY f.platform, f.audience_type, fs.step_order;
```

### Check elements in an offer flow step
```sql
SELECT f.platform, f.audience_type, fs.step_order, s.step_type,
       e.internal_name, e.internal_type, fse.element_order
FROM offer_builder_flows f
JOIN offer_builder_flow_steps fs ON f.id = fs.flow_id
JOIN offer_builder_steps s ON fs.step_id = s.id
LEFT JOIN offer_builder_flow_step_elements fse ON fs.id = fse.flow_step_id
LEFT JOIN offer_builder_elements e ON fse.element_id = e.id
WHERE f.synthetic_reward_type_id = 'reward-type-uuid'
  AND f.platform = 'mobile'
  AND f.audience_type = 'full_journey'
ORDER BY fs.step_order, fse.element_order;
```

---

## Frontend Integration

The frontend reads these configurations via API calls:
- Journey templates: `GET /merchant-portal/v2/journeys/templates`
- Offer builder reward types: `GET /portal-gateway/v1/offer-builder/synthetic-reward-types`
- Offer builder flows: `GET /portal-gateway/v1/offer-builder/flows?rewardTypeId=X&platform=Y&audienceType=Z`

The frontend code in `bilt-frontend-mobile/apps/bilt-merchant-mobile/` handles:
- Navigation between steps based on `builder_entrypoint`
- Rendering step content based on `template_type`
- Campaign type selection (visit-based vs audience-based) for `FLEXIBLE_JOURNEY`

---

## Offer Builder Integration

For creating/modifying offer builder configurations (reward types, flows, steps, elements), see:
- `offer-builder/01-architecture.md` - How offer builder works
- `offer-builder/02-adding-a-reward-type.md` - Step-by-step guide for new reward types

Key concepts for journey integration:
- Journey steps with `template_type = 'OFFER'` invoke the offer builder
- `builder_entrypoint` controls navigation to offer builder API
- Use `audience_type = 'full_journey'` for journey-aware offer flows

---

## Related Documentation

| Topic | File |
|-------|------|
| Journey Architecture | `journey-templates/01-architecture.md` |
| Adding journey templates | `journey-templates/02-adding-a-template.md` |
| Offer Builder Architecture | `offer-builder/01-architecture.md` |
| Adding reward types | `offer-builder/02-adding-a-reward-type.md` |
| Flexible journey SQL | `journey-templates/created-journey-templates/flexible-journey/`
