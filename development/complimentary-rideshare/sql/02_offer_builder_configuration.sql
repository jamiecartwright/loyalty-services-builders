-- ============================================================================
-- COMPLIMENTARY RIDESHARE: OFFER BUILDER CONFIGURATION
-- ============================================================================
-- This SQL configures the offer builder flows, steps, and elements for the
-- complimentary rideshare reward types.
--
-- PREREQUISITES:
--   - Schema changes from 01_schema_changes.sql must be applied first
--   - synthetic_reward_type_groups table must exist
--   - Both rideshare reward types must exist:
--     - complimentary_ride_to_merchant (5828f406-c7fe-4125-ab3b-d594a8d0a0a7)
--     - complimentary_ride_from_merchant (b2c3d4e5-f6a7-8901-bcde-f23456789012)
--
-- Related tickets:
--   MR-2544: Create offer builder flows for rideshare types
-- ============================================================================

-- ============================================================================
-- CONSTANTS (for readability)
-- ============================================================================
-- Reward Type IDs
-- TO_MERCHANT_ID = '5828f406-c7fe-4125-ab3b-d594a8d0a0a7'
-- FROM_MERCHANT_ID = 'b2c3d4e5-f6a7-8901-bcde-f23456789012'

-- ============================================================================
-- PART 1: REUSABLE STEPS
-- ============================================================================
-- Check if these steps already exist; create only if needed

-- reward_configuration step (for car type and max cost selection)
INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT 
    'rs-step-reward-config-001',
    'reward_configuration',
    'What kind of ride experience do you want to offer?'
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_steps WHERE step_type = 'reward_configuration'
);

-- program_settings step (reuse existing if available)
-- This should already exist from other flows

-- messaging_sms step for TO variant
INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT 
    'rs-step-messaging-to-001',
    'messaging_sms_rideshare_to',
    'Create a personalized SMS to send when guests are on their way'
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_steps WHERE step_type = 'messaging_sms_rideshare_to'
);

-- messaging_sms step for FROM variant  
INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT 
    'rs-step-messaging-from-001',
    'messaging_sms_rideshare_from',
    'Create a personalized SMS to send when guests receive their complimentary ride'
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_steps WHERE step_type = 'messaging_sms_rideshare_from'
);

-- confirmation step (reuse existing)
-- success_handoff step (reuse existing)

-- ============================================================================
-- PART 2: REUSABLE ELEMENTS
-- ============================================================================

-- Eligible car types selector (multi-select cards with images)
INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 
    'rs-elem-car-types-001',
    'eligible_car_types',
    'multi_select_card',
    'Eligible car types',
    NULL,
    'Select which ride tiers guests can book',
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_elements WHERE internal_name = 'eligible_car_types'
);

-- Car type options (with descriptions)
INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, description, option_order, icon)
SELECT 
    'rs-opt-car-standard',
    (SELECT id FROM offer_builder_elements WHERE internal_name = 'eligible_car_types'),
    'standard',
    'Standard',
    'A standard car for regular fares',
    1,
    NULL  -- TODO: Add image URL once hosted
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options 
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'eligible_car_types')
    AND option_value = 'standard'
);

INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, description, option_order, icon)
SELECT 
    'rs-opt-car-black',
    (SELECT id FROM offer_builder_elements WHERE internal_name = 'eligible_car_types'),
    'black',
    'Black / Black XL',
    'Luxury rides, professional drivers',
    2,
    NULL  -- TODO: Add image URL once hosted
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options 
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'eligible_car_types')
    AND option_value = 'black'
);

INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, description, option_order, icon)
SELECT 
    'rs-opt-car-premium',
    (SELECT id FROM offer_builder_elements WHERE internal_name = 'eligible_car_types'),
    'premium',
    'Premium (Chauffeur Service)',
    'White glove chauffeur experience',
    3,
    NULL  -- TODO: Add image URL once hosted
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options 
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'eligible_car_types')
    AND option_value = 'premium'
);

-- Maximum ride cost toggle
INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 
    'rs-elem-max-cost-toggle-001',
    'max_ride_cost_enabled',
    'toggle',
    'Maximum ride cost',
    NULL,
    'Set the maximum cost covered of any complementary ride',
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_elements WHERE internal_name = 'max_ride_cost_enabled'
);

-- Maximum ride cost amount (conditional on toggle)
INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 
    'rs-elem-max-cost-amount-001',
    'max_ride_cost_amount',
    'currency',
    NULL,
    '$ 100',
    NULL,
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_elements WHERE internal_name = 'max_ride_cost_amount'
);

-- Offer partial credit checkbox (conditional on toggle)
INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 
    'rs-elem-partial-credit-001',
    'offer_partial_credit',
    'checkbox',
    'Offer partial credit if ride exceeds maximum ride cost',
    NULL,
    NULL,
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_elements WHERE internal_name = 'offer_partial_credit'
);

-- ============================================================================
-- PART 3: FLOWS - RIDE TO MERCHANT
-- ============================================================================

-- Mobile/Full flow
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-mobile-full', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'mobile', 'full');

-- Mobile/Full Journey flow
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-mobile-journey', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'mobile', 'full_journey');

-- Mobile/Single User Instant
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-mobile-instant', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'mobile', 'single_user_instant');

-- Mobile/Single User Deferred
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-mobile-deferred', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'mobile', 'single_user_deferred');

-- Web/Full
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-web-full', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'web', 'full');

-- Web/Single User Instant
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-web-instant', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'web', 'single_user_instant');

-- Web/Single User Deferred
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-to-web-deferred', '5828f406-c7fe-4125-ab3b-d594a8d0a0a7', 'web', 'single_user_deferred');

-- ============================================================================
-- PART 4: FLOWS - RIDE FROM MERCHANT
-- ============================================================================

-- Mobile/Full flow
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-mobile-full', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'mobile', 'full');

-- Mobile/Full Journey flow
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-mobile-journey', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'mobile', 'full_journey');

-- Mobile/Single User Instant
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-mobile-instant', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'mobile', 'single_user_instant');

-- Mobile/Single User Deferred
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-mobile-deferred', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'mobile', 'single_user_deferred');

-- Web/Full
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-web-full', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'web', 'full');

-- Web/Single User Instant
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-web-instant', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'web', 'single_user_instant');

-- Web/Single User Deferred
INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES ('rs-flow-from-web-deferred', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'web', 'single_user_deferred');

-- ============================================================================
-- PART 5: FLOW STEPS - RIDE TO MERCHANT (Mobile/Full example)
-- ============================================================================
-- Note: This pattern should be repeated for all flows. 
-- The step_id references need to be looked up from existing steps or 
-- the new steps created in Part 1.

-- For brevity, showing the mobile/full flow as template:

-- Step 1: Reward Configuration
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES (
    'rs-fstep-to-mf-1',
    'rs-flow-to-mobile-full',
    'rs-step-reward-config-001',  -- References the reward_configuration step
    1,
    TRUE,
    FALSE,
    FALSE,  -- First step, no back navigation
    TRUE
);

-- Step 2: Audience Definition (standalone flows only - journey flows skip this)
-- TODO: Reference existing audience_definition step_id
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES (
    'rs-fstep-to-mf-2',
    'rs-flow-to-mobile-full',
    (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1),
    2,
    TRUE,
    FALSE,
    TRUE,
    TRUE
);

-- Step 3: Program Settings
-- TODO: Reference existing program_settings step_id
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES (
    'rs-fstep-to-mf-3',
    'rs-flow-to-mobile-full',
    (SELECT id FROM offer_builder_steps WHERE step_type = 'program_settings' LIMIT 1),
    3,
    TRUE,
    FALSE,
    TRUE,
    TRUE
);

-- Step 4: Messaging (TO variant)
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES (
    'rs-fstep-to-mf-4',
    'rs-flow-to-mobile-full',
    'rs-step-messaging-to-001',
    4,
    TRUE,
    FALSE,
    TRUE,
    TRUE
);

-- Step 5: Confirmation
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES (
    'rs-fstep-to-mf-5',
    'rs-flow-to-mobile-full',
    (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1),
    5,
    TRUE,
    FALSE,
    TRUE,
    TRUE
);

-- Step 6: Success Handoff
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES (
    'rs-fstep-to-mf-6',
    'rs-flow-to-mobile-full',
    (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1),
    6,
    FALSE,
    FALSE,
    FALSE,  -- No back from success
    TRUE
);

-- ============================================================================
-- PART 6: FLOW STEP ELEMENTS - Reward Configuration Step
-- ============================================================================

-- Eligible car types selector
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES (
    'rs-fse-car-types-001',
    'rs-fstep-to-mf-1',  -- Reward configuration step
    'rs-elem-car-types-001',
    1,
    TRUE,
    TRUE,
    NULL,
    NULL
);

-- Maximum ride cost toggle
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES (
    'rs-fse-max-cost-toggle-001',
    'rs-fstep-to-mf-1',
    'rs-elem-max-cost-toggle-001',
    2,
    FALSE,
    TRUE,
    'true',  -- Default ON
    NULL
);

-- Maximum ride cost amount (conditional on toggle)
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES (
    'rs-fse-max-cost-amount-001',
    'rs-fstep-to-mf-1',
    'rs-elem-max-cost-amount-001',
    3,
    FALSE,
    FALSE,  -- Hidden by default, shown when toggle is ON
    '100',
    '{"showWhen": {"field": "max_ride_cost_enabled", "equals": "true"}}'::jsonb
);

-- Offer partial credit checkbox (conditional on toggle)
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES (
    'rs-fse-partial-credit-001',
    'rs-fstep-to-mf-1',
    'rs-elem-partial-credit-001',
    4,
    FALSE,
    FALSE,  -- Hidden by default, shown when toggle is ON
    'true',  -- Default checked
    '{"showWhen": {"field": "max_ride_cost_enabled", "equals": "true"}}'::jsonb
);

-- ============================================================================
-- REMAINING WORK (TODO)
-- ============================================================================
-- 
-- The following needs to be completed but requires:
-- 1. Looking up exact IDs for existing reusable steps/elements
-- 2. Creating flow_steps for all 14 flows (7 TO + 7 FROM)
-- 3. Creating flow_step_elements for each step
--
-- Pattern for full_journey flows:
--   - Add 'journey_guidance' display_block as first element in each step
--   - Add 'skip_reward' button as last element in configurable steps
--
-- Query to find existing step IDs:
-- SELECT id, step_type, default_title FROM offer_builder_steps;
--
-- Query to find existing element IDs:
-- SELECT id, internal_name, internal_type FROM offer_builder_elements;
-- ============================================================================

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check flows created
SELECT 
    f.id as flow_id,
    srt.internal_name as reward_type,
    f.platform,
    f.audience_type
FROM offer_builder_flows f
JOIN synthetic_reward_types srt ON f.synthetic_reward_type_id = srt.id
WHERE srt.internal_name LIKE 'complimentary_ride%'
ORDER BY srt.internal_name, f.platform, f.audience_type;

-- Check steps in a flow
SELECT 
    fs.step_order,
    s.step_type,
    s.default_title,
    fs.is_required,
    fs.is_skip_allowed
FROM offer_builder_flow_steps fs
JOIN offer_builder_steps s ON fs.step_id = s.id
WHERE fs.flow_id = 'rs-flow-to-mobile-full'
ORDER BY fs.step_order;

-- Check elements in a step
SELECT 
    fse.element_order,
    e.internal_name,
    e.internal_type,
    fse.is_required,
    fse.is_visible,
    fse.conditional_logic
FROM offer_builder_flow_step_elements fse
JOIN offer_builder_elements e ON fse.element_id = e.id
WHERE fse.flow_step_id = 'rs-fstep-to-mf-1'
ORDER BY fse.element_order;
