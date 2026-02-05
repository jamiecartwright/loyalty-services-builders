-- ============================================================================
-- COMPLIMENTARY RIDESHARE: LOOKUP QUERIES & COMPLETION GUIDE
-- ============================================================================
-- Run these queries to find existing IDs needed to complete the configuration.
-- Then use the results to fill in the TODOs in 02_offer_builder_configuration.sql
-- ============================================================================

-- ============================================================================
-- STEP 1: Find existing reusable steps
-- ============================================================================

-- Get all existing step types and their IDs
SELECT id, step_type, default_title 
FROM offer_builder_steps 
ORDER BY step_type;

-- Expected existing steps we can reuse:
-- - audience_definition (for standalone flows)
-- - program_settings
-- - confirmation  
-- - success_handoff
-- - messaging (generic)

-- ============================================================================
-- STEP 2: Find existing reusable elements
-- ============================================================================

-- Get all existing elements and their IDs
SELECT id, internal_name, internal_type, default_label
FROM offer_builder_elements
ORDER BY internal_type, internal_name;

-- Expected existing elements we can reuse:
-- - max_redemptions_per_person (select)
-- - max_redemptions (number)
-- - offer_duration_start (datetime)
-- - offer_duration_end (datetime)
-- - message_content (text_box)
-- - offer_name (text)
-- - input_summary (itemized_list)
-- - create_offer (button)
-- - journey_guidance (display_block) - for full_journey flows

-- ============================================================================
-- STEP 3: Find existing element options
-- ============================================================================

-- Get options for max_redemptions_per_person selector
SELECT 
    eo.id,
    eo.option_value,
    eo.default_label,
    eo.option_order,
    e.internal_name as element_name
FROM offer_builder_element_options eo
JOIN offer_builder_elements e ON eo.element_id = e.id
WHERE e.internal_name = 'max_redemptions_per_person'
ORDER BY eo.option_order;

-- ============================================================================
-- STEP 4: Reference an existing similar flow
-- ============================================================================

-- Look at neighborhood_discount flow structure as reference
SELECT 
    f.id as flow_id,
    srt.internal_name as reward_type,
    f.platform,
    f.audience_type
FROM offer_builder_flows f
JOIN synthetic_reward_types srt ON f.synthetic_reward_type_id = srt.id
WHERE srt.internal_name = 'neighborhood_discount'
  AND f.platform = 'mobile'
  AND f.audience_type = 'full';

-- Get steps for that flow
SELECT 
    fs.id as flow_step_id,
    fs.step_order,
    s.id as step_id,
    s.step_type,
    s.default_title,
    fs.is_required,
    fs.is_skip_allowed
FROM offer_builder_flow_steps fs
JOIN offer_builder_steps s ON fs.step_id = s.id
JOIN offer_builder_flows f ON fs.flow_id = f.id
JOIN synthetic_reward_types srt ON f.synthetic_reward_type_id = srt.id
WHERE srt.internal_name = 'neighborhood_discount'
  AND f.platform = 'mobile'
  AND f.audience_type = 'full'
ORDER BY fs.step_order;

-- Get elements for each step (run for each flow_step_id from above)
-- Replace 'FLOW_STEP_ID_HERE' with actual ID
/*
SELECT 
    fse.element_order,
    e.id as element_id,
    e.internal_name,
    e.internal_type,
    e.default_label,
    fse.is_required,
    fse.is_visible,
    fse.default_value,
    fse.conditional_logic
FROM offer_builder_flow_step_elements fse
JOIN offer_builder_elements e ON fse.element_id = e.id
WHERE fse.flow_step_id = 'FLOW_STEP_ID_HERE'
ORDER BY fse.element_order;
*/

-- ============================================================================
-- COMPLETION TEMPLATE
-- ============================================================================
-- Once you have the IDs, use this template to complete the configuration:

/*
-- FLOW STEPS for STANDALONE (full) flows - 6 steps including audience:
-- Copy this block for each standalone flow, replacing:
--   - {FLOW_ID} with the flow ID (e.g., 'rs-flow-to-mobile-full')
--   - {STEP_ID_*} with actual step IDs from Step 1 above

INSERT INTO offer_builder_flow_steps 
    (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES 
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_REWARD_CONFIG}', 1, TRUE, FALSE, FALSE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_AUDIENCE_DEFINITION}', 2, TRUE, FALSE, TRUE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_PROGRAM_SETTINGS}', 3, TRUE, FALSE, TRUE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_MESSAGING}', 4, TRUE, FALSE, TRUE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_CONFIRMATION}', 5, TRUE, FALSE, TRUE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_SUCCESS}', 6, FALSE, FALSE, FALSE, TRUE);

-- FLOW STEPS for JOURNEY (full_journey) flows - NO audience step:
-- Journey flows don't include audience_definition because the journey defines the audience

INSERT INTO offer_builder_flow_steps 
    (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible)
VALUES 
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_REWARD_CONFIG}', 1, TRUE, TRUE, FALSE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_PROGRAM_SETTINGS}', 2, TRUE, TRUE, TRUE, TRUE),
    (gen_random_uuid(), '{FLOW_ID}', '{STEP_ID_MESSAGING}', 3, TRUE, TRUE, TRUE, TRUE);

-- FLOW STEP ELEMENTS - Reward Configuration step
-- Replace {FLOW_STEP_ID} with actual flow_step ID for reward_config step

INSERT INTO offer_builder_flow_step_elements
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES
    -- Eligible car types selector (multi-select with images)
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_ELIGIBLE_CAR_TYPES}', 1, TRUE, TRUE, NULL, NULL),
    -- Maximum ride cost toggle
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_MAX_RIDE_COST_ENABLED}', 2, FALSE, TRUE, 'true', NULL),
    -- Maximum ride cost amount (conditional on toggle)
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_MAX_RIDE_COST_AMOUNT}', 3, FALSE, FALSE, '100', 
        '{"showWhen": {"field": "max_ride_cost_enabled", "equals": "true"}}'),
    -- Offer partial credit checkbox (conditional on toggle)
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_OFFER_PARTIAL_CREDIT}', 4, FALSE, FALSE, 'true',
        '{"showWhen": {"field": "max_ride_cost_enabled", "equals": "true"}}');

-- FLOW STEP ELEMENTS - Audience Definition step (standalone flows only)
-- Replace {FLOW_STEP_ID} with actual flow_step ID for audience_definition step

INSERT INTO offer_builder_flow_step_elements
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES
    -- Audience selector (tag selector, segment builder, etc.)
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_AUDIENCE_SELECTOR}', 1, TRUE, TRUE, NULL, NULL),
    -- Audience count display
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_AUDIENCE_COUNT}', 2, FALSE, TRUE, NULL, NULL);

-- FLOW STEP ELEMENTS - Program Settings step
-- Use existing element IDs from Step 2 above

INSERT INTO offer_builder_flow_step_elements
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_MAX_REDEMPTIONS_PER_PERSON}', 1, FALSE, TRUE, NULL, NULL),
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_MAX_REDEMPTIONS}', 2, FALSE, TRUE, NULL, NULL),
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_DURATION_START}', 3, FALSE, TRUE, NULL, NULL),
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_DURATION_END}', 4, FALSE, TRUE, NULL, NULL);

-- FLOW STEP ELEMENTS - Messaging step
INSERT INTO offer_builder_flow_step_elements
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_MESSAGE_CONTENT}', 1, FALSE, TRUE, NULL, NULL);

-- FLOW STEP ELEMENTS - Confirmation step
INSERT INTO offer_builder_flow_step_elements
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_OFFER_NAME}', 1, TRUE, TRUE, NULL, NULL),
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_INPUT_SUMMARY}', 2, FALSE, TRUE, NULL, NULL),
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_CREATE_OFFER}', 3, FALSE, TRUE, NULL, NULL);

-- Success step typically has no input elements

*/

-- ============================================================================
-- FULL_JOURNEY VARIANT NOTES
-- ============================================================================
-- For full_journey flows, each step should have:
-- 1. journey_guidance display_block as FIRST element (shows context about the journey)
-- 2. skip_reward button as LAST element (allows skipping this step in the journey)
--
-- Example:
/*
INSERT INTO offer_builder_flow_step_elements
    (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, conditional_logic)
VALUES
    -- Journey guidance (first)
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_JOURNEY_GUIDANCE}', 1, FALSE, TRUE, NULL, NULL),
    -- ... other elements ...
    -- Skip button (last)
    (gen_random_uuid(), '{FLOW_STEP_ID}', '{ELEM_ID_SKIP_REWARD}', 99, FALSE, TRUE, NULL, NULL);
*/
