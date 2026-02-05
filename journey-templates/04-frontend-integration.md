# Frontend Integration Guide

This guide covers how the mobile frontend (`bilt-frontend-mobile/apps/bilt-merchant-mobile`) integrates with the Journey Builder system.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Mobile App Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Screens                     State                   API        │
│  ┌─────────────────┐        ┌─────────────────┐                │
│  │ Journeys Tab    │───────▶│  journeyStore   │◀──────┐        │
│  │ (List)          │        │                 │       │        │
│  └────────┬────────┘        │ - journeys      │       │        │
│           │                 │ - templates     │       │        │
│           ▼                 │ - activeJourney │       │        │
│  ┌─────────────────┐        │ - loading states│       │        │
│  │ Template Detail │        └─────────────────┘       │        │
│  │ (Builder)       │                                  │        │
│  └────────┬────────┘                                  │        │
│           │                                           │        │
│           ▼                 ┌─────────────────────────┴───┐    │
│  ┌─────────────────┐        │      React Query Hooks      │    │
│  │  Step Modals    │───────▶│ - useJourneyTemplates       │    │
│  │ - Audience      │        │ - useJourneyTemplateById    │    │
│  │ - Offer         │        │ - useJourneys               │    │
│  │ - Message       │        │ - useCreateJourney          │    │
│  └─────────────────┘        └─────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## File Structure

```
bilt-frontend-mobile/apps/bilt-merchant-mobile/
├── app/main/
│   ├── (dashboard)/(store)/(tabs)/
│   │   └── journeys.tsx                    # Journey list screen
│   ├── journeys/
│   │   └── templates/
│   │       └── [id].tsx                    # Template detail/builder screen
│   └── modals/journeys/[id]/
│       ├── audience.tsx                    # Audience filter builder
│       ├── offer-select-type.tsx           # Reward type selection
│       ├── offer-builder.tsx               # Offer configuration
│       ├── messaging-campaign-type.tsx     # Campaign type selection
│       └── messaging-input.tsx             # Message composer
├── components/journeys/
│   ├── cards/
│   │   ├── JourneyCard.tsx                 # Active journey card
│   │   ├── JourneyStepCard.tsx             # Step configuration card
│   │   └── JourneyTemplateCard.tsx         # Template selection card
│   └── modals/
│       └── journey-name.tsx                # Journey naming modal
├── hooks/api/journeys/
│   ├── useJourneys.ts                      # Fetch merchant's journeys
│   ├── useJourneyTemplates.ts              # Fetch all templates
│   ├── useJourneyTemplateById.ts           # Fetch single template
│   └── useCreateJourney.ts                 # Create journey mutation
├── store/
│   └── journeyStore.ts                     # Journey state management
└── types/
    └── journeys.ts                         # TypeScript definitions
```

## TypeScript Types

### Core Types

**File:** `types/journeys.ts`

```typescript
// Journey type enum - must match backend JourneyType
export type JourneyType = 
  | 'FIRST_TIME_GUESTS' 
  | 'LOW_REVIEW_ENGAGEMENT' 
  | 'BUSINESS_ACROSS_LOCATIONS'
  | 'FLEXIBLE_JOURNEY';  // Add new types here

export type JourneyStatus = 'DRAFT' | 'LIVE' | 'COMPLETED' | 'ARCHIVED';

export type JourneyStepType = 'audience' | 'offer' | 'message' | 'email';

// Template from API
export type JourneyTemplate = {
  id: string;
  type: JourneyType;
  portal: string;
  name: string;
  description: string;
  imageUrl: string;
  flow: JourneyBuilderFlow;
  audienceTemplate: JourneyAudienceTemplate;
  offerTemplates: JourneyOfferTemplate[];
  smsCampaignTemplates: JourneySmsCampaignTemplate[];
  emailCampaignTemplates: JourneyEmailCampaignTemplate[];
};

// Builder flow configuration
export type JourneyBuilderFlow = {
  id: string;
  backgroundImageUrl: string;
  title: string;
  description: string;
  steps: JourneyStep[];
  isRewardSelectionRequired?: boolean;
};

// Individual step in the flow
export type JourneyStep = {
  id: string;
  stepId: string;
  stepType: JourneyStepType;
  showMerchantSelector?: boolean;
  stepOrder: number;
  isRequired: boolean;
  badgeLabel: string;
  badgeIcon?: string;
  defaultBody: JourneyStepBody[];
  body: JourneyStepBody[];
  builderEntrypoint?: string;
};

// Step body content item
export type JourneyStepBody = {
  empty: boolean;
  map: {
    order: number;
    icon?: string;
    value: string | React.ReactNode;
  };
};
```

### Audience Types

```typescript
// Audience template from API (uses TagRuleNode format)
export type JourneyAudienceTemplate = {
  id: string;
  name: string;
  description: string;
  rules: TagRuleNode[];  // Backend v2 format
};

// Runtime audience state (during configuration)
export type JourneyAudienceState = {
  selectedTags: string[];
  filters: (TagOption & { isPrefilled?: boolean })[];
  audienceCount: number;
};
```

### Offer/Campaign Types

```typescript
export type OfferRewardType = 'COMPLIMENTARY_ITEM' | 'DISCOUNT';

export type JourneyOffer = {
  name: string;
  merchant?: Merchant | null;
  rewardId?: string;
  rewardType?: OfferRewardType;
  rewardCreationRequest?: CreateRewardRequest;
  startTime?: string;
  endTime?: string;
  maxTransactionsForOffer?: number;
  maxTransactionsPerUser?: number;
  fulfillmentMessageContent?: string;
};

export type JourneyOfferTemplate = {
  id: string;
  journeyTemplateId: string;
  name: string;
  description: string;
  rewardType: OfferRewardType;
  rewardMessage: object;
  showRewardMessage: boolean;
};
```

## State Management

### Journey Store

**File:** `store/journeyStore.ts`

The store manages:
- Templates fetched from API
- Active journey being configured
- Step completion tracking
- Form state for each step

```typescript
interface JourneyStoreState {
  journeys: Record<string, Journey>;
  templates: Record<string, JourneyTemplate>;
  activeJourneyId: string | null;
  isLoading: boolean;
  isCreating: boolean;
  isUpdating: boolean;
  isDeleting: boolean;
  isFetchingTemplates: boolean;
  error?: string;
}

// Key actions
type JourneyStoreAction =
  | { type: 'SET_JOURNEYS'; journeys: Journey[] }
  | { type: 'CREATE_JOURNEY'; journey: Journey }
  | { type: 'UPDATE_JOURNEY'; journeyId: string; updates: Partial<Journey> }
  | { type: 'DELETE_JOURNEY'; journeyId: string }
  | { type: 'SET_TEMPLATES'; templates: JourneyTemplate[] }
  | { type: 'SET_ACTIVE_JOURNEY'; journeyId: string | null }
  | { type: 'MARK_STEP_TOUCHED'; journeyId: string; stepType: JourneyStepType }
  | { type: 'UPDATE_AUDIENCE'; journeyId: string; audience: JourneyAudienceState }
  | { type: 'UPDATE_OFFERS'; journeyId: string; offers: JourneyOffer[] }
  | { type: 'UPDATE_SMS_CAMPAIGNS'; journeyId: string; campaigns: JourneySmsCampaignFormData[] }
  // ... etc
```

### Creating Journey from Template

```typescript
export function createJourneyFromTemplate(
  template: JourneyTemplate,
  merchant: Merchant,
  phoneNumber: string,
  tagOptions: TagOption[]
): Journey {
  // Convert audience rules from TagRuleNode[] to TagOption[]
  const prefilledFilters = convertTagAttributesToFilterV2(
    template.audienceTemplate.rules,
    tagOptions
  ).map(filter => ({ ...filter, isPrefilled: true }));

  return {
    id: generateUUID(),
    merchant,
    merchantPhoneNumber: phoneNumber,
    type: template.type,
    status: 'DRAFT',
    name: template.name,
    audienceConfig: template.audienceTemplate,
    template,
    audience: {
      selectedTags: [],
      filters: prefilledFilters,
      audienceCount: 0,
    },
    offers: [],
    smsCampaigns: [],
    emailCampaigns: [],
    touchedSteps: [],
  };
}
```

## API Hooks

### Fetch Templates

**File:** `hooks/api/journeys/useJourneyTemplates.ts`

```typescript
export default function useJourneyTemplates(options: { isAdmin?: boolean } = {}) {
  return useQuery<JourneyTemplate[]>({
    queryKey: ['journey-templates'],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.append('portal', 'merchant');
      
      const response = await authenticatedApiRequest<{ templates: JourneyTemplate[] }>(
        `/portal-gateway/v1/journeys/templates?${params}`
      );
      
      return response.templates;
    },
    enabled: options.isAdmin ?? false,
  });
}
```

### Create Journey

**File:** `hooks/api/journeys/useCreateJourney.ts`

```typescript
export function buildCreateJourneyRequest(journey: Journey): CreateJourneyRequest {
  return {
    journeyTemplateId: journey.template.id,
    issuerMerchantGroupId: journey.merchant.merchantGroupId,
    issuerMerchantId: journey.merchant.merchantCatalogId,
    name: journey.name,
    status: journey.status,
    audienceConfig: {
      name: journey.audienceConfig.name,
      rules: convertFiltersToTagRuleNodes(journey.audience.filters),
    },
    offers: journey.offers.map(offer => ({
      merchantCatalogId: offer.merchant?.merchantCatalogId,
      rewardType: offer.rewardType,
      rewardId: offer.rewardId,
      rewardCreationRequest: offer.rewardCreationRequest,
      // ... other fields
    })),
    smsCampaigns: journey.smsCampaigns.map(campaign => ({
      textContent: campaign.textContent,
      campaignType: 'EVENT',
      visitTriggerType: campaign.visitTriggerType,
      // ... other fields
    })),
  };
}

export default function useCreateJourney() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (request: CreateJourneyRequest) => {
      return authenticatedApiRequest<Journey>(
        '/portal-gateway/v1/journeys',
        { method: 'POST', body: JSON.stringify(request) }
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}
```

## Screen Components

### Template Detail Screen

**File:** `app/main/journeys/templates/[id].tsx`

This is the main builder screen. Key responsibilities:

1. **Fetch template** via `useJourneyTemplateById`
2. **Initialize journey** via `createJourneyFromTemplate`
3. **Render steps** from `template.flow.steps`
4. **Handle step navigation** based on `stepType`
5. **Track completion** via `touchedSteps`
6. **Create journey** via `useCreateJourney`

```typescript
export default function JourneyTemplateDetailsScreen() {
  const { id } = useLocalSearchParams();
  const { data: template } = useJourneyTemplateById(id as string);
  const journeyActions = useJourneyStoreActions();
  const activeJourney = useActiveJourney();
  const createJourneyMutation = useCreateJourney();
  
  // Initialize journey when template loads
  useEffect(() => {
    if (template && selectedMerchant) {
      const newJourney = createJourneyFromTemplate(template, selectedMerchant, phoneNumber, tagOptions);
      journeyActions.createJourney(newJourney);
      journeyActions.setActiveJourney(newJourney.id);
    }
  }, [template, selectedMerchant]);

  // Handle step press - navigate to appropriate modal
  const handleStepPress = useCallback((step: JourneyStep, stepIndex: number) => {
    if (!activeJourney || !isStepEnabled(stepIndex)) return;
    
    journeyActions.markStepTouched(activeJourney.id, step.stepType);
    
    switch (step.stepType) {
      case 'audience':
        navigate(`/main/modals/journeys/${id}/audience`);
        break;
      case 'offer':
        if (template?.flow.isRewardSelectionRequired) {
          navigate(`/main/modals/journeys/${id}/offer-select-type`);
        } else {
          navigate(`/main/modals/journeys/${id}/offer-builder`);
        }
        break;
      case 'message':
        navigate(`/main/modals/journeys/${id}/messaging-campaign-type`);
        break;
    }
  }, [activeJourney, template]);

  // Render steps
  return (
    <View>
      {template.flow.steps.map((step, index) => (
        <JourneyStepCard
          key={step.id}
          badgeLabel={step.badgeLabel}
          badgeIcon={step.badgeIcon}
          body={getStepBody(step)}
          onPress={() => handleStepPress(step, index)}
          disabled={!isStepEnabled(index)}
          touched={activeJourney?.touchedSteps.includes(step.stepType)}
        />
      ))}
      <Button
        content="Launch Journey"
        onPress={handleCreateJourney}
        isDisabled={!allStepsCompleted}
      />
    </View>
  );
}
```

### Step Body Rendering

The `getStepBody` function transforms step templates into display content:

```typescript
const getStepBody = useCallback((step: JourneyStep): JourneyStepCardBody[] => {
  if (!activeJourney) return step.defaultBody;

  switch (step.stepType) {
    case 'audience': {
      // Show configured filters
      const filtersBody = activeJourney.audience.filters.map((filter, i) => ({
        empty: false,
        map: {
          order: i,
          icon: filter.displayIcon,
          value: <FilterDescription filter={filter} />,
        },
      }));
      return [...step.defaultBody, ...filtersBody];
    }
    
    case 'offer': {
      const offer = activeJourney.offers?.[0];
      if (!offer) return step.defaultBody;
      
      // Replace placeholders with actual values
      return step.body.map(item => ({
        ...item,
        map: {
          ...item.map,
          value: item.map.value
            .replace('{reward.name}', offer.name)
            .replace('{reward.config.itemName}', offer.name),
        },
      }));
    }
    
    case 'message': {
      const campaign = activeJourney.smsCampaigns?.[0];
      if (!campaign) return step.defaultBody;
      
      return step.body.map(item => ({
        ...item,
        map: {
          ...item.map,
          value: item.map.value
            .replace('{campaign.schedule}', getCampaignTimingSummary(campaign))
            .replace('{campaign.textContent}', campaign.textContent),
        },
      }));
    }
    
    default:
      return step.defaultBody;
  }
}, [activeJourney]);
```

## Adding Support for New Template Types

When adding a new journey type (e.g., `FLEXIBLE_JOURNEY`), the frontend typically requires minimal changes because it's data-driven. However, you may need to:

### 1. Add TypeScript Type

```typescript
// types/journeys.ts
export type JourneyType = 
  | 'FIRST_TIME_GUESTS' 
  // ... existing types
  | 'FLEXIBLE_JOURNEY';  // ADD
```

### 2. Handle Special Cases (if any)

If your template has unique behavior, handle it in the step press handler:

```typescript
case 'offer': {
  const isRewardSelectionRequired = template?.flow.isRewardSelectionRequired;
  
  // FLEXIBLE_JOURNEY sets isRewardSelectionRequired = true
  // so it goes through the full selection flow
  if (isRewardSelectionRequired) {
    navigate(`/main/modals/journeys/${id}/offer-select-type`);
  } else {
    // Other templates may have pre-configured reward type
    const entrypointUrl = step.builderEntrypoint;
    const rewardTypeId = new URLSearchParams(entrypointUrl?.split('?')[1]).get('rewardTypeId');
    
    if (rewardTypeId) {
      offerBuilderActions.setRewardType({ id: rewardTypeId });
    }
    navigate(`/main/modals/journeys/${id}/offer-builder`);
  }
  break;
}
```

### 3. Customize Step Modals (if needed)

For `FLEXIBLE_JOURNEY` or other flexible templates:
- **Audience modal**: Starts with empty filters (no prefilled rules)
- **Offer modal**: Shows full reward type selection
- **Message modal**: Starts with campaign type selection (not pre-composed)

These behaviors are already built into the existing modals - they check for the presence of template data and adjust accordingly.

## Testing Checklist

### Unit Tests
- [ ] `journeyStore` reducer handles all action types
- [ ] `createJourneyFromTemplate` correctly initializes journey
- [ ] `buildCreateJourneyRequest` produces valid API payload
- [ ] Step body rendering handles all placeholders

### Integration Tests
- [ ] Template list renders from API response
- [ ] Template detail screen initializes journey state
- [ ] Audience step navigates to filter builder
- [ ] Offer step respects `isRewardSelectionRequired` flag
- [ ] Message step navigates correctly
- [ ] Journey creation succeeds and refreshes list

### Manual E2E Tests
1. Navigate to Journeys tab
2. Verify templates load and display correctly
3. Tap a template card
4. Verify template detail screen shows steps
5. Configure each step in order
6. Verify step cards update with configured values
7. Launch journey
8. Verify success and journey appears in list
