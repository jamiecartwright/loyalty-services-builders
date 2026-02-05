# Complimentary Rideshare - Flow Diagrams

Visual representation of the offer builder flows for validation.

---

## Reward Type Selection (Pre-Flow)

Before entering any flow, users select from the reward type selection screen:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              SELECT REWARD TYPE                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  ┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐                     │
│  │  🍽️ Complimentary    │   │  💰 Discount         │   │  🚗 Complimentary    │ ◄── NEW GROUP       │
│  │     Item             │   │                      │   │     Ride             │                     │
│  │                      │   │                      │   │                      │                     │
│  │  "Gift guests a      │   │  "Offer a % or $     │   │  "Gift guests a      │                     │
│  │   complimentary      │   │   off their next     │   │   seamless way to    │                     │
│  │   item"              │   │   visit"             │   │   get to and from"   │                     │
│  └──────────────────────┘   └──────────────────────┘   └──────────────────────┘                     │
│                                                                 │                                   │
│                                                                 ▼                                   │
│                                                     ┌──────────────────────┐                        │
│                                                     │  SELECT DIRECTION    │                        │
│                                                     ├──────────────────────┤                        │
│                                                     │  ○ Ride TO merchant  │                        │
│                                                     │  ○ Ride FROM rest.   │                        │
│                                                     └──────────────────────┘                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Flow Matrix

| Reward Type | Platform | Audience Type | Flow ID |
|-------------|----------|---------------|---------|
| TO Merchant | mobile | full | `rs-flow-to-mobile-full` |
| TO Merchant | mobile | full_journey | `rs-flow-to-mobile-journey` |
| TO Merchant | mobile | single_user_instant | `rs-flow-to-mobile-instant` |
| TO Merchant | mobile | single_user_deferred | `rs-flow-to-mobile-deferred` |
| TO Merchant | web | full | `rs-flow-to-web-full` |
| TO Merchant | web | single_user_instant | `rs-flow-to-web-instant` |
| TO Merchant | web | single_user_deferred | `rs-flow-to-web-deferred` |
| FROM Merchant | mobile | full | `rs-flow-from-mobile-full` |
| FROM Merchant | mobile | full_journey | `rs-flow-from-mobile-journey` |
| FROM Merchant | mobile | single_user_instant | `rs-flow-from-mobile-instant` |
| FROM Merchant | mobile | single_user_deferred | `rs-flow-from-mobile-deferred` |
| FROM Merchant | web | full | `rs-flow-from-web-full` |
| FROM Merchant | web | single_user_instant | `rs-flow-from-web-instant` |
| FROM Merchant | web | single_user_deferred | `rs-flow-from-web-deferred` |

---

## Flow: Ride TO Merchant (mobile/full)

```
┌────────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   STEP 1           │     │   STEP 2       │     │   STEP 3       │     │   STEP 4       │     │   STEP 5       │     │   STEP 6       │
│   Reward           │────▶│   Audience     │────▶│   Program      │────▶│   Messaging    │────▶│   Confirmation │────▶│   Success      │
│   Config           │     │   Definition   │     │   Settings     │     │   (TO)         │     │                │     │                │
├────────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│                    │     │                │     │                │     │                │     │                │     │                │
│ "What kind of      │     │ "Who should    │     │ Redemption     │     │ "Create SMS    │     │ • Offer Name   │     │ ✓ Success!     │
│  ride experience   │     │  receive this  │     │ limits:        │     │  for when      │     │                │     │                │
│  do you want to    │     │  offer?"       │     │                │     │  guests are    │     │ • Summary of   │     │ "Your offer    │
│  offer?"           │     │                │     │ • Per person   │     │  on their way" │     │   all settings │     │  has been      │
│                    │     │ • All guests   │     │ • Total max    │     │                │     │                │     │  created"      │
│ Eligible car types │     │ • Tagged       │     │                │     │ ┌────────────┐ │     │ [Create Offer] │     │                │
│ ┌──────────────┐   │     │   guests       │     │ Date range:    │     │ │ Message    │ │     │                │     │ [Done]         │
│ │🚗 Standard  ☑│   │     │ • Custom       │     │ • Start date   │     │ │ preview    │ │     │                │     │                │
│ │🚗 Black XL  ☑│   │     │   segment      │     │ • End date     │     │ └────────────┘ │     │                │     │                │
│ │🚗 Premium   ☑│   │     │                │     │                │     │                │     │                │     │                │
│ └──────────────┘   │     │ Audience count:│     │                │     │                │     │                │     │                │
│                    │     │ "123 guests"   │     │                │     │                │     │                │     │                │
│ Max ride cost [ON] │     │                │     │                │     │                │     │                │     │                │
│ ┌────────────────┐ │     │                │     │                │     │                │     │                │     │                │
│ │ $ 100          │ │     │                │     │                │     │                │     │                │     │                │
│ └────────────────┘ │     │                │     │                │     │                │     │                │     │                │
│ ☑ Offer partial    │     │                │     │                │     │                │     │                │     │                │
│   credit if over   │     │                │     │                │     │                │     │                │     │                │
├────────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│ ◀ Back: NO         │     │ ◀ Back: YES    │     │ ◀ Back: YES    │     │ ◀ Back: YES    │     │ ◀ Back: YES    │     │ ◀ Back: NO     │
│ Skip: NO           │     │ Skip: NO       │     │ Skip: NO       │     │ Skip: NO       │     │ Skip: NO       │     │ Skip: NO       │
│ Required: YES      │     │ Required: YES  │     │ Required: YES  │     │ Required: YES  │     │ Required: YES  │     │ Required: NO   │
└────────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
```

---

## Flow: Ride FROM Merchant (mobile/full)

```
┌────────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   STEP 1           │     │   STEP 2       │     │   STEP 3       │     │   STEP 4       │     │   STEP 5       │     │   STEP 6       │
│   Reward           │────▶│   Audience     │────▶│   Program      │────▶│   Messaging    │────▶│   Confirmation │────▶│   Success      │
│   Config           │     │   Definition   │     │   Settings     │     │   (FROM)       │     │                │     │                │
├────────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│                    │     │                │     │                │     │                │     │                │     │                │
│ "What kind of      │     │ "Who should    │     │ Redemption     │     │ "Create SMS    │     │ • Offer Name   │     │ ✓ Success!     │
│  ride experience   │     │  receive this  │     │ limits:        │     │  for when      │     │                │     │                │
│  do you want to    │     │  offer?"       │     │                │     │  guests receive│     │ • Summary of   │     │ "Your offer    │
│  offer?"           │     │                │     │ • Per person   │     │  their ride"   │     │   all settings │     │  has been      │
│                    │     │ • All guests   │     │ • Total max    │     │                │     │                │     │  created"      │
│ Eligible car types │     │ • Tagged       │     │                │     │ ┌────────────┐ │     │ [Create Offer] │     │                │
│ ┌──────────────┐   │     │   guests       │     │ Date range:    │     │ │ Message    │ │     │                │     │ [Done]         │
│ │🚗 Standard  ☑│   │     │ • Custom       │     │ • Start date   │     │ │ preview    │ │     │                │     │                │
│ │🚗 Black XL  ☑│   │     │   segment      │     │ • End date     │     │ └────────────┘ │     │                │     │                │
│ │🚗 Premium   ☑│   │     │                │     │                │     │                │     │                │     │                │
│ └──────────────┘   │     │ Audience count:│     │                │     │                │     │                │     │                │
│                    │     │ "123 guests"   │     │                │     │                │     │                │     │                │
│ Max ride cost [ON] │     │                │     │                │     │                │     │                │     │                │
│ ┌────────────────┐ │     │                │     │                │     │                │     │                │     │                │
│ │ $ 100          │ │     │                │     │                │     │                │     │                │     │                │
│ └────────────────┘ │     │                │     │                │     │                │     │                │     │                │
│ ☑ Offer partial    │     │                │     │                │     │                │     │                │     │                │
│   credit if over   │     │                │     │                │     │                │     │                │     │                │
├────────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│ ◀ Back: NO         │     │ ◀ Back: YES    │     │ ◀ Back: YES    │     │ ◀ Back: YES    │     │ ◀ Back: YES    │     │ ◀ Back: NO     │
│ Skip: NO           │     │ Skip: NO       │     │ Skip: NO       │     │ Skip: NO       │     │ Skip: NO       │     │ Skip: NO       │
│ Required: YES      │     │ Required: YES  │     │ Required: YES  │     │ Required: YES  │     │ Required: YES  │     │ Required: NO   │
└────────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
```

---

## Flow: Journey Variant (mobile/full_journey)

Journey flows differ from standalone flows:
- **No audience step** - the journey defines the audience
- **Skip buttons** - allow skipping this reward in the journey
- **Journey guidance** - context about where this fits in the journey

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   STEP 1       │     │   STEP 2       │     │   STEP 3       │     │   STEP 4       │     │   STEP 5       │
│   Reward       │────▶│   Program      │────▶│   Messaging    │────▶│   Confirmation │────▶│   Success      │
│   Config       │     │   Settings     │     │                │     │                │     │                │
├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│ ┌────────────┐ │     │ ┌────────────┐ │     │ ┌────────────┐ │     │ ┌────────────┐ │     │                │
│ │ JOURNEY    │ │     │ │ JOURNEY    │ │     │ │ JOURNEY    │ │     │ │ JOURNEY    │ │     │ ✓ Success!     │
│ │ GUIDANCE   │ │     │ │ GUIDANCE   │ │     │ │ GUIDANCE   │ │     │ │ GUIDANCE   │ │     │                │
│ │ display    │ │     │ │ display    │ │     │ │ display    │ │     │ │ display    │ │     │ Return to      │
│ └────────────┘ │     | └────────────┘ │     │ └────────────┘ │     │ └────────────┘ │     │ journey        │
│                │     │                │     │                │     │                │     │                │
│ ... same as    │     │ ... same as    │     │ ... same as    │     │ ... same as    │     │                │
│ full flow ...  │     │ full flow ...  │     │ full flow ...  │     │ full flow ...  │     │                │
│                │     │                │     │                │     │                │     │                │
│ ┌────────────┐ │     │ ┌────────────┐ │     │ ┌────────────┐ │     │                │     │                │
│ │[Skip This  │ │     │ │[Skip This  │ │     │ │[Skip This  │ │     │                │     │                │
│ │  Reward]   │ │     │ │  Reward]   │ │     │ │  Reward]   │ │     │                │     │                │
│ └────────────┘ │     │ └────────────┘ │     │ └────────────┘ │     │                │     │                │
├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│ Skip: YES      │     │ Skip: YES      │     │ Skip: YES      │     │ Skip: NO       │     │ Skip: NO       │
└────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
```

---

## Flow: Single User Instant (mobile/single_user_instant)

For instant offers to a single user, program settings are hidden:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   STEP 1       │     │   STEP 2       │     │   STEP 3       │     │   STEP 4       │
│   Reward       │────▶│   Messaging    │────▶│   Confirmation │────▶│   Success      │
│   Config       │     │                │     │                │     │                │
├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│                │     │                │     │                │     │                │
│ "How much      │     │ SMS message    │     │ • Summary      │     │ ✓ Sent!        │
│  credit?"      │     │ for this       │     │                │     │                │
│                │     │ user           │     │ [Send Offer]   │     │                │
│ ┌────┐ ┌────┐  │     │                │     │                │     │                │
│ │$10 │ │$15 │  │     │                │     │                │     │                │
│ └────┘ └────┘  │     │                │     │                │     │                │
│ ┌────┐ ┌──────┐│     │                │     │                │     │                │
│ │$25 │ │Custom││     │                │     │                │     │                │
│ └────┘ └──────┘│     │                │     │                │     │                │
│                │     │                │     │                │     │                │
├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│ Program        │     │                │     │                │     │                │
│ Settings:      │     │                │     │                │     │                │
│ HIDDEN         │     │                │     │                │     │                │
└────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
```

---

## Flow: Single User Deferred (mobile/single_user_deferred)

For deferred offers, includes scheduling:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   STEP 1       │     │   STEP 2       │     │   STEP 3       │     │   STEP 4       │     │   STEP 5       │
│   Reward       │────▶│   Schedule     │────▶│   Messaging    │────▶│   Confirmation │────▶│   Success      │
│   Config       │     │                │     │                │     │                │     │                │
├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤     ├────────────────┤
│                │     │                │     │                │     │                │     │                │
│ Same as full   │     │ • Send date    │     │ SMS message    │     │ • Summary      │     │ ✓ Scheduled!   │
│                │     │ • Send time    │     │                │     │                │     │                │
│                │     │                │     │                │     │ [Schedule]     │     │                │
│                │     │                │     │                │     │                │     │                │
└────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
```

---

## Element Details

### Step 1: Reward Configuration

**Title:** "What kind of ride experience do you want to offer?"

| Element | Type | Required | Visible | Conditional |
|---------|------|----------|---------|-------------|
| `eligible_car_types` | multi_select_card | YES | YES | - |
| `max_ride_cost_enabled` | toggle | NO | YES | - |
| `max_ride_cost_amount` | currency | NO | NO | Show when `max_ride_cost_enabled` = true |
| `offer_partial_credit` | checkbox | NO | NO | Show when `max_ride_cost_enabled` = true |

**Options for eligible_car_types:**
| Value | Label | Description | Image |
|-------|-------|-------------|-------|
| standard | Standard | A standard car for regular fares | (image URL TBD) |
| black | Black / Black XL | Luxury rides, professional drivers | (image URL TBD) |
| premium | Premium (Chauffeur Service) | White glove chauffeur experience | (image URL TBD) |

### Step 2: Audience Definition (standalone `full` flows only)

> **Note:** This step only appears in standalone (`full`) flows. Journey (`full_journey`) flows don't include this step because the journey defines the audience.

| Element | Type | Required | Visible |
|---------|------|----------|---------|
| `audience_selector` | audience_builder | YES | YES |
| `audience_count` | display_block | NO | YES |

**Audience options:**
- All guests (default)
- Tagged guests (filter by tags)
- Custom segment (advanced rules)

### Step 3: Program Settings

| Element | Type | Required | Visible |
|---------|------|----------|---------|
| `max_redemptions_per_person` | select | NO | YES |
| `max_redemptions` | number | NO | YES |
| `offer_duration_start` | datetime | NO | YES |
| `offer_duration_end` | datetime | NO | YES |

### Step 4: Messaging

| Element | Type | Required | Visible |
|---------|------|----------|---------|
| `message_content` | text_box | NO | YES |

**Title differs by variant:**
- TO: "Create a personalized SMS to send when guests are on their way"
- FROM: "Create a personalized SMS to send when guests receive their complimentary ride"

### Step 5: Confirmation

| Element | Type | Required | Visible |
|---------|------|----------|---------|
| `offer_name` | text | YES | YES |
| `input_summary` | itemized_list | NO | YES |
| `create_offer` | button | NO | YES |

### Step 6: Success

| Element | Type | Required | Visible |
|---------|------|----------|---------|
| (display only) | - | - | - |

---

## Differences: TO vs FROM

| Aspect | TO Merchant | FROM Merchant |
|--------|---------------|-----------------|
| Messaging Title | "...when guests are on their way" | "...when guests receive their ride" |
| Default SMS | Arrival-focused messaging | Departure-focused messaging |
| reward_type_id | `5828f406-c7fe-4125-ab3b-d594a8d0a0a7` | `b2c3d4e5-f6a7-8901-bcde-f23456789012` |

All other steps are identical between TO and FROM variants.

---

## Differences: Standalone vs Journey

| Aspect | Standalone (`full`) | Journey (`full_journey`) |
|--------|---------------------|--------------------------|
| Audience Step | YES - Step 2 | NO - journey defines audience |
| Skip Buttons | NO | YES - on each step |
| Journey Guidance | NO | YES - header on each step |
| Confirmation Step | YES | Usually NO |
| Success Handoff | YES | Usually NO |
| Total Steps | 6 | 3-4 |
