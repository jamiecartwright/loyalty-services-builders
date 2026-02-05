# PRD: Complimentary Rideshare Offer Builder

**Parent Issue:** [MR-2505](https://linear.app/bilt/issue/MR-2505/enable-complimentary-ride-in-offer-builder)  
**Status:** Planning  
**Author:** Jamie Cartwright  
**Date:** Jan 30, 2026

---

## Overview

Enable dining merchants to create complimentary rideshare credit offers for guests via the Offer Builder. Merchants can offer rides either TO or FROM their location.

## Design

- **Mobile:** [Figma](https://www.figma.com/design/brNBRVP2ZyKPuidGT8ve1X/%F0%9F%8E%81-Offer-Builder---Merchant-portal?node-id=16199-38276)
- **Web:** [Figma](https://www.figma.com/design/brNBRVP2ZyKPuidGT8ve1X/%F0%9F%8E%81-Offer-Builder---Merchant-portal?node-id=16118-179470)

---

## System Changes Required

### 1. Reward Type Groups (New Architecture)

**Problem:** The reward type selection screen shows one card per `synthetic_reward_type`. For Complimentary Ride, we need ONE card that expands to show TWO options (To/From merchant). This will also be an important concept for Experiences/Amenities, another upcoming reward type for Offer Builder.

**Solution:** Introduce `synthetic_reward_type_groups` table to group multiple reward types under a single selection card.

```
┌─────────────────────────────────┐
│  synthetic_reward_type_groups   │ ← "Complimentary Ride" (parent card)
└─────────────┬───────────────────┘
              │ 1:N
              ▼
┌─────────────────────────────────┐
│    synthetic_reward_types       │ ← "Ride to merchant"
│                                 │ ← "Ride from merchant"
└─────────────────────────────────┘
```

**Schema Changes:**
1. Create `synthetic_reward_type_groups` table with: id, internal_name, external_label, description, icon, display_rank, issuer_type, is_enabled
2. Add nullable `group_id` FK to `synthetic_reward_types`
3. Add `description` column to `offer_builder_element_options` (for car type descriptions)

**API Changes:**
- `GET /synthetic-reward-types` response adds `rewardTypeGroups` array with nested `childTypes`

### 2. New Synthetic Reward Types

Split the existing `complimentary_rideshare_credit` into two:

| Type | internal_name | Description |
|------|---------------|-------------|
| TO | `complimentary_ride_to_merchant` | Help guests get to your location |
| FROM | `complimentary_ride_from_merchant` | Help guests get home safely |

Both have:
- `issuer_type = 'DINING'` (shown to dining merchants)
- `bilt_category = 'RIDESHARE'`
- `value_type = 'REDEEM_DOLLAR_CREDIT'`

### 3. Offer Builder Flows

Create flows for both types across all platform/audience combinations:

| Platform | Audience Types |
|----------|----------------|
| mobile | full, full_journey, single_user_instant, single_user_deferred |
| web | full, single_user_instant, single_user_deferred |

**Flow Steps - Standalone (full):**
1. **Reward Configuration** - Select car types, set max ride cost
2. **Audience Definition** - Select target audience (all guests, tagged, segment)
3. **Program Settings** - Redemption limits, date range
4. **Messaging** - SMS template (copy differs for TO vs FROM)
5. **Confirmation** - Review and name offer
6. **Success** - Confirmation screen

**Flow Steps - Journey (full_journey):**
1. **Reward Configuration** - Select car types, set max ride cost
2. **Program Settings** - Redemption limits, date range (no audience - defined by journey)
3. **Messaging** - SMS template (copy differs for TO vs FROM)

**Flow Steps - Single User (instant/deferred):**
1. **Reward Configuration** - Select car types, set max ride cost
2. **Program Settings** - Redemption limits
3. **Messaging** - SMS template

### 4. New/Modified Elements

| Element | Type | Notes |
|---------|------|-------|
| `eligible_car_types` | `multi_select_card` | Multi-select with car images. Image URLs stored in `icon` column. |
| `max_ride_cost_enabled` | `toggle` | Toggle to enable/disable max cost cap |
| `max_ride_cost_amount` | `currency` | Dollar input (default: $100), conditional on toggle |
| `offer_partial_credit` | `checkbox` | "Offer partial credit if ride exceeds maximum" - guest pays the difference. Conditional on toggle. |

**Car Type Options:**
| Value | Label | Description |
|-------|-------|-------------|
| standard | Standard | A standard car for regular fares |
| black | Black / Black XL | Luxury rides, professional drivers |
| premium | Premium (Chauffeur Service) | White glove chauffeur experience |

**Rideshare Partner:** Lyft. Mapping selected car types to Lyft vehicle classes is a follow-on phase.

### 5. Conditional Element Visibility

The `max_ride_cost_amount` and `offer_partial_credit` fields appear when `max_ride_cost_enabled = true`.

**Implementation Status:** ✅ Already implemented in both codebases:
- Mobile: `evaluateConditionalLogic()` in `packages/bilt-sdk/src/offer-creator/utils/conditionalLogic.ts`
- Web: `shouldShowElement()` in `packages/bilt-loyalty-sdk-web/src/offer-creator/utils/elementNormalizer.ts`
- Format: `{ when: { field: "max_ride_cost_enabled", equals: "true" }, isVisible: true }`

---

## Implementation Phases

### Phase 1: Backend Schema & Data
- Create groups table
- Add group_id to reward types
- Seed rideshare group and two child types
- Create offer builder flows, steps, elements

### Phase 2: API Updates  
- Update `getSyntheticRewardTypes()` to return groups with children
- Update response models

### Phase 3: Frontend - Selection Screen
- Handle groups in reward type selection
- Add sub-selection screen/modal for group children

### Phase 4: Frontend - Flow Rendering
- ✅ Conditional element visibility (already implemented - no work needed)
- ⚠️ **New:** `multi_select_card` element type with images
  - Mobile: Create `MultiSelectElement` component (currently only supports: switch, number, select, text_box, dining_items, text)
  - Web: Enhance `MultiSelectInput.tsx` to render icons/images from options
- Handle `toggle` element type
- Handle `currency` element type

### Phase 5: Enable & Test
- Remove "Coming Soon" state
- E2E testing

---

## Success Criteria

- [ ] Merchants can select "Complimentary Ride" and choose TO or FROM direction
- [ ] Full offer creation flow works for both directions
- [ ] Offers appear correctly in offer management screens
- [ ] Web and mobile parity
