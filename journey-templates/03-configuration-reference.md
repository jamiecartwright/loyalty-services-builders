# Journey Template Configuration Reference

Complete reference for all configurable options when creating journey templates.

## Table of Contents

1. [Template Configuration](#template-configuration)
2. [Builder Flow Configuration](#builder-flow-configuration)
3. [Step Configuration](#step-configuration)
4. [Audience Template Configuration](#audience-template-configuration)
5. [Offer Template Configuration](#offer-template-configuration)
6. [Campaign Template Configuration](#campaign-template-configuration)
7. [Tag Rule Node Reference](#tag-rule-node-reference)

---

## Template Configuration

### `journey_templates` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `journey_type` | String | Yes | Enum value from `JourneyType` |
| `portal` | String | Yes | `'merchant'` or `'property'` |
| `name` | String | Yes | Display name (shown in template list) |
| `description` | String | No | Description text (shown in template detail) |
| `image_url` | String | No | Background image URL |
| `create_time` | Timestamp | Yes | Creation timestamp |
| `update_time` | Timestamp | Yes | Last update timestamp |
| `delete_time` | Timestamp | No | Soft delete timestamp |

### Portal Values

| Value | Description | App |
|-------|-------------|-----|
| `merchant` | Dining/Restaurant journeys | bilt-merchant-mobile |
| `property` | Rent/Property journeys | bilt-property-mobile |

---

## Builder Flow Configuration

### `journey_builder_flows` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `journey_template_id` | UUID | Yes | FK to `journey_templates` |
| `background_image_url` | String | No | Hero image for detail screen |
| `title` | String | No | Override template name in builder UI |
| `description` | String | No | Override template description |
| `is_reward_selection_required` | Boolean | No | If `true`, user must select reward type |
| `created_at` | Timestamp | Yes | Creation timestamp |
| `updated_at` | Timestamp | Yes | Last update timestamp |

### `is_reward_selection_required` Behavior

| Value | Behavior |
|-------|----------|
| `true` | User navigates to reward type selection first |
| `false` (default) | Uses reward type from `builder_entrypoint` URL param |

---

## Step Configuration

### `journey_steps` Table (Reusable Definitions)

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `step_type` | String | Yes | Step type identifier |
| `created_at` | Timestamp | Yes | Creation timestamp |
| `updated_at` | Timestamp | Yes | Last update timestamp |

### Step Types

| Type | Description | Typical Order |
|------|-------------|---------------|
| `audience` | Target audience configuration | 1 |
| `offer` | Reward/experience configuration | 2 |
| `message` | SMS campaign configuration | 3 |
| `email` | Email campaign configuration | 4 |

### `journey_builder_flow_steps` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `flow_id` | UUID | Yes | FK to `journey_builder_flows` |
| `step_id` | UUID | Yes | FK to `journey_steps` |
| `step_order` | Integer | Yes | Display order (1-based) |
| `is_required` | Boolean | Yes | Must be completed to launch |
| `badge_label` | String | No | Label shown on step card |
| `badge_icon` | String | No | Icon token (from `@biltorg/icons-core`) |
| `default_body` | JSONB | No | Content before configuration |
| `body` | JSONB | No | Content after configuration (with placeholders) |
| `builder_entrypoint` | String | No | URL path for step builder |
| `show_merchant_selector` | Boolean | No | Show location picker in step |
| `group_id` | UUID | No | Optional grouping for UI |
| `template_id` | UUID | No | FK to offer/campaign template |
| `template_type` | String | No | `'OFFER'`, `'SMS_CAMPAIGN'`, `'EMAIL_CAMPAIGN'`, `'AUDIENCE'` |
| `created_at` | Timestamp | No | Creation timestamp |
| `updated_at` | Timestamp | No | Last update timestamp |

### Body Format

The `default_body` and `body` fields are JSON arrays of display items:

```json
[
  {
    "empty": false,
    "map": {
      "order": 1,
      "icon": "clock-bold",      // Optional icon token
      "value": "Text to display" // Or placeholder like "{reward.name}"
    }
  }
]
```

### Available Placeholders

| Placeholder | Replacement Value |
|-------------|-------------------|
| `{reward.name}` | Offer name |
| `{reward.config.itemName}` | Configured item name |
| `{campaign.schedule}` | Timing summary text |
| `{campaign.textContent}` | Message content |

### Icon Tokens

Common icons from `@biltorg/icons-core`:

| Token | Usage |
|-------|-------|
| `users-bold` | Audience |
| `gift-bold` | Offer/Reward |
| `chat-dots-bold` | SMS Message |
| `envelope-bold` | Email |
| `clock-bold` | Timing |
| `calendar-bold` | Date/Schedule |

### Builder Entrypoint URLs

| URL Pattern | Description |
|-------------|-------------|
| `/main/modals/journeys/{id}/audience` | Audience filter builder |
| `/main/modals/journeys/{id}/offer-select-type` | Reward type selection |
| `/main/modals/journeys/{id}/offer-builder` | Direct to offer builder |
| `/main/modals/journeys/{id}/offer-builder?rewardTypeId=xxx` | Pre-selected reward type |
| `/main/modals/journeys/{id}/messaging-campaign-type` | Campaign type selection |
| `/main/modals/journeys/{id}/messaging-input` | Message composer |

---

## Audience Template Configuration

### `journey_audience_templates` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `journey_template_id` | UUID | Yes | FK to `journey_templates` |
| `name` | String | No | Audience name |
| `description` | String | No | Audience description |
| `rules` | JSONB | No | Array of `TagRuleNode` objects |
| `create_time` | Timestamp | Yes | Creation timestamp |
| `update_time` | Timestamp | Yes | Last update timestamp |
| `delete_time` | Timestamp | No | Soft delete timestamp |

### Rules Format

The `rules` field is a JSON array of `TagRuleNode` objects:

```json
[
  {
    "nodeType": "VISIT_COUNT",
    "fields": [
      {"key": "QUANTITATIVE_OPERATOR", "value": "EXACTLY"},
      {"key": "QUANTITATIVE_VALUE_INTEGER", "value": "1"},
      {"key": "DATE_OPERATOR", "value": "ALL_TIME"}
    ]
  },
  {
    "nodeType": "TIMEFRAME",
    "fields": [
      {"key": "DATE_OPERATOR", "value": "LAST_N_DAYS"},
      {"key": "TIME_VALUE_INTEGER", "value": "30"},
      {"key": "TIME_UNIT", "value": "DAYS"}
    ]
  }
]
```

---

## Offer Template Configuration

### `journey_offer_templates` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `journey_template_id` | UUID | Yes | FK to `journey_templates` |
| `name` | String | No | Offer name |
| `description` | String | No | Offer description |
| `reward_type` | String | No | `'COMPLIMENTARY_ITEM'` or `'DISCOUNT'` |
| `reward_message` | JSONB | No | Message template object |
| `show_reward_message` | Boolean | No | Display message to guest |
| `create_time` | Timestamp | Yes | Creation timestamp |
| `update_time` | Timestamp | Yes | Last update timestamp |
| `delete_time` | Timestamp | No | Soft delete timestamp |

### Reward Types

| Value | Description |
|-------|-------------|
| `COMPLIMENTARY_ITEM` | Free item (menu item, service, etc.) |
| `DISCOUNT` | Percentage or fixed discount |

### Reward Message Format

```json
{
  "title": "Thanks for visiting!",
  "body": "Enjoy a complimentary {itemName} on your next visit.",
  "footer": "Valid for 30 days"
}
```

---

## Campaign Template Configuration

### `journey_sms_campaign_templates` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `journey_template_id` | UUID | Yes | FK to `journey_templates` |
| `name` | String | No | Campaign name |
| `text_content` | String | No | SMS message template |
| `from_phone` | String | No | Sender phone number |
| `campaign_type` | String | No | `'EVENT'` or `'BULK'` |
| `visit_trigger_type` | String | No | `'BEFORE_VISIT'`, `'DURING_VISIT'`, `'AFTER_VISIT'` |
| `visit_trigger_offset_minutes` | Integer | No | Minutes offset from trigger |
| `visit_trigger_fixed_time` | String | No | Specific time (HH:MM format) |
| `visit_trigger_enabled` | Boolean | No | Enable visit-based triggering |
| `one_time_send` | Boolean | No | Send only once per guest |
| `create_time` | Timestamp | Yes | Creation timestamp |
| `update_time` | Timestamp | Yes | Last update timestamp |

### `journey_email_campaign_templates` Table

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | UUID | Yes | Primary key |
| `journey_template_id` | UUID | Yes | FK to `journey_templates` |
| `subject_template` | String | No | Email subject line |
| `html_content_template` | String | No | HTML email body |
| `text_content_template` | String | No | Plain text email body |
| `design_content_template` | String | No | Email design JSON |
| `campaign_type` | String | No | `'EVENT'` or `'BULK'` |
| (same trigger fields as SMS) | | | |

### Campaign Types

| Value | Description |
|-------|-------------|
| `EVENT` | Triggered by guest actions (visit, booking, etc.) |
| `BULK` | Sent to all audience members at scheduled time |

### Visit Trigger Types

| Value | Description |
|-------|-------------|
| `BEFORE_VISIT` | Send before scheduled visit |
| `DURING_VISIT` | Send while guest is at location |
| `AFTER_VISIT` | Send after visit completes |

### Message Placeholders

| Placeholder | Description |
|-------------|-------------|
| `{merchant.name}` | Merchant/Restaurant name |
| `{merchant.shortName}` | Abbreviated name |
| `{guest.firstName}` | Guest's first name |
| `{guest.lastName}` | Guest's last name |
| `{offer.name}` | Offer name |
| `{offer.itemName}` | Configured item name |
| `{offer.expirationDate}` | Offer expiration date |

---

## Tag Rule Node Reference

### Complete Node Type List

#### Guest Behavior (Dining)

| Node Type | Fields | Description |
|-----------|--------|-------------|
| `VISIT_COUNT` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER`, `DATE_OPERATOR` | Number of visits |
| `REVIEW_RATING` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Star rating |
| `REVIEW_COUNT` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Number of reviews |
| `SPEND_AMOUNT` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_DECIMAL` | Spend amount |
| `BOOKING_METHOD` | `BOOKING_METHODS` | Reservation channel |
| `BOOKING_WINDOW` | `DATE_OPERATOR`, `TIME_VALUE_INTEGER`, `TIME_UNIT` | Time to booking |
| `COVER_SIZE` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Party size |
| `VISIT_TIME` | `VISIT_TIME_OPTIONS` | Time of day |
| `WHICH_VISIT` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Visit number |

#### Menu/Items (Dining)

| Node Type | Fields | Description |
|-----------|--------|-------------|
| `ITEM` | `ITEM_IDS` | Specific items |
| `ITEM_CATEGORY` | `CATEGORY_IDS` | Item categories |
| `ITEM_COUNT` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Items ordered |
| `ITEM_PRICE` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_DECIMAL` | Item price |

#### Location/Account (Dining)

| Node Type | Fields | Description |
|-----------|--------|-------------|
| `MERCHANT` | `MERCHANT_IDS` | Specific locations |
| `MERCHANT_GUESTBOOK` | `GUESTBOOK_STATUS` | Guestbook status |
| `PAYMENT_METHOD` | `PAYMENT_METHODS` | How paid |
| `HOUSE_ACCOUNT` | `HOUSE_ACCOUNT_STATUS` | House account status |

#### Resident (Property)

| Node Type | Fields | Description |
|-----------|--------|-------------|
| `LEASE_STATUS` | `LEASE_STATUSES` | Current lease state |
| `RESIDENT_STATUS` | `RESIDENT_STATUSES` | Account state |
| `LEASE_START_DATE` | `DATE_OPERATOR`, `DATE_VALUE` | Lease start |
| `LEASE_END_DATE` | `DATE_OPERATOR`, `DATE_VALUE` | Lease end |
| `RENT_AMOUNT` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_DECIMAL` | Monthly rent |
| `HOUSEHOLD_SIZE` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Occupants |
| `TERM_LENGTH` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Lease months |
| `TENURE` | `QUANTITATIVE_OPERATOR`, `QUANTITATIVE_VALUE_INTEGER` | Months as resident |
| `LEASEHOLDER_STATUS` | `LEASEHOLDER_STATUSES` | Primary/co-signer |
| `RESIDENT_LOYALTY_STATUS` | `LOYALTY_STATUSES` | Rent loyalty tier |
| `PROPERTY` | `PROPERTY_IDS` | Specific properties |

#### General/Loyalty

| Node Type | Fields | Description |
|-----------|--------|-------------|
| `BILT_LOYALTY_STATUS` | `LOYALTY_STATUSES` | Bilt member tier |
| `BILT_MEMBERS` | `MEMBERSHIP_STATUS` | Bilt membership |
| `TIMEFRAME` | `DATE_OPERATOR`, various | Date constraints |
| `CUSTOMERS` | `CUSTOMER_CRITERIA` | Dynamic list |
| `STATIC_CUSTOMERS` | `CUSTOMER_IDS` | Static ID list |
| `STATIC_LIST_CUSTOMERS` | `LIST_ID` | From customer list |
| `STATIC_TAG_LIST_CUSTOMERS` | `TAG_LIST_ID` | From tagged list |
| `PROFILE_ATTRIBUTES` | Various | Guest profile fields |

### Field Keys Reference

| Field Key | Type | Values |
|-----------|------|--------|
| `QUANTITATIVE_OPERATOR` | Enum | `EXACTLY`, `MORE_THAN`, `LESS_THAN`, `BETWEEN`, `AT_LEAST`, `AT_MOST` |
| `QUANTITATIVE_VALUE_INTEGER` | Integer | Any integer |
| `QUANTITATIVE_VALUE_DECIMAL` | Decimal | Any decimal |
| `DATE_OPERATOR` | Enum | `ALL_TIME`, `LAST_N_DAYS`, `BETWEEN_DATES`, `AFTER_DATE`, `BEFORE_DATE` |
| `TIME_VALUE_INTEGER` | Integer | Time amount |
| `TIME_UNIT` | Enum | `HOURS`, `DAYS`, `WEEKS`, `MONTHS` |
| `DATE_VALUE` | String | ISO date string |
| `START_DATE` | String | ISO date string |
| `END_DATE` | String | ISO date string |

### Example Rule Configurations

#### First-Time Guests
```json
[
  {
    "nodeType": "VISIT_COUNT",
    "fields": [
      {"key": "QUANTITATIVE_OPERATOR", "value": "EXACTLY"},
      {"key": "QUANTITATIVE_VALUE_INTEGER", "value": "1"},
      {"key": "DATE_OPERATOR", "value": "ALL_TIME"}
    ]
  }
]
```

#### High Spenders in Last 30 Days
```json
[
  {
    "nodeType": "SPEND_AMOUNT",
    "fields": [
      {"key": "QUANTITATIVE_OPERATOR", "value": "MORE_THAN"},
      {"key": "QUANTITATIVE_VALUE_DECIMAL", "value": "100.00"}
    ]
  },
  {
    "nodeType": "TIMEFRAME",
    "fields": [
      {"key": "DATE_OPERATOR", "value": "LAST_N_DAYS"},
      {"key": "TIME_VALUE_INTEGER", "value": "30"},
      {"key": "TIME_UNIT", "value": "DAYS"}
    ]
  }
]
```

#### Low Review Rating
```json
[
  {
    "nodeType": "REVIEW_RATING",
    "fields": [
      {"key": "QUANTITATIVE_OPERATOR", "value": "LESS_THAN"},
      {"key": "QUANTITATIVE_VALUE_INTEGER", "value": "4"}
    ]
  }
]
```

#### New Lease in Last 7 Days
```json
[
  {
    "nodeType": "LEASE_STATUS",
    "fields": [
      {"key": "LEASE_STATUSES", "value": "ACTIVE"}
    ]
  },
  {
    "nodeType": "LEASE_START_DATE",
    "fields": [
      {"key": "DATE_OPERATOR", "value": "LAST_N_DAYS"},
      {"key": "TIME_VALUE_INTEGER", "value": "7"},
      {"key": "TIME_UNIT", "value": "DAYS"}
    ]
  }
]
```

---

## Putting It All Together

### Complete Template Example

```sql
-- LOYALTY_REACTIVATION template: Win back lapsed high-value guests

-- 1. Base template
INSERT INTO journey_templates (id, journey_type, portal, name, description, image_url, create_time, update_time)
VALUES (
    'template-uuid',
    'LOYALTY_REACTIVATION',
    'merchant',
    'Win Back Your Best Guests',
    'Re-engage high-value guests who haven''t visited in 60+ days',
    'https://cdn.example.com/reactivation.jpg',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);

-- 2. Builder flow
INSERT INTO journey_builder_flows (id, journey_template_id, is_reward_selection_required, created_at, updated_at)
VALUES ('flow-uuid', 'template-uuid', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 3. Steps (audience + offer + message)
INSERT INTO journey_builder_flow_steps (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon, default_body, created_at, updated_at)
VALUES 
('step1-uuid', 'flow-uuid', (SELECT id FROM journey_steps WHERE step_type = 'audience'), 1, true, 'Audience', 'users-bold', '[{"empty":false,"map":{"order":1,"value":"High-value guests who haven''t visited recently"}}]'::JSONB, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('step2-uuid', 'flow-uuid', (SELECT id FROM journey_steps WHERE step_type = 'offer'), 2, true, 'Offer', 'gift-bold', '[{"empty":false,"map":{"order":1,"value":"Exclusive reward to bring them back"}}]'::JSONB, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('step3-uuid', 'flow-uuid', (SELECT id FROM journey_steps WHERE step_type = 'message'), 3, true, 'Message', 'chat-dots-bold', '[{"empty":false,"map":{"order":1,"value":"Personalized outreach"}}]'::JSONB, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 4. Pre-configured audience rules
INSERT INTO journey_audience_templates (id, journey_template_id, name, rules, create_time, update_time)
VALUES ('audience-uuid', 'template-uuid', 'High-value lapsed guests', '[
    {"nodeType": "SPEND_AMOUNT", "fields": [{"key": "QUANTITATIVE_OPERATOR", "value": "MORE_THAN"}, {"key": "QUANTITATIVE_VALUE_DECIMAL", "value": "200.00"}]},
    {"nodeType": "VISIT_COUNT", "fields": [{"key": "QUANTITATIVE_OPERATOR", "value": "AT_LEAST"}, {"key": "QUANTITATIVE_VALUE_INTEGER", "value": "3"}]},
    {"nodeType": "TIMEFRAME", "fields": [{"key": "DATE_OPERATOR", "value": "BEFORE_DATE"}, {"key": "TIME_VALUE_INTEGER", "value": "60"}, {"key": "TIME_UNIT", "value": "DAYS"}]}
]'::JSONB, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 5. Pre-configured offer
INSERT INTO journey_offer_templates (id, journey_template_id, name, reward_type, reward_message, show_reward_message, create_time, update_time)
VALUES ('offer-uuid', 'template-uuid', 'Welcome Back Reward', 'DISCOUNT', '{"title": "We miss you!", "body": "Enjoy 20% off your next visit."}'::JSONB, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 6. Pre-configured SMS
INSERT INTO journey_sms_campaign_templates (id, journey_template_id, name, text_content, campaign_type, visit_trigger_type, one_time_send, create_time, update_time)
VALUES ('sms-uuid', 'template-uuid', 'Win Back SMS', 'Hi {guest.firstName}! It''s been a while since we''ve seen you at {merchant.name}. We''d love to welcome you back with 20% off. See you soon!', 'EVENT', 'AFTER_VISIT', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```
