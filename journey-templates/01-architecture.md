# Journey Builder Architecture

This document describes the architecture of the Journey Builder system across benefits-svc and the mobile frontends.

## System Overview

The Journey Builder enables merchants/properties to create automated engagement workflows. A journey consists of:
- **Audience** - Who receives the journey (based on tag rules)
- **Offers** - What reward/experience recipients receive
- **Campaigns** - How recipients are notified (SMS/Email)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Journey Builder Flow                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │  Audience   │───▶│    Offer    │───▶│   Campaign  │             │
│  │   (Tags)    │    │  (Reward)   │    │ (SMS/Email) │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Backend Data Model (benefits-svc)

### Entity Relationship

```
┌──────────────────────┐
│  journey_templates   │
│  ├─ id               │
│  ├─ journey_type     │◀──────────── Enum: JourneyType
│  ├─ portal           │
│  ├─ name             │
│  └─ description      │
└──────────┬───────────┘
           │
           │ 1:1
           ▼
┌──────────────────────┐        ┌──────────────────────┐
│ journey_builder_flows│───────▶│journey_builder_flow_ │
│  ├─ id               │  1:N   │       steps          │
│  ├─ journey_template │        │  ├─ id               │
│  │   _id             │        │  ├─ flow_id          │
│  ├─ title            │        │  ├─ step_id ─────────│──┐
│  └─ description      │        │  ├─ step_order       │  │
└──────────────────────┘        │  ├─ is_required      │  │
                                │  ├─ badge_label      │  │
                                │  ├─ default_body     │  │
                                │  └─ builder_entrypoint│  │
                                └──────────────────────┘  │
                                                          │
                                ┌──────────────────────┐  │
                                │    journey_steps     │◀─┘
                                │  ├─ id               │
                                │  └─ step_type        │◀── 'audience'|'message'|'offer'|'email'
                                └──────────────────────┘

┌──────────────────────┐
│journey_audience_     │
│    templates         │
│  ├─ id               │
│  ├─ journey_template │
│  │   _id             │
│  ├─ name             │
│  └─ rules (JSONB)    │◀──────── TagRuleNode[]
└──────────────────────┘

┌──────────────────────┐
│journey_offer_        │
│    templates         │
│  ├─ id               │
│  ├─ journey_template │
│  │   _id             │
│  ├─ reward_type      │
│  └─ reward_message   │
└──────────────────────┘
```

### Core Tables

#### `journey_templates`
Blueprint for a journey type.

```sql
CREATE TABLE journey_templates (
    id                VARCHAR(36) PRIMARY KEY,
    journey_type      TEXT NOT NULL,        -- 'FIRST_TIME_GUESTS', 'FLEXIBLE_JOURNEY', etc.
    portal            TEXT NOT NULL,        -- 'merchant' or 'property'
    name              TEXT NOT NULL,
    description       TEXT,
    image_url         TEXT,
    create_time       TIMESTAMPTZ NOT NULL,
    update_time       TIMESTAMPTZ NOT NULL,
    delete_time       TIMESTAMPTZ
);
```

#### `journey_builder_flows`
UI configuration for creating journeys from a template.

```sql
CREATE TABLE journey_builder_flows (
    id                   VARCHAR(36) PRIMARY KEY,
    journey_template_id  VARCHAR(36) NOT NULL,  -- FK to journey_templates
    background_image_url TEXT,
    title                TEXT,
    description          TEXT,
    created_at           TIMESTAMPTZ NOT NULL,
    updated_at           TIMESTAMPTZ NOT NULL
);
```

#### `journey_steps`
Reusable step type definitions.

```sql
CREATE TABLE journey_steps (
    id         VARCHAR(36) PRIMARY KEY,
    step_type  TEXT NOT NULL,  -- 'audience', 'message', 'offer', 'email'
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);
```

#### `journey_builder_flow_steps`
Links flows to steps with ordering and configuration.

```sql
CREATE TABLE journey_builder_flow_steps (
    id                 VARCHAR(36) PRIMARY KEY,
    flow_id            VARCHAR(36) NOT NULL,      -- FK to journey_builder_flows
    step_id            VARCHAR(36) NOT NULL,      -- FK to journey_steps
    step_order         INT NOT NULL,
    is_required        BOOL DEFAULT true,
    badge_label        TEXT,                      -- UI label
    badge_icon         TEXT,                      -- Icon token
    default_body       JSONB,                     -- Default content
    body               JSONB,                     -- Configured content with placeholders
    builder_entrypoint TEXT,                      -- URL for builder UI
    created_at         TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ
);
```

#### `journey_audience_templates`
Default audience rules for a template.

```sql
CREATE TABLE journey_audience_templates (
    id                  VARCHAR(36) PRIMARY KEY,
    journey_template_id VARCHAR(36) NOT NULL,
    name                TEXT,
    description         TEXT,
    rules               JSONB,                  -- TagRuleNode array
    create_time         TIMESTAMPTZ NOT NULL,
    update_time         TIMESTAMPTZ NOT NULL,
    delete_time         TIMESTAMPTZ
);
```

#### `journey_offer_templates`
Default offer configuration for a template.

```sql
CREATE TABLE journey_offer_templates (
    id                  VARCHAR(36) PRIMARY KEY,
    journey_template_id VARCHAR(36) NOT NULL,
    name                TEXT,
    description         TEXT,
    reward_type         TEXT,                   -- 'COMPLIMENTARY_ITEM', 'DISCOUNT'
    reward_message      JSONB,                  -- Message template with placeholders
    show_reward_message BOOLEAN,
    create_time         TIMESTAMPTZ NOT NULL,
    update_time         TIMESTAMPTZ NOT NULL,
    delete_time         TIMESTAMPTZ
);
```

### Java Models

#### JourneyType Enum
```java
public enum JourneyType {
  // Dining/Merchant
  FIRST_TIME_GUESTS("FIRST_TIME_GUESTS"),
  LOW_REVIEW_ENGAGEMENT("LOW_REVIEW_ENGAGEMENT"),
  BUSINESS_ACROSS_LOCATIONS("BUSINESS_ACROSS_LOCATIONS"),
  
  // Property/Rent
  NEW_LEASE("NEW_LEASE"),
  FIRST_THIRTY_DAYS("FIRST_THIRTY_DAYS"),
  RESIDENT_LIFECYCLE("RESIDENT_LIFECYCLE"),
  RENEWAL_REENGAGEMENT("RENEWAL_REENGAGEMENT");
}
```

#### JourneyTemplate
```java
public class JourneyTemplate {
  UUID id;
  JourneyType journeyType;
  String portal;
  String name;
  String description;
  String imageUrl;
  
  JourneyBuilderFlow flow;                        // UI configuration
  JourneyAudienceTemplate audienceTemplate;       // Default audience rules
  List<JourneyOfferTemplate> offerTemplates;      // Default offer config
  List<JourneySmsCampaignTemplate> smsCampaignTemplates;
  List<JourneyEmailCampaignTemplate> emailCampaignTemplates;
}
```

#### JourneyBuilderStep
```java
public class JourneyBuilderStep {
  UUID id;
  UUID stepId;               // Reference to reusable step
  String stepType;           // 'audience', 'message', 'offer', 'email'
  Integer stepOrder;
  Boolean isRequired;
  String badgeLabel;
  String badgeIcon;
  List<JsonObject> defaultBody;    // Before user configures
  List<JsonObject> body;           // After user configures
  String builderEntrypoint;        // URL to open the builder
  UUID groupId;                    // Optional group for organizing steps
  UUID templateId;                 // Links to offer/campaign template
  TemplateType templateType;       // OFFER, SMS_CAMPAIGN, EMAIL_CAMPAIGN, AUDIENCE
  Boolean showMerchantSelector;
}
```

## Tag Rule Engine

### Available Node Types

#### Dining/Guest Targeting
| Node Type | Description |
|-----------|-------------|
| `VISIT_COUNT` | Number of visits |
| `REVIEW_RATING` | Star rating of reviews |
| `REVIEW_COUNT` | Number of reviews |
| `SPEND_AMOUNT` | Total or per-visit spend |
| `BOOKING_METHOD` | How reservation was made |
| `BOOKING_WINDOW` | Time since/until booking |
| `COVER_SIZE` | Party size |
| `VISIT_TIME` | When visits occurred |
| `WHICH_VISIT` | Target specific visit number |
| `ITEM` | Specific menu items ordered |
| `ITEM_CATEGORY` | Menu category ordered |
| `ITEM_COUNT` | Number of items ordered |
| `ITEM_PRICE` | Price of items ordered |
| `PAYMENT_METHOD` | How guest paid |
| `MERCHANT` | Specific merchant locations |
| `MERCHANT_GUESTBOOK` | Guestbook membership |
| `HOUSE_ACCOUNT` | House account status |

#### Property/Rent Targeting
| Node Type | Description |
|-----------|-------------|
| `LEASE_STATUS` | Current lease status |
| `RESIDENT_STATUS` | Resident account status |
| `LEASE_START_DATE` | When lease started |
| `LEASE_END_DATE` | When lease ends |
| `RENT_AMOUNT` | Monthly rent |
| `HOUSEHOLD_SIZE` | Number of occupants |
| `TERM_LENGTH` | Lease term |
| `TENURE` | How long a resident |
| `LEASEHOLDER_STATUS` | Primary vs. co-signer |
| `RESIDENT_LOYALTY_STATUS` | Rent loyalty tier |
| `PROPERTY` | Specific property |

#### General/Loyalty
| Node Type | Description |
|-----------|-------------|
| `BILT_LOYALTY_STATUS` | Member tier |
| `BILT_MEMBERS` | Bilt membership status |
| `TIMEFRAME` | Date/time constraints |
| `CUSTOMERS` | Dynamic customer list |
| `STATIC_CUSTOMERS` | Static customer IDs |
| `STATIC_LIST_CUSTOMERS` | Customers from a list |
| `STATIC_TAG_LIST_CUSTOMERS` | Customers from tagged lists |

### Field Types
| Field Key | Description |
|-----------|-------------|
| `QUANTITATIVE_OPERATOR` | EXACTLY, MORE_THAN, LESS_THAN, BETWEEN |
| `QUANTITATIVE_VALUE_INTEGER` | Integer value |
| `QUANTITATIVE_VALUE_DECIMAL` | Decimal value |
| `DATE_OPERATOR` | ALL_TIME, LAST_N_DAYS, BETWEEN_DATES |
| `TIME_UNIT` | HOURS, DAYS, WEEKS, MONTHS |
| `VISIT_STATUS` | COMPLETED, CANCELLED, NO_SHOW |

## Frontend Architecture (bilt-frontend-mobile)

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Mobile App Data Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  useJourneyTemplates() ──▶ GET /journeys/templates              │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐                                           │
│  │  journeyStore   │◀─── createJourneyFromTemplate()           │
│  │  (State Mgmt)   │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ Template Detail │───▶│  Step Modals    │                    │
│  │    Screen       │    │ (audience/offer/│                    │
│  │                 │    │  message/email) │                    │
│  └─────────────────┘    └────────┬────────┘                    │
│                                  │                              │
│                                  ▼                              │
│                    useCreateJourney() ──▶ POST /journeys       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Path | Purpose |
|-----------|------|---------|
| `JourneyTemplateCard` | `components/journeys/cards/` | Template list card |
| `JourneyStepCard` | `components/journeys/cards/` | Step configuration card |
| `JourneyCard` | `components/journeys/cards/` | Active journey card |

### Key Hooks

| Hook | Path | Purpose |
|------|------|---------|
| `useJourneyTemplates` | `hooks/api/journeys/` | Fetch all templates |
| `useJourneyTemplateById` | `hooks/api/journeys/` | Fetch single template |
| `useJourneys` | `hooks/api/journeys/` | Fetch merchant's journeys |
| `useCreateJourney` | `hooks/api/journeys/` | Create journey instance |

### State Management

The `journeyStore` manages:
- Active journey being configured
- Template cache
- Step completion tracking
- Form state for each step type

## API Endpoints

### Templates
```
GET /portal-gateway/v1/journeys/templates?portal=merchant
GET /portal-gateway/v1/journeys/templates/{id}
```

### Journeys (CRUD)
```
POST /portal-gateway/v1/journeys
GET  /portal-gateway/v1/journeys?merchantId={id}
PUT  /portal-gateway/v1/journeys/{id}
DELETE /portal-gateway/v1/journeys/{id}
```

### Internal APIs (benefits-svc)
```
GET /internal/journey-service/v1/journeys/templates?portal={portal}
GET /internal/journey-service/v1/journeys/templates/{id}
POST /internal/journey-service/v1/merchant-groups/{id}/journeys
GET  /internal/journey-service/v1/merchant-groups/{id}/journeys
PUT  /internal/journey-service/v1/merchant-groups/{id}/journeys/{journeyId}
DELETE /internal/journey-service/v1/merchant-groups/{id}/journeys/{journeyId}
```

## Request/Response Structures

### Journey Creation Request
```json
{
  "journeyTemplateId": "uuid",
  "issuerMerchantGroupId": "uuid",
  "issuerMerchantId": "uuid",
  "name": "My Journey",
  "status": "DRAFT|LIVE",
  "audienceConfig": {
    "name": "Custom Audience",
    "rules": [/* TagRuleNode array */]
  },
  "offers": [{
    "merchantCatalogId": "uuid",
    "rewardType": "COMPLIMENTARY_ITEM",
    "rewardId": "uuid"
  }],
  "smsCampaigns": [{
    "textContent": "Message with {placeholders}",
    "campaignType": "EVENT",
    "visitTriggerType": "AFTER_VISIT"
  }],
  "emailCampaigns": [{/* ... */}]
}
```

### Template Response
```json
{
  "id": "uuid",
  "journeyType": "FIRST_TIME_GUESTS",
  "portal": "merchant",
  "name": "Turn first-time guests into regulars",
  "description": "...",
  "imageUrl": "https://...",
  "flow": {
    "id": "uuid",
    "steps": [
      {
        "stepType": "audience",
        "stepOrder": 1,
        "isRequired": true,
        "badgeLabel": "Audience",
        "defaultBody": [...]
      }
    ]
  },
  "audienceTemplate": {
    "id": "uuid",
    "name": "First time guests",
    "rules": [/* TagRuleNode array */]
  },
  "offerTemplates": [...],
  "smsCampaignTemplates": [...]
}
```
