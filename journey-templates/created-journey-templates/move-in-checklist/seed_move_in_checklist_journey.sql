-- ============================================================
-- MOVE_IN_CHECKLIST Journey Template + Offer Builder Migration
-- ============================================================
-- Creates a property-portal journey template for move-in checklists,
-- backed by fully configured offer builder flows.
--
-- Each checklist task type has its own synthetic_reward_type and
-- offer builder flow. The flow guides the property manager through:
--   1. Task setup (name, description, required toggle)
--   2. Audience selection
--   3. Action configuration (placeholder — other team implements)
--   4. Review & save
--   5. Success screen
--
-- Checklist task types:
--   1. Confirm Lease Signing
--   2. Set Up Autopay
--   3. Get Renters Insurance
--   4. Set Up Utilities (generic — covers any freeform task)
--   5. Upload Document
-- ============================================================


-- ============================================================
-- PART 1: SYNTHETIC REWARD TYPE GROUP
-- ============================================================

INSERT INTO synthetic_reward_type_groups
  (id, internal_name, external_label, description, icon, display_rank, issuer_type, is_enabled)
VALUES
  ('f6060606-0001-4000-8000-000000000001',
   'move_in_checklist_tasks',
   'Move-In Checklist Tasks',
   'Checklist tasks that new residents complete during move-in',
   'checklist-regular',
   1,
   'PROPERTY',
   TRUE);


-- ============================================================
-- PART 2: SYNTHETIC REWARD TYPES (one per action)
-- ============================================================

INSERT INTO synthetic_reward_types
  (id, internal_name, external_label, description, icon,
   value_type, bilt_category, value_format, currency,
   issuer_type, is_enabled, display_rank, group_id)
VALUES
  ('f6060606-1001-4000-8000-000000000001',
   'checklist_lease_signing', 'Lease Signing',
   'Confirm the resident has signed their lease',
   'file-text-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 1, 'f6060606-0001-4000-8000-000000000001'),

  ('f6060606-1002-4000-8000-000000000002',
   'checklist_autopay_setup', 'Autopay Setup',
   'Set up automatic rent payments',
   'credit-card-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 2, 'f6060606-0001-4000-8000-000000000001'),

  ('f6060606-1003-4000-8000-000000000003',
   'checklist_renters_insurance', 'Renters Insurance',
   'Obtain renters insurance for the unit',
   'shield-check-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 3, 'f6060606-0001-4000-8000-000000000001'),

  ('f6060606-1004-4000-8000-000000000004',
   'checklist_utilities_setup', 'Utilities Setup',
   'Transfer or set up utility accounts',
   'lightning-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 4, 'f6060606-0001-4000-8000-000000000001'),

  ('f6060606-1005-4000-8000-000000000005',
   'checklist_document_upload', 'Document Upload',
   'Upload a required document such as proof of insurance',
   'upload-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 5, 'f6060606-0001-4000-8000-000000000001');


-- ============================================================
-- PART 3: OFFER BUILDER STEPS (reusable)
-- ============================================================

INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT 'f6060606-2001-4000-8000-000000000001',
       'checklist_task_setup',
       'Create your move-in task'
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_steps WHERE step_type = 'checklist_task_setup'
);

INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT 'f6060606-2002-4000-8000-000000000001',
       'action_configuration',
       'Configure task details'
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_steps WHERE step_type = 'action_configuration'
);


-- ============================================================
-- PART 4: OFFER BUILDER ELEMENTS (reusable)
-- ============================================================

-- 4a: New checklist-specific elements

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 'f6060606-3001-4000-8000-000000000001',
       'task_name', 'text', 'Task name', 'e.g. Sign your lease',
       'The name residents will see for this checklist task', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'task_name');

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 'f6060606-3002-4000-8000-000000000001',
       'task_description', 'text_box', 'Description', 'Describe what the resident needs to do',
       'A brief description of the task shown to residents', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'task_description');

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 'f6060606-3003-4000-8000-000000000001',
       'is_completion_required', 'switch', 'Is Completion Required?', null,
       'Whether residents must complete this task', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'is_completion_required');

-- Options for is_completion_required switch
INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, option_order)
SELECT 'f6060606-3003-4000-8000-000000000101',
       (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1),
       'true', 'Required', 1
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1)
    AND option_value = 'true'
);

INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, option_order)
SELECT 'f6060606-3003-4000-8000-000000000102',
       (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1),
       'false', 'Optional', 2
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1)
    AND option_value = 'false'
);

-- 4b: Standard elements used by audience + confirmation steps.
-- These exist in production (F&F discount flow); create only if missing.

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input, option_source_link)
SELECT 'f6060606-3010-4000-8000-000000000001',
       'audience_selection', 'switch', 'Audience Type', null,
       'Choose whether to offer this to all residents or target specific segments', TRUE, null
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'audience_selection');

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input, option_source_link)
SELECT 'f6060606-3011-4000-8000-000000000001',
       'guest_tags', 'tag_selector', 'Guest Tags', null,
       'Filter eligible residents by tags', TRUE,
       '/portal-gateway/v1/crm/merchant-groups/tags'
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'guest_tags');

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input, option_source_link)
SELECT 'f6060606-3012-4000-8000-000000000001',
       'guest_filters', 'tag_options', null, null, null, TRUE,
       '/portal-gateway/v1/tags/options'
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'guest_filters');

-- audience_count already created in V99

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 'f6060606-3020-4000-8000-000000000001',
       'offer_name', 'text', 'Task name', null,
       'Name your checklist task', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'offer_name');

-- input_summary already created in V99

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT 'f6060606-3021-4000-8000-000000000001',
       'create_offer', 'button', 'Create task', null, null, FALSE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'create_offer');


-- ============================================================
-- PART 5: OFFER BUILDER FLOWS (mobile + web, one per type)
-- ============================================================

INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES
  -- Mobile
  ('f6060606-4001-4000-8000-000000000001', 'f6060606-1001-4000-8000-000000000001', 'mobile', 'full'),
  ('f6060606-4002-4000-8000-000000000001', 'f6060606-1002-4000-8000-000000000002', 'mobile', 'full'),
  ('f6060606-4003-4000-8000-000000000001', 'f6060606-1003-4000-8000-000000000003', 'mobile', 'full'),
  ('f6060606-4004-4000-8000-000000000001', 'f6060606-1004-4000-8000-000000000004', 'mobile', 'full'),
  ('f6060606-4005-4000-8000-000000000001', 'f6060606-1005-4000-8000-000000000005', 'mobile', 'full'),
  -- Web
  ('f6060606-4007-4000-8000-000000000001', 'f6060606-1001-4000-8000-000000000001', 'web', 'full'),
  ('f6060606-4008-4000-8000-000000000001', 'f6060606-1002-4000-8000-000000000002', 'web', 'full'),
  ('f6060606-4009-4000-8000-000000000001', 'f6060606-1003-4000-8000-000000000003', 'web', 'full'),
  ('f6060606-400a-4000-8000-000000000001', 'f6060606-1004-4000-8000-000000000004', 'web', 'full'),
  ('f6060606-400b-4000-8000-000000000001', 'f6060606-1005-4000-8000-000000000005', 'web', 'full');


-- ============================================================
-- PART 6: OFFER BUILDER FLOW STEPS
-- ============================================================
-- 5 steps per flow × 10 flows = 50 rows.
-- Steps: task_setup (1), audience_definition (2), action_configuration (3),
--        confirmation (4), success_handoff (5).

-- ---------- Mobile flows ----------

-- Mobile: Lease Signing
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5001-0001-8000-000000000001', 'f6060606-4001-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5001-0002-8000-000000000001', 'f6060606-4001-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5001-0003-8000-000000000001', 'f6060606-4001-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5001-0004-8000-000000000001', 'f6060606-4001-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5001-0005-8000-000000000001', 'f6060606-4001-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Autopay Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5002-0001-8000-000000000001', 'f6060606-4002-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5002-0002-8000-000000000001', 'f6060606-4002-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5002-0003-8000-000000000001', 'f6060606-4002-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5002-0004-8000-000000000001', 'f6060606-4002-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5002-0005-8000-000000000001', 'f6060606-4002-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Renters Insurance
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5003-0001-8000-000000000001', 'f6060606-4003-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5003-0002-8000-000000000001', 'f6060606-4003-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5003-0003-8000-000000000001', 'f6060606-4003-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5003-0004-8000-000000000001', 'f6060606-4003-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5003-0005-8000-000000000001', 'f6060606-4003-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Utilities Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5004-0001-8000-000000000001', 'f6060606-4004-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5004-0002-8000-000000000001', 'f6060606-4004-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5004-0003-8000-000000000001', 'f6060606-4004-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5004-0004-8000-000000000001', 'f6060606-4004-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5004-0005-8000-000000000001', 'f6060606-4004-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Document Upload
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5005-0001-8000-000000000001', 'f6060606-4005-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5005-0002-8000-000000000001', 'f6060606-4005-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5005-0003-8000-000000000001', 'f6060606-4005-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5005-0004-8000-000000000001', 'f6060606-4005-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5005-0005-8000-000000000001', 'f6060606-4005-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- ---------- Web flows ----------

-- Web: Lease Signing
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5007-0001-8000-000000000001', 'f6060606-4007-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5007-0002-8000-000000000001', 'f6060606-4007-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5007-0003-8000-000000000001', 'f6060606-4007-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5007-0004-8000-000000000001', 'f6060606-4007-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5007-0005-8000-000000000001', 'f6060606-4007-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Autopay Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5008-0001-8000-000000000001', 'f6060606-4008-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5008-0002-8000-000000000001', 'f6060606-4008-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5008-0003-8000-000000000001', 'f6060606-4008-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5008-0004-8000-000000000001', 'f6060606-4008-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5008-0005-8000-000000000001', 'f6060606-4008-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Renters Insurance
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-5009-0001-8000-000000000001', 'f6060606-4009-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-5009-0002-8000-000000000001', 'f6060606-4009-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-5009-0003-8000-000000000001', 'f6060606-4009-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-5009-0004-8000-000000000001', 'f6060606-4009-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-5009-0005-8000-000000000001', 'f6060606-4009-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Utilities Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-500a-0001-8000-000000000001', 'f6060606-400a-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-500a-0002-8000-000000000001', 'f6060606-400a-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-500a-0003-8000-000000000001', 'f6060606-400a-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-500a-0004-8000-000000000001', 'f6060606-400a-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-500a-0005-8000-000000000001', 'f6060606-400a-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Document Upload
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('f6060606-500b-0001-8000-000000000001', 'f6060606-400b-4000-8000-000000000001', 'f6060606-2001-4000-8000-000000000001', 1, true, false, false, true),
  ('f6060606-500b-0002-8000-000000000001', 'f6060606-400b-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('f6060606-500b-0003-8000-000000000001', 'f6060606-400b-4000-8000-000000000001', 'f6060606-2002-4000-8000-000000000001', 3, false, false, true, true),
  ('f6060606-500b-0004-8000-000000000001', 'f6060606-400b-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f6060606-500b-0005-8000-000000000001', 'f6060606-400b-4000-8000-000000000001', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);


-- ============================================================
-- PART 7: OFFER BUILDER FLOW STEP ELEMENTS
-- ============================================================
-- Step 1 (checklist_task_setup): task_name, task_description, is_completion_required
-- Step 2 (audience_definition):  audience_selection, guest_tags, guest_filters, audience_count
-- Step 3 (action_configuration): empty placeholder — other team populates per type
-- Step 4 (confirmation):         offer_name, input_summary, create_offer
-- Step 5 (success_handoff):      empty (no elements, matches production convention)
--
-- Default task_name values vary per type. All other defaults are shared.
-- Using a helper CTE to pair flow_step_ids with element_ids.

-- Step 1 elements: task_name (per-type defaults), task_description, is_completion_required
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section) VALUES
  -- Mobile flows: Step 1
  ('f6060606-6001-0001-8000-000000000001', 'f6060606-5001-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Sign your lease', 'body'),
  ('f6060606-6001-0001-8000-000000000002', 'f6060606-5001-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6001-0001-8000-000000000003', 'f6060606-5001-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-6002-0001-8000-000000000001', 'f6060606-5002-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up autopay', 'body'),
  ('f6060606-6002-0001-8000-000000000002', 'f6060606-5002-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6002-0001-8000-000000000003', 'f6060606-5002-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-6003-0001-8000-000000000001', 'f6060606-5003-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Get renters insurance', 'body'),
  ('f6060606-6003-0001-8000-000000000002', 'f6060606-5003-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6003-0001-8000-000000000003', 'f6060606-5003-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-6004-0001-8000-000000000001', 'f6060606-5004-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up utilities', 'body'),
  ('f6060606-6004-0001-8000-000000000002', 'f6060606-5004-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6004-0001-8000-000000000003', 'f6060606-5004-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-6005-0001-8000-000000000001', 'f6060606-5005-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Upload document', 'body'),
  ('f6060606-6005-0001-8000-000000000002', 'f6060606-5005-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6005-0001-8000-000000000003', 'f6060606-5005-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  -- Web flows: Step 1
  ('f6060606-6007-0001-8000-000000000001', 'f6060606-5007-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Sign your lease', 'body'),
  ('f6060606-6007-0001-8000-000000000002', 'f6060606-5007-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6007-0001-8000-000000000003', 'f6060606-5007-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-6008-0001-8000-000000000001', 'f6060606-5008-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up autopay', 'body'),
  ('f6060606-6008-0001-8000-000000000002', 'f6060606-5008-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6008-0001-8000-000000000003', 'f6060606-5008-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-6009-0001-8000-000000000001', 'f6060606-5009-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Get renters insurance', 'body'),
  ('f6060606-6009-0001-8000-000000000002', 'f6060606-5009-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6009-0001-8000-000000000003', 'f6060606-5009-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-600a-0001-8000-000000000001', 'f6060606-500a-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up utilities', 'body'),
  ('f6060606-600a-0001-8000-000000000002', 'f6060606-500a-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-600a-0001-8000-000000000003', 'f6060606-500a-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f6060606-600b-0001-8000-000000000001', 'f6060606-500b-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Upload document', 'body'),
  ('f6060606-600b-0001-8000-000000000002', 'f6060606-500b-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-600b-0001-8000-000000000003', 'f6060606-500b-0001-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body');

-- Step 2 elements: audience_selection, guest_tags, guest_filters, audience_count
-- Matches production F&F discount pattern (mobile full).
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section) VALUES
  -- Mobile flows: Step 2 (audience)
  ('f6060606-6001-0002-8000-000000000001', 'f6060606-5001-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6001-0002-8000-000000000002', 'f6060606-5001-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6001-0002-8000-000000000003', 'f6060606-5001-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6001-0002-8000-000000000004', 'f6060606-5001-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-6002-0002-8000-000000000001', 'f6060606-5002-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6002-0002-8000-000000000002', 'f6060606-5002-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6002-0002-8000-000000000003', 'f6060606-5002-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6002-0002-8000-000000000004', 'f6060606-5002-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-6003-0002-8000-000000000001', 'f6060606-5003-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6003-0002-8000-000000000002', 'f6060606-5003-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6003-0002-8000-000000000003', 'f6060606-5003-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6003-0002-8000-000000000004', 'f6060606-5003-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-6004-0002-8000-000000000001', 'f6060606-5004-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6004-0002-8000-000000000002', 'f6060606-5004-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6004-0002-8000-000000000003', 'f6060606-5004-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6004-0002-8000-000000000004', 'f6060606-5004-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-6005-0002-8000-000000000001', 'f6060606-5005-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6005-0002-8000-000000000002', 'f6060606-5005-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6005-0002-8000-000000000003', 'f6060606-5005-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6005-0002-8000-000000000004', 'f6060606-5005-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  -- Web flows: Step 2 (audience)
  ('f6060606-6007-0002-8000-000000000001', 'f6060606-5007-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6007-0002-8000-000000000002', 'f6060606-5007-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6007-0002-8000-000000000003', 'f6060606-5007-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6007-0002-8000-000000000004', 'f6060606-5007-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-6008-0002-8000-000000000001', 'f6060606-5008-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6008-0002-8000-000000000002', 'f6060606-5008-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6008-0002-8000-000000000003', 'f6060606-5008-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6008-0002-8000-000000000004', 'f6060606-5008-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-6009-0002-8000-000000000001', 'f6060606-5009-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-6009-0002-8000-000000000002', 'f6060606-5009-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6009-0002-8000-000000000003', 'f6060606-5009-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-6009-0002-8000-000000000004', 'f6060606-5009-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-600a-0002-8000-000000000001', 'f6060606-500a-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-600a-0002-8000-000000000002', 'f6060606-500a-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-600a-0002-8000-000000000003', 'f6060606-500a-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-600a-0002-8000-000000000004', 'f6060606-500a-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('f6060606-600b-0002-8000-000000000001', 'f6060606-500b-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('f6060606-600b-0002-8000-000000000002', 'f6060606-500b-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-600b-0002-8000-000000000003', 'f6060606-500b-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('f6060606-600b-0002-8000-000000000004', 'f6060606-500b-0002-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer');

-- Step 3 (action_configuration): empty placeholder — other team adds elements per type.

-- Step 4 elements: offer_name, input_summary, create_offer
-- Matches production F&F discount confirmation pattern.
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section) VALUES
  -- Mobile flows: Step 4 (confirmation)
  ('f6060606-6001-0004-8000-000000000001', 'f6060606-5001-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6001-0004-8000-000000000002', 'f6060606-5001-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6001-0004-8000-000000000003', 'f6060606-5001-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-6002-0004-8000-000000000001', 'f6060606-5002-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6002-0004-8000-000000000002', 'f6060606-5002-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6002-0004-8000-000000000003', 'f6060606-5002-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-6003-0004-8000-000000000001', 'f6060606-5003-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6003-0004-8000-000000000002', 'f6060606-5003-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6003-0004-8000-000000000003', 'f6060606-5003-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-6004-0004-8000-000000000001', 'f6060606-5004-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6004-0004-8000-000000000002', 'f6060606-5004-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6004-0004-8000-000000000003', 'f6060606-5004-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-6005-0004-8000-000000000001', 'f6060606-5005-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6005-0004-8000-000000000002', 'f6060606-5005-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6005-0004-8000-000000000003', 'f6060606-5005-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  -- Web flows: Step 4 (confirmation)
  ('f6060606-6007-0004-8000-000000000001', 'f6060606-5007-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6007-0004-8000-000000000002', 'f6060606-5007-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6007-0004-8000-000000000003', 'f6060606-5007-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-6008-0004-8000-000000000001', 'f6060606-5008-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6008-0004-8000-000000000002', 'f6060606-5008-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6008-0004-8000-000000000003', 'f6060606-5008-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-6009-0004-8000-000000000001', 'f6060606-5009-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-6009-0004-8000-000000000002', 'f6060606-5009-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-6009-0004-8000-000000000003', 'f6060606-5009-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-600a-0004-8000-000000000001', 'f6060606-500a-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-600a-0004-8000-000000000002', 'f6060606-500a-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-600a-0004-8000-000000000003', 'f6060606-500a-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f6060606-600b-0004-8000-000000000001', 'f6060606-500b-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('f6060606-600b-0004-8000-000000000002', 'f6060606-500b-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f6060606-600b-0004-8000-000000000003', 'f6060606-500b-0004-8000-000000000001', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta');

-- Step 5 (success_handoff): no elements (matches production pattern).


-- ============================================================
-- PART 8: ACTIONS (one per checklist task type)
-- ============================================================

INSERT INTO actions (id, action_type, action_config)
VALUES
  ('a1010101-0001-4000-8000-000000000001', 'CONFIRM_LEASE_SIGNING', '{"taskName": "Sign your lease"}'::jsonb),
  ('a1010101-0002-4000-8000-000000000002', 'SETUP_AUTOPAY', null),
  ('a1010101-0003-4000-8000-000000000003', 'GET_RENTERS_INSURANCE', null),
  ('a1010101-0004-4000-8000-000000000004', 'CHECKLIST_TASK', '{"taskName": "Set up utilities"}'::jsonb),
  ('a1010101-0005-4000-8000-000000000005', 'UPLOAD_DOCUMENT', '{"maxSize": "10MB"}'::jsonb);


-- ============================================================
-- PART 9: JOURNEY TEMPLATE
-- ============================================================

INSERT INTO journey_templates
  (id, journey_type, portal, name, description, offer_group_type)
VALUES
  ('b2020202-0001-4000-8000-000000000001',
   'MOVE_IN_CHECKLIST', 'property', 'Move-In Checklist',
   'Guide new residents through essential move-in tasks.',
   'MOVE_IN_CHECKLIST');


-- ============================================================
-- PART 10: JOURNEY BUILDER FLOW
-- ============================================================

INSERT INTO journey_builder_flows
  (id, journey_template_id, title, description, is_reward_selection_required)
VALUES
  ('c3030303-0001-4000-8000-000000000001',
   'b2020202-0001-4000-8000-000000000001',
   'Move-In Checklist',
   'Configure the tasks for your move-in checklist. Each task becomes an item residents can complete.',
   false);


-- ============================================================
-- PART 11: JOURNEY OFFER TEMPLATES
-- ============================================================

INSERT INTO journey_offer_templates
  (id, journey_template_id, name, reward_type, action_id)
VALUES
  ('d4040404-0001-4000-8000-000000000001', 'b2020202-0001-4000-8000-000000000001', 'Lease Signing Confirmation', 'NONE', 'a1010101-0001-4000-8000-000000000001'),
  ('d4040404-0002-4000-8000-000000000002', 'b2020202-0001-4000-8000-000000000001', 'Autopay Setup', 'NONE', 'a1010101-0002-4000-8000-000000000002'),
  ('d4040404-0003-4000-8000-000000000003', 'b2020202-0001-4000-8000-000000000001', 'Renters Insurance', 'NONE', 'a1010101-0003-4000-8000-000000000003'),
  ('d4040404-0004-4000-8000-000000000004', 'b2020202-0001-4000-8000-000000000001', 'Utilities Setup', 'NONE', 'a1010101-0004-4000-8000-000000000004'),
  ('d4040404-0005-4000-8000-000000000005', 'b2020202-0001-4000-8000-000000000001', 'Document Upload', 'NONE', 'a1010101-0005-4000-8000-000000000005');


-- ============================================================
-- PART 12: JOURNEY BUILDER FLOW STEPS
-- ============================================================

INSERT INTO journey_builder_flow_steps
  (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon,
   default_body, template_type, template_id, builder_entrypoint, show_merchant_selector)
VALUES
  ('e5050505-0001-4000-8000-000000000001',
   'c3030303-0001-4000-8000-000000000001', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   1, false, 'Sign Lease', 'file-text-bold',
   '[{"icon": null, "order": 1, "value": "Confirm that the resident has signed their lease agreement."}]'::jsonb,
   'OFFER', 'd4040404-0001-4000-8000-000000000001',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=f6060606-1001-4000-8000-000000000001&platform={platform}&audienceType=full',
   false),

  ('e5050505-0002-4000-8000-000000000002',
   'c3030303-0001-4000-8000-000000000001', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   2, false, 'Set Up Autopay', 'credit-card-bold',
   '[{"icon": null, "order": 1, "value": "Encourage residents to set up automatic rent payments."}]'::jsonb,
   'OFFER', 'd4040404-0002-4000-8000-000000000002',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=f6060606-1002-4000-8000-000000000002&platform={platform}&audienceType=full',
   false),

  ('e5050505-0003-4000-8000-000000000003',
   'c3030303-0001-4000-8000-000000000001', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   3, false, 'Get Renters Insurance', 'shield-check-bold',
   '[{"icon": null, "order": 1, "value": "Prompt residents to obtain renters insurance for their unit."}]'::jsonb,
   'OFFER', 'd4040404-0003-4000-8000-000000000003',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=f6060606-1003-4000-8000-000000000003&platform={platform}&audienceType=full',
   false),

  ('e5050505-0004-4000-8000-000000000004',
   'c3030303-0001-4000-8000-000000000001', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   4, false, 'Set Up Utilities', 'lightning-bold',
   '[{"icon": null, "order": 1, "value": "Remind residents to transfer or set up utility accounts."}]'::jsonb,
   'OFFER', 'd4040404-0004-4000-8000-000000000004',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=f6060606-1004-4000-8000-000000000004&platform={platform}&audienceType=full',
   false),

  ('e5050505-0005-4000-8000-000000000005',
   'c3030303-0001-4000-8000-000000000001', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   5, false, 'Upload Document', 'upload-bold',
   '[{"icon": null, "order": 1, "value": "Request residents upload a required document such as proof of insurance or ID."}]'::jsonb,
   'OFFER', 'd4040404-0005-4000-8000-000000000005',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=f6060606-1005-4000-8000-000000000005&platform={platform}&audienceType=full',
   false);
