# Adding a New Reward Type

This guide walks through adding a completely new synthetic reward type with its offer builder flows.

## Overview

Adding a new reward type involves:

1. **Database**: Create the reward type in `synthetic_reward_types`
2. **Database**: Create flows for each platform × audience_type combination
3. **Database**: Link steps to flows
4. **Database**: Link elements to flow steps
5. **Backend**: Usually no code changes (unless new value_type/category)
6. **Frontend**: Usually no code changes (unless new element types)

## Example: Adding Complimentary Rides

Let's add offer builder support for the existing `complimentary_rideshare_credit` reward type.

### Step 1: Verify/Create Synthetic Reward Type

First, check if the type exists:
```sql
SELECT id, internal_name, value_type, bilt_category, issuer_type, is_enabled
FROM synthetic_reward_types
WHERE internal_name = 'complimentary_rideshare_credit';
```

If it doesn't exist or needs updates:
```sql
INSERT INTO synthetic_reward_types (
    id,
    internal_name,
    external_label,
    description,
    icon,
    value_type,
    bilt_category,
    value_format,
    currency,
    issuer_type,
    is_enabled,
    display_rank
) VALUES (
    '5828f406-c7fe-4125-ab3b-d594a8d0a0a7',
    'complimentary_rideshare_credit',
    'Complimentary Ride',
    'Offer guests a complimentary ride credit',
    'car-front-regular',
    'REDEEM_DOLLAR_CREDIT',
    'RIDESHARE',
    'FLAT',
    'DOLLARS',
    'RIDESHARE',  -- issuer_type for filtering
    true,
    1
);
```

### Step 2: Identify Required Flows

Determine which contexts need flows:

| platform | audience_type | Use Case |
|----------|---------------|----------|
| `mobile` | `full` | Standalone offer creation |
| `mobile` | `full_journey` | Within a journey |
| `mobile` | `single_user_instant` | Instant single-user offer |
| `mobile` | `single_user_deferred` | Deferred single-user offer |
| `web` | `full` | Web standalone creation |
| `web` | `full_journey` | Web journey context |

For a dining-style complimentary ride, you likely need at minimum:
- `mobile` + `full_journey` (for journey integration)
- `mobile` + `full` (for standalone)

### Step 3: Design the Flow Steps

For complimentary rides, the flow might be:

| Order | Step Type | Purpose |
|-------|-----------|---------|
| 1 | `reward_creation` | Configure ride credit amount |
| 2 | `program_settings` | Limits, duration |
| 3 | `messaging` | Optional checkout message |
| 4 | `confirmation` | Review (standalone only) |
| 5 | `success_handoff` | Success (standalone only) |

### Step 4: Create the SQL Migration

```sql
-- ============================================================
-- Complimentary Rideshare Credit - Offer Builder Flows
-- ============================================================

-- Variable for the reward type ID
-- (Use actual UUID from synthetic_reward_types)
-- complimentary_rideshare_credit: 5828f406-c7fe-4125-ab3b-d594a8d0a0a7

-- ============================================================
-- Flow 1: mobile + full_journey
-- ============================================================
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES (
    'f1-ride-mobile-journey',  -- Replace with real UUID
    '5828f406-c7fe-4125-ab3b-d594a8d0a0a7',
    'mobile',
    'full_journey'
);

-- Flow steps for mobile + full_journey
-- Note: Journey flows typically don't have confirmation/success steps
INSERT INTO offer_builder_flow_steps 
    (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES
    -- Step 1: Configure credit amount
    ('fs1-ride-mj', 'f1-ride-mobile-journey', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'reward_creation'), 
     1, true, true, true, true),
    
    -- Step 2: Program settings
    ('fs2-ride-mj', 'f1-ride-mobile-journey', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'program_settings'), 
     2, true, true, true, true),
    
    -- Step 3: Messaging (optional in journeys)
    ('fs3-ride-mj', 'f1-ride-mobile-journey', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'messaging'), 
     3, false, true, true, true);

-- ============================================================
-- Flow 2: mobile + full (standalone)
-- ============================================================
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES (
    'f2-ride-mobile-full',  -- Replace with real UUID
    '5828f406-c7fe-4125-ab3b-d594a8d0a0a7',
    'mobile',
    'full'
);

-- Flow steps for mobile + full
INSERT INTO offer_builder_flow_steps 
    (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES
    -- Step 1: Configure credit amount
    ('fs1-ride-mf', 'f2-ride-mobile-full', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'reward_creation'), 
     1, true, false, true, true),
    
    -- Step 2: Audience (who can receive)
    ('fs2-ride-mf', 'f2-ride-mobile-full', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition'), 
     2, true, false, true, true),
    
    -- Step 3: Program settings
    ('fs3-ride-mf', 'f2-ride-mobile-full', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'program_settings'), 
     3, true, false, true, true),
    
    -- Step 4: Messaging
    ('fs4-ride-mf', 'f2-ride-mobile-full', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'messaging'), 
     4, false, false, true, true),
    
    -- Step 5: Confirmation
    ('fs5-ride-mf', 'f2-ride-mobile-full', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation'), 
     5, true, false, true, true),
    
    -- Step 6: Success
    ('fs6-ride-mf', 'f2-ride-mobile-full', 
     (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff'), 
     6, true, false, false, true);
```

### Step 5: Add Elements to Flow Steps

Elements define the actual inputs. Copy from a similar flow and adjust:

```sql
-- Get elements from similar flow (dining_complimentary_item)
SELECT 
    fse.flow_step_id,
    fs.step_order,
    s.step_type,
    e.internal_name,
    e.internal_type,
    fse.element_order,
    fse.is_required,
    fse.is_visible,
    fse.default_value
FROM offer_builder_flow_step_elements fse
JOIN offer_builder_flow_steps fs ON fse.flow_step_id = fs.id
JOIN offer_builder_steps s ON fs.step_id = s.id
JOIN offer_builder_elements e ON fse.element_id = e.id
JOIN offer_builder_flows f ON fs.flow_id = f.id
WHERE f.synthetic_reward_type_id = 'dce31367-c854-41ba-b855-541bdcfd5874'  -- dining_complimentary_item
  AND f.audience_type = 'full_journey'
ORDER BY fs.step_order, fse.element_order;

-- Then insert similar elements for your new flow steps
INSERT INTO offer_builder_flow_step_elements 
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section)
VALUES
    -- For reward_creation step: credit amount input
    ('fse1-ride', 'fs1-ride-mj', 
     (SELECT id FROM offer_builder_elements WHERE internal_name = 'discount_amount'),
     1, true, true, null, 'main'),
    
    -- Journey guidance display
    ('fse2-ride', 'fs1-ride-mj',
     (SELECT id FROM offer_builder_elements WHERE internal_name = 'journey_guidance'),
     2, false, true, null, 'header'),
    
    -- Skip button (for journey flows)
    ('fse3-ride', 'fs1-ride-mj',
     (SELECT id FROM offer_builder_elements WHERE internal_name = 'skip_reward'),
     3, false, true, null, 'footer');
```

### Step 6: Verify Configuration

Run diagnostic query:
```sql
SELECT 
    srt.internal_name as reward_type,
    f.platform,
    f.audience_type,
    fs.step_order,
    s.step_type,
    s.default_title,
    e.internal_name as element,
    e.internal_type,
    fse.element_order,
    fse.is_required
FROM synthetic_reward_types srt
JOIN offer_builder_flows f ON srt.id = f.synthetic_reward_type_id
JOIN offer_builder_flow_steps fs ON f.id = fs.flow_id
JOIN offer_builder_steps s ON fs.step_id = s.id
LEFT JOIN offer_builder_flow_step_elements fse ON fs.id = fse.flow_step_id
LEFT JOIN offer_builder_elements e ON fse.element_id = e.id
WHERE srt.internal_name = 'complimentary_rideshare_credit'
ORDER BY f.platform, f.audience_type, fs.step_order, fse.element_order;
```

## Backend Considerations

### No Code Changes Needed If:
- Using existing `value_type` (REDEEM_DOLLAR_CREDIT, EARN_DOLLAR_CREDIT, EARN_POINTS)
- Using existing `bilt_category` (DINING, HOME, RIDESHARE)
- Using existing element types

### Code Changes Needed If:
- New `value_type` → Update `ValueType` enum
- New `bilt_category` → Update `BiltCategory` enum
- New `issuer_type` → Update repository queries
- New element type → Update frontend element renderer

## Frontend Considerations

### No Changes Needed If:
- Using existing element types
- Standard navigation flow

### Changes Needed If:
- Custom element rendering required
- Special validation logic
- Custom success handling

## Testing Checklist

- [ ] Reward type appears in `/synthetic-reward-types?issuerType=RIDESHARE`
- [ ] Flow returns for `GET /flows?rewardTypeId=X&platform=mobile&audienceType=full_journey`
- [ ] All steps appear in correct order
- [ ] All elements render correctly
- [ ] Required fields validate
- [ ] Skip buttons work (journey flows)
- [ ] Offer creation succeeds
- [ ] Offer appears in merchant's offer list

## Common Patterns

### Journey vs Standalone Differences

| Aspect | Journey (`full_journey`) | Standalone (`full`) |
|--------|-------------------------|---------------------|
| Skip buttons | Yes | No |
| Confirmation step | Usually no | Yes |
| Success handoff | Usually no | Yes |
| Audience step | No (journey defines) | Yes |
| `is_skip_allowed` | true | false |

### Copying Elements from Similar Flow

```sql
-- Copy all elements from source flow step to target flow step
INSERT INTO offer_builder_flow_step_elements 
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section)
SELECT 
    spanner.generate_uuid(),
    'YOUR_TARGET_FLOW_STEP_ID',
    element_id,
    element_order,
    is_required,
    is_visible,
    default_value,
    section
FROM offer_builder_flow_step_elements
WHERE flow_step_id = 'SOURCE_FLOW_STEP_ID';
```

### Creating All Platform/Audience Combinations

For complete coverage, you may need 6+ flows:
```sql
-- Generate all combinations
SELECT 
    platform,
    audience_type
FROM (VALUES ('mobile'), ('web')) AS p(platform)
CROSS JOIN (VALUES ('full'), ('full_journey'), ('single_user_instant'), ('single_user_deferred')) AS a(audience_type);
```
