# Flexible Journey Template - Data Mapping

This document maps the display details from `flexible_journey_details.csv` to the required database fields.

**Status: ✅ All values defined** - Ready for SQL generation

---

## 1. Journey Template (`journey_templates`)

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-template` |
| `journey_type` | `FLEXIBLE_JOURNEY` |
| `portal` | `merchant` |
| `name` | Build a custom guest experience |
| `description` | Create a custom experience by choosing your selected guests, the experience you want to offer, and how you'd like to welcome them in. |
| `image_url` | `NULL` |

---

## 2. Builder Flow (`journey_builder_flows`)

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-flow` |
| `journey_template_id` | `flexible-journey-template` |
| `background_image_url` | `NULL` |
| `title` | Build a custom guest experience |
| `description` | Create a custom experience by choosing your selected guests, the experience you want to offer, and how you'd like to welcome them in. |
| `is_reward_selection_required` | `true` |

---

## 3. Builder Flow Steps (`journey_builder_flow_steps`)

### Step 1: Audience

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-step-audience` |
| `flow_id` | `flexible-journey-flow` |
| `step_type` | `audience` |
| `step_order` | `1` |
| `is_required` | `true` |
| `badge_label` | Audience |
| `badge_icon` | `users-bold` |
| `default_body_json` | `[{"empty":false,"map":{"order":1,"value":"Reach out to valued guests based on visits, spend, tags, and more."}}]` |
| `body_json` | `[{"empty":false,"map":{"order":1,"value":"Custom audience"}}]` |
| `builder_entrypoint` | `/main/modals/journeys/{id}/audience` |
| `template_type` | `AUDIENCE` |
| `template_id` | `flexible-journey-audience` |

### Step 2: Before (Message/Campaign)

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-step-before` |
| `flow_id` | `flexible-journey-flow` |
| `step_type` | `message` |
| `step_order` | `2` |
| `is_required` | `false` |
| `badge_label` | Before: Invite guests in |
| `badge_icon` | `chat-dots-bold` |
| `default_body_json` | `[{"empty":false,"map":{"order":1,"value":"Send a personalized message inviting or welcoming guests to your restaurant"}}]` |
| `body_json` | `[{"empty":false,"map":{"order":1,"value":"{campaign.schedule}"}},{"empty":false,"map":{"order":2,"value":"{campaign.textContent}"}}]` |
| `builder_entrypoint` | `/main/modals/journeys/{id}/messaging-campaign-type` |
| `template_type` | `SMS_CAMPAIGN` |
| `template_id` | `NULL` |

### Step 3: During (Offer)

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-step-during` |
| `flow_id` | `flexible-journey-flow` |
| `step_type` | `offer` |
| `step_order` | `3` |
| `is_required` | `false` |
| `badge_label` | During: Deliver a guest experience |
| `badge_icon` | `gift-bold` |
| `default_body_json` | `[{"empty":false,"map":{"order":1,"value":"Choose which experience you'd like to automatically offer these guests to make them feel special."}}]` |
| `body_json` | `[{"empty":false,"map":{"order":1,"value":"{reward.name}"}}]` |
| `builder_entrypoint` | `/main/modals/journeys/{id}/offer-select-type` |
| `template_type` | `OFFER` |
| `template_id` | `NULL` |

### Step 4: After (Message/Campaign)

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-step-after` |
| `flow_id` | `flexible-journey-flow` |
| `step_type` | `message` |
| `step_order` | `4` |
| `is_required` | `false` |
| `badge_label` | After: Thanks guests |
| `badge_icon` | `chat-dots-bold` |
| `default_body_json` | `[{"empty":false,"map":{"order":1,"value":"Send a note to thank guests for visiting and inviting them back in."}}]` |
| `body_json` | `[{"empty":false,"map":{"order":1,"value":"{campaign.schedule}"}},{"empty":false,"map":{"order":2,"value":"{campaign.textContent}"}}]` |
| `builder_entrypoint` | `/main/modals/journeys/{id}/messaging-campaign-type` |
| `template_type` | `SMS_CAMPAIGN` |
| `template_id` | `NULL` |

---

## 4. Audience Template (`journey_audience_templates`)

| Field | Value |
|-------|-------|
| `id` | `flexible-journey-audience` |
| `journey_template_id` | `flexible-journey-template` |
| `name` | Choose an audience |
| `description` | Filter who you would like to target |

**Audience Rules:** Empty array `[]` (user defines all rules)

---

## 5. Offer Templates

**None** - User configures from scratch

---

## 6. SMS Campaign Templates

**None** - User configures from scratch

---

## 7. Email Campaign Templates

**None** - User configures from scratch

---

## 8. Guidance Box Copy

| Context | Key | Value |
|---------|-----|-------|
| Audience Builder | `journey_guidance_audience_creator` | Filter your guestbook for who you would like to target for this journey |
| Campaign Builder | `journey_guidance_campaign_builder` | Set up a message you'd like to share with your guests |
| Offer Builder | `journey_guidance_offer_builder` | Create an offer for your guests |

**Note:** Storage location for guidance copy TBD - may need app-level config or new DB field.

---

## 9. UI Copy

| Element | Value |
|---------|-------|
| Action button text | Launch this journey |

---

## Code Changes Required

See **[code-changes.md](./code-changes.md)** for detailed instructions.

| Change | File | Status |
|--------|------|--------|
| Add `FLEXIBLE_JOURNEY` to enum | `benefits-svc/.../model/JourneyType.java` | ⬜ TODO |
| Add to OpenAPI spec | `benefits-svc/.../api/docs/journey-template-openapi.yaml` | ⬜ TODO |
| Add TypeScript type | `bilt-frontend-mobile/.../types/journeys.ts` | ⬜ TODO |
| Update template service ordering | `benefits-svc/.../JourneyTemplateService.java` | ⬜ Optional |

---

## Generated Files

| File | Description |
|------|-------------|
| [V143__add_flexible_journey_template.sql](./V143__add_flexible_journey_template.sql) | Database migration |
| [code-changes.md](./code-changes.md) | Code change instructions |

---

## Next Steps

1. ✅ All data values defined
2. ✅ SQL migration generated → `V143__add_flexible_journey_template.sql`
3. ⬜ Update Java enum (see code-changes.md)
4. ⬜ Update OpenAPI spec (see code-changes.md)
5. ⬜ Update TypeScript types (see code-changes.md)
6. ⬜ Determine storage for guidance copy (deferred)
