# Adding a New Journey Template

This guide walks through adding a new journey template to the system. We'll use `FLEXIBLE_JOURNEY` as a concrete example—a template that allows merchants to fully customize their audience, offers, and messaging.

## Overview

Adding a new journey template involves:

1. **Backend (benefits-svc)**
   - Add enum value to `JourneyType`
   - Create database migration with template data
   - Update OpenAPI spec
   - Update template service ordering (if applicable)

2. **Frontend (bilt-frontend-mobile)**
   - Add type to TypeScript definitions
   - Create/modify step modal screens (if needed)
   - Test the full flow

## Step 1: Define the Journey Type

### 1.1 Add Enum Value

**File:** `benefits-svc/app/src/main/java/com/biltrewards/benefits/journeys/model/JourneyType.java`

```java
public enum JourneyType {
  // Existing types...
  FIRST_TIME_GUESTS("FIRST_TIME_GUESTS"),
  LOW_REVIEW_ENGAGEMENT("LOW_REVIEW_ENGAGEMENT"),
  BUSINESS_ACROSS_LOCATIONS("BUSINESS_ACROSS_LOCATIONS"),
  
  // Add new type
  FLEXIBLE_JOURNEY("FLEXIBLE_JOURNEY");  // <-- NEW
  
  private final String val;
  // ...
}
```

### 1.2 Update OpenAPI Spec

**File:** `benefits-svc/app/src/main/java/com/biltrewards/benefits/journeys/api/docs/journey-template-openapi.yaml`

```yaml
JourneyType:
  type: string
  description: Type of journey defining its purpose and characteristics
  enum:
    - FIRST_TIME_GUESTS
    - LOW_REVIEW_ENGAGEMENT
    - BUSINESS_ACROSS_LOCATIONS
    - FLEXIBLE_JOURNEY  # <-- ADD
```

## Step 2: Create Database Migration

Create a new migration file to insert the template data.

**File:** `benefits-svc/app/src/main/resources/db/migration/schema/benefits/spanner/common/V1XX__add_flexible_journey_template.sql`

```sql
-- ============================================================
-- FLEXIBLE_JOURNEY Template Migration
-- ============================================================
-- This journey type allows merchants to fully customize their
-- audience targeting, offers, and messaging without preset rules.
-- ============================================================

-- Step 1: Insert base template
INSERT INTO journey_templates (
    id,
    journey_type,
    portal,
    name,
    description,
    image_url,
    create_time,
    update_time
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',  -- Generate a real UUID
    'FLEXIBLE_JOURNEY',
    'merchant',
    'Create Your Own Journey',
    'Design a custom guest experience with your own audience targeting, reward, and messaging.',
    'https://your-cdn.com/images/flexible-journey.jpg',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Step 2: Create builder flow
INSERT INTO journey_builder_flows (
    id,
    journey_template_id,
    background_image_url,
    title,
    description,
    is_reward_selection_required,
    created_at,
    updated_at
) VALUES (
    '11111111-2222-3333-4444-555555555555',
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    'https://your-cdn.com/images/flexible-journey-bg.jpg',
    'Create Your Own Journey',
    'Build a custom engagement workflow for your guests',
    true,  -- Let merchant choose reward type
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Step 3: Add builder flow steps
-- Note: journey_steps should already have the base step types from V109/V110
--
-- IMPORTANT: JSONB format for default_body and body uses flat structure:
--   [{"icon": null, "order": 1, "value": "text here"}]
--   [{"icon": "icon-name", "order": 1, "value": "text here"}]

-- Step 3a: Audience step
INSERT INTO journey_builder_flow_steps (
    id,
    flow_id,
    step_id,
    step_order,
    is_required,
    badge_label,
    badge_icon,
    default_body,
    body,
    builder_entrypoint,
    created_at,
    updated_at
) VALUES (
    '66666666-7777-8888-9999-aaaaaaaaaaaa',
    '11111111-2222-3333-4444-555555555555',
    (SELECT id FROM journey_steps WHERE step_type = 'audience'),
    1,
    true,
    'Audience',
    'users-bold',
    '[{"icon": null, "order": 1, "value": "Define your target audience"}]'::JSONB,
    null,
    '/main/modals/journeys/{id}/audience',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Step 3b: Offer step
INSERT INTO journey_builder_flow_steps (
    id,
    flow_id,
    step_id,
    step_order,
    is_required,
    badge_label,
    badge_icon,
    default_body,
    body,
    builder_entrypoint,
    created_at,
    updated_at
) VALUES (
    'bbbbbbbb-cccc-dddd-eeee-ffffffffffff',
    '11111111-2222-3333-4444-555555555555',
    (SELECT id FROM journey_steps WHERE step_type = 'offer'),
    2,
    true,
    'Offer',
    'gift-bold',
    '[{"icon": null, "order": 1, "value": "Choose a reward for guests"}]'::JSONB,
    '[{"icon": "cocktail-regular", "order": 1, "value": "{reward.name}"}]'::JSONB,
    '/main/modals/journeys/{id}/offer-select-type',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Step 3c: Message step
INSERT INTO journey_builder_flow_steps (
    id,
    flow_id,
    step_id,
    step_order,
    is_required,
    badge_label,
    badge_icon,
    default_body,
    body,
    builder_entrypoint,
    created_at,
    updated_at
) VALUES (
    '00000000-1111-2222-3333-444444444444',
    '11111111-2222-3333-4444-555555555555',
    (SELECT id FROM journey_steps WHERE step_type = 'message'),
    3,
    true,
    'Message',
    'chat-dots-bold',
    '[{"icon": null, "order": 1, "value": "Set up your outreach"}]'::JSONB,
    '[{"icon": "clock-regular", "order": 1, "value": "{campaign.schedule}"}, {"icon": "text-box", "order": 2, "value": "{campaign.textContent}"}]'::JSONB,
    '/main/modals/journeys/{id}/messaging-campaign-type',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Step 4: Create empty audience template (no preset rules)
INSERT INTO journey_audience_templates (
    id,
    journey_template_id,
    name,
    description,
    rules,
    create_time,
    update_time
) VALUES (
    '12345678-1234-1234-1234-123456789abc',
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    'Custom Audience',
    'Define your own targeting criteria',
    '[]'::JSONB,  -- Empty rules - merchant defines everything
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Note: No offer templates or campaign templates are created
-- This is intentional - FLEXIBLE_JOURNEY has no preset defaults
```

### Migration Design Notes

**For FLEXIBLE_JOURNEY specifically:**
- `is_reward_selection_required = true` - Merchant must choose reward type
- `rules = '[]'` - Empty audience rules, merchant defines all targeting
- No `journey_offer_templates` rows - Merchant selects/creates offers
- No `journey_sms_campaign_templates` rows - Merchant configures from scratch
- `builder_entrypoint` uses full selection flows rather than pre-configured paths

**For other template types**, you would typically include:
- Pre-defined audience rules (e.g., `VISIT_COUNT = 1` for first-time guests)
- Default offer templates with reward types
- Pre-written SMS/Email templates with placeholders

## Step 3: Update Template Service (Optional)

If you want your new template to appear in a specific order in the UI:

**File:** `benefits-svc/app/src/main/java/com/biltrewards/benefits/journeys/JourneyTemplateService.java`

```java
private static final List<JourneyType> MERCHANT_JOURNEY_TYPE_ORDER =
    List.of(
        JourneyType.FIRST_TIME_GUESTS,
        JourneyType.BUSINESS_ACROSS_LOCATIONS,
        JourneyType.LOW_REVIEW_ENGAGEMENT,
        JourneyType.FLEXIBLE_JOURNEY  // Add at end or desired position
    );
```

## Step 4: Frontend Updates

### 4.1 Add TypeScript Type

**File:** `bilt-frontend-mobile/apps/bilt-merchant-mobile/types/journeys.ts`

```typescript
export type JourneyType = 
  | 'FIRST_TIME_GUESTS' 
  | 'LOW_REVIEW_ENGAGEMENT' 
  | 'BUSINESS_ACROSS_LOCATIONS'
  | 'FLEXIBLE_JOURNEY';  // <-- ADD
```

### 4.2 Handle New Type in UI

The template detail screen (`app/main/journeys/templates/[id].tsx`) is already generic—it reads from the `flow.steps` array and renders based on `stepType`. No changes needed unless you want custom behavior.

For step handling in `handleStepPress`:

```typescript
case 'offer': {
  const isRewardSelectionRequired = template?.flow.isRewardSelectionRequired;
  
  // FLEXIBLE_JOURNEY will have isRewardSelectionRequired = true
  // so it goes to offer-select-type, not directly to builder
  if (rewardTypeId && !isRewardSelectionRequired) {
    offerBuilderActions.setRewardType({ id: rewardTypeId });
    navigate(`/main/modals/journeys/${id}/offer-builder`);
  } else {
    // This path for FLEXIBLE_JOURNEY
    navigate(`/main/modals/journeys/${id}/offer-select-type`);
  }
  break;
}
```

### 4.3 Audience Configuration

The audience modal (`/main/modals/journeys/[id]/audience`) reads from `template.audienceTemplate.rules` and pre-populates filters. For `FLEXIBLE_JOURNEY`, this array is empty, so the user starts with a clean slate.

## Step 5: Testing Checklist

### Backend Tests
- [ ] Unit test for new `JourneyType` enum parsing
- [ ] Integration test: fetch templates includes new type
- [ ] Integration test: create journey with new template
- [ ] Verify migration runs without errors

### Frontend Tests  
- [ ] Template appears in journey list
- [ ] Template detail screen renders correctly
- [ ] Audience step works with empty initial rules
- [ ] Offer selection flow works
- [ ] Message configuration flow works
- [ ] Journey creation succeeds
- [ ] Created journey appears in "My Journeys"

### Manual Testing Flow
1. Open merchant app → Journeys tab
2. Verify "Create Your Own Journey" template card appears
3. Tap template → See empty audience step
4. Configure audience → Add custom filters
5. Configure offer → Select reward type → Configure item
6. Configure message → Set timing and content
7. Launch journey → Verify success
8. Check journey appears in list with "Live" status

## Example: Pre-configured Template

For comparison, here's what a more opinionated template might look like:

```sql
-- FIRST_TIME_GUESTS example with pre-configured rules

INSERT INTO journey_audience_templates (
    id, journey_template_id, name, description, rules, create_time, update_time
) VALUES (
    'uuid-here',
    'first-time-guests-template-id',
    'First Time Guests',
    'Guests who visited exactly once',
    '[
        {
            "nodeType": "VISIT_COUNT",
            "fields": [
                {"key": "QUANTITATIVE_OPERATOR", "value": "EXACTLY"},
                {"key": "QUANTITATIVE_VALUE_INTEGER", "value": "1"},
                {"key": "DATE_OPERATOR", "value": "ALL_TIME"}
            ]
        }
    ]'::JSONB,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT INTO journey_offer_templates (
    id, journey_template_id, name, description, 
    reward_type, reward_message, show_reward_message,
    create_time, update_time
) VALUES (
    'uuid-here',
    'first-time-guests-template-id',
    'Complimentary Item',
    'Offer a free item on their next visit',
    'COMPLIMENTARY_ITEM',
    '{"title": "Thanks for visiting!", "body": "Enjoy a complimentary {itemName} on us."}'::JSONB,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
```

## Deployment Checklist

1. [ ] Add enum value to `JourneyType.java`
2. [ ] Add enum value to `journey-template-openapi.yaml`
3. [ ] Run `mvn generate-sources` to regenerate API models
4. [ ] Create and test SQL migration locally
5. [ ] Deploy `benefits-svc` with migration
6. [ ] Add TypeScript type to `types/journeys.ts`
7. [ ] Deploy mobile app update (or wait for next release)

## Summary

| Step | File(s) | Change |
|------|---------|--------|
| 1 | `JourneyType.java` | Add enum value |
| 2 | `journey-template-openapi.yaml` | Add to enum in spec |
| 3 | `V1XX__migration.sql` | Insert template data |
| 4 | `JourneyTemplateService.java` | Update ordering (optional) |
| 5 | `types/journeys.ts` | Add TypeScript type |
| 6 | Frontend screens | Usually no changes needed |

The system is designed to be data-driven—most customization happens in the database migration, not in code.
