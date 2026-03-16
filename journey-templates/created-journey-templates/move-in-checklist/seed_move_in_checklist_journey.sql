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
  ('354edde1-e2f9-48ec-a0f7-7a5a20227aec',
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
  ('a4b668d9-fa29-4b6d-aa17-fddd30a75014',
   'checklist_lease_signing', 'Lease Signing',
   'Confirm the resident has signed their lease',
   'file-text-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 1, '354edde1-e2f9-48ec-a0f7-7a5a20227aec'),

  ('1f2d384f-5d3f-4da3-8e9c-71dffefd5e5a',
   'checklist_autopay_setup', 'Autopay Setup',
   'Set up automatic rent payments',
   'credit-card-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 2, '354edde1-e2f9-48ec-a0f7-7a5a20227aec'),

  ('5107b023-9efc-4b0b-9e26-0365d1cb6ef2',
   'checklist_renters_insurance', 'Renters Insurance',
   'Obtain renters insurance for the unit',
   'shield-check-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 3, '354edde1-e2f9-48ec-a0f7-7a5a20227aec'),

  ('c514294a-e4c6-45a9-81dd-eed9e0f14461',
   'checklist_utilities_setup', 'Utilities Setup',
   'Transfer or set up utility accounts',
   'lightning-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 4, '354edde1-e2f9-48ec-a0f7-7a5a20227aec'),

  ('99736fc0-f444-4a54-ad4b-83c19a74d91f',
   'checklist_document_upload', 'Document Upload',
   'Upload a required document such as proof of insurance',
   'upload-regular',
   'EARN_POINTS', 'HOME', 'FLAT', 'BILT_POINTS',
   'PROPERTY', TRUE, 5, '354edde1-e2f9-48ec-a0f7-7a5a20227aec');


-- ============================================================
-- PART 3: OFFER BUILDER STEPS (reusable)
-- ============================================================

INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT '3000d2e7-2f5a-4036-bcc2-81bf57936d34',
       'checklist_task_setup',
       'Create your move-in task'
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_steps WHERE step_type = 'checklist_task_setup'
);

INSERT INTO offer_builder_steps (id, step_type, default_title)
SELECT '1e9eb608-82f3-4066-811a-37af00e0b369',
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
SELECT 'ac52e51e-883d-4451-bd1f-18eb2efc8372',
       'task_name', 'text', 'Task name', 'e.g. Sign your lease',
       'The name residents will see for this checklist task', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'task_name');

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT '70fb3606-cb6d-46d2-b5df-7cae96a766f5',
       'task_description', 'text_box', 'Description', 'Describe what the resident needs to do',
       'A brief description of the task shown to residents', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'task_description');

INSERT INTO offer_builder_elements (id, internal_name, internal_type, default_label, default_placeholder, default_help_text, is_input)
SELECT '07e25e8a-645e-49b2-a2a6-89cef6790085',
       'is_completion_required', 'switch', 'Is Completion Required?', null,
       'Whether residents must complete this task', TRUE
WHERE NOT EXISTS (SELECT 1 FROM offer_builder_elements WHERE internal_name = 'is_completion_required');

-- Options for is_completion_required switch
INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, option_order)
SELECT 'cb2d093d-f26b-4086-a452-9aced20aa3af',
       (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1),
       'true', 'Required', 1
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1)
    AND option_value = 'true'
);

INSERT INTO offer_builder_element_options (id, element_id, option_value, default_label, option_order)
SELECT 'ff54760f-ba04-4a0c-bfab-120796bd9d33',
       (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1),
       'false', 'Optional', 2
WHERE NOT EXISTS (
    SELECT 1 FROM offer_builder_element_options
    WHERE element_id = (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1)
    AND option_value = 'false'
);

-- 4b: Standard elements reused from existing flows.
-- audience_selection, guest_tags, guest_filters, audience_count,
-- offer_name, input_summary, and create_offer already exist in the DB
-- (seeded by earlier migrations). They are referenced by internal_name
-- in the flow_step_elements below.


-- ============================================================
-- PART 5: OFFER BUILDER FLOWS (mobile + web, one per type)
-- ============================================================

INSERT INTO offer_builder_flows (id, synthetic_reward_type_id, platform, audience_type)
VALUES
  -- Mobile
  ('ece9666c-b7b9-435c-bc31-052d7a92653e', 'a4b668d9-fa29-4b6d-aa17-fddd30a75014', 'mobile', 'full'),
  ('ad9dc73b-fce4-4d98-9c72-ea99ffbed521', '1f2d384f-5d3f-4da3-8e9c-71dffefd5e5a', 'mobile', 'full'),
  ('afafd7a7-3972-49b9-aef6-59309130e1c8', '5107b023-9efc-4b0b-9e26-0365d1cb6ef2', 'mobile', 'full'),
  ('84cf3012-7d50-4f93-822e-fd1e6f3c5831', 'c514294a-e4c6-45a9-81dd-eed9e0f14461', 'mobile', 'full'),
  ('119eaf0c-6430-41f7-9454-ce583f88fb76', '99736fc0-f444-4a54-ad4b-83c19a74d91f', 'mobile', 'full'),
  -- Web
  ('dc4c8a50-84bb-4a4a-a991-98c1053e5b23', 'a4b668d9-fa29-4b6d-aa17-fddd30a75014', 'web', 'full'),
  ('5892b5ef-6b90-4ba3-9191-1a86831289a6', '1f2d384f-5d3f-4da3-8e9c-71dffefd5e5a', 'web', 'full'),
  ('40751399-c0ff-4cf2-ac91-68d08bdd5215', '5107b023-9efc-4b0b-9e26-0365d1cb6ef2', 'web', 'full'),
  ('f24fa81f-e705-4f90-bf71-877ab3f3a615', 'c514294a-e4c6-45a9-81dd-eed9e0f14461', 'web', 'full'),
  ('e49c6c1f-da1e-46c9-90da-20385868333c', '99736fc0-f444-4a54-ad4b-83c19a74d91f', 'web', 'full');


-- ============================================================
-- PART 6: OFFER BUILDER FLOW STEPS
-- ============================================================
-- 5 steps per flow × 10 flows = 50 rows.
-- Steps: task_setup (1), audience_definition (2), action_configuration (3),
--        confirmation (4), success_handoff (5).

-- ---------- Mobile flows ----------

-- Mobile: Lease Signing
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('2f36f74c-bf0b-4a0e-afd6-a2cf373658ad', 'ece9666c-b7b9-435c-bc31-052d7a92653e', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('ec85cbdf-f7ee-4dab-96dc-c65faf92cb2c', 'ece9666c-b7b9-435c-bc31-052d7a92653e', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('bae7c187-ef4b-44a2-891a-e4194c510cf4', 'ece9666c-b7b9-435c-bc31-052d7a92653e', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('4bb54a6c-1088-48de-b82e-78bf93b4a43c', 'ece9666c-b7b9-435c-bc31-052d7a92653e', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('f0f29c97-3e91-409a-a437-f43b6282f3f2', 'ece9666c-b7b9-435c-bc31-052d7a92653e', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Autopay Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('78816563-c048-436c-9cd6-27a09f3205b5', 'ad9dc73b-fce4-4d98-9c72-ea99ffbed521', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('36d1453d-df90-4578-b269-89769e247abe', 'ad9dc73b-fce4-4d98-9c72-ea99ffbed521', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('3bff4670-7c8a-4cda-be6f-a5e225b3b0e1', 'ad9dc73b-fce4-4d98-9c72-ea99ffbed521', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('df6e082c-d208-4f60-8f5c-7a495fc34653', 'ad9dc73b-fce4-4d98-9c72-ea99ffbed521', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('1d8a7922-fcd4-4fa0-9ed1-9a77fb347949', 'ad9dc73b-fce4-4d98-9c72-ea99ffbed521', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Renters Insurance
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('924bbb10-51d9-481a-a541-c6fa472ad8e3', 'afafd7a7-3972-49b9-aef6-59309130e1c8', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('719c5490-2c77-4697-9cb2-98430f30d8c0', 'afafd7a7-3972-49b9-aef6-59309130e1c8', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('48481823-7d55-46ab-abb4-9506b8553c19', 'afafd7a7-3972-49b9-aef6-59309130e1c8', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('f9635165-b6a2-4a37-877b-5f031916c82f', 'afafd7a7-3972-49b9-aef6-59309130e1c8', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('2815dc03-632f-49d7-ae9a-7e8cb8ff7cb2', 'afafd7a7-3972-49b9-aef6-59309130e1c8', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Utilities Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('c4b4d303-0eb7-447f-9a38-e9a6b0c3b20d', '84cf3012-7d50-4f93-822e-fd1e6f3c5831', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('77452b96-8b8f-4d08-8ac6-3aed14ffeb7f', '84cf3012-7d50-4f93-822e-fd1e6f3c5831', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('c7658394-1174-4127-9759-1d0cfd1a16d9', '84cf3012-7d50-4f93-822e-fd1e6f3c5831', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('57be3e80-0ce7-4f6b-9d8b-73a5bf13290e', '84cf3012-7d50-4f93-822e-fd1e6f3c5831', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('b6306cdb-76bf-46f1-93fa-33284e1ac22d', '84cf3012-7d50-4f93-822e-fd1e6f3c5831', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Mobile: Document Upload
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('cca6f5db-f454-4e22-9747-3d267a5d1fdd', '119eaf0c-6430-41f7-9454-ce583f88fb76', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('9d28af62-7a36-4c7a-ba41-1181dcb5a639', '119eaf0c-6430-41f7-9454-ce583f88fb76', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('13a7d89b-9b1f-440f-9d5e-fff4906d9150', '119eaf0c-6430-41f7-9454-ce583f88fb76', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('c9d6a596-4c5f-4c69-8680-16d2bb79d21c', '119eaf0c-6430-41f7-9454-ce583f88fb76', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('17e6251b-a7b9-43d0-8659-697a4880d5a9', '119eaf0c-6430-41f7-9454-ce583f88fb76', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- ---------- Web flows ----------

-- Web: Lease Signing
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('4df93056-67ab-4cfe-bc18-73d903ece555', 'dc4c8a50-84bb-4a4a-a991-98c1053e5b23', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('5a5d092e-9cdc-463c-89ff-15e243fc59fb', 'dc4c8a50-84bb-4a4a-a991-98c1053e5b23', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('e94a7660-19a1-4677-b181-0f93290951fd', 'dc4c8a50-84bb-4a4a-a991-98c1053e5b23', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('7755d8f7-f12f-4203-a0ae-150ef4436ad0', 'dc4c8a50-84bb-4a4a-a991-98c1053e5b23', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('c7d3bbe0-77f0-49ac-a960-a928a2393113', 'dc4c8a50-84bb-4a4a-a991-98c1053e5b23', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Autopay Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('c34695cc-eccd-4856-83df-3d6d2d034c3e', '5892b5ef-6b90-4ba3-9191-1a86831289a6', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('0c4d9e46-cc64-414e-afb3-abf27dd013f6', '5892b5ef-6b90-4ba3-9191-1a86831289a6', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('fcb958a1-4a9c-4e73-90c5-ae48c1d81df0', '5892b5ef-6b90-4ba3-9191-1a86831289a6', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('3354627f-bf0f-481f-b601-4d081b7c62f2', '5892b5ef-6b90-4ba3-9191-1a86831289a6', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('8e8ce599-a9af-4b3d-9663-ba4687f92309', '5892b5ef-6b90-4ba3-9191-1a86831289a6', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Renters Insurance
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('e9147955-6168-42e3-96e5-5ee2c03a7e17', '40751399-c0ff-4cf2-ac91-68d08bdd5215', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('b7bb9f24-e49e-470f-b39f-ea2ba5cec5a1', '40751399-c0ff-4cf2-ac91-68d08bdd5215', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('9eca7f4e-d92e-4968-8bdd-a54201637106', '40751399-c0ff-4cf2-ac91-68d08bdd5215', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('f66c133f-c734-4261-a2d2-0561bf2bebb6', '40751399-c0ff-4cf2-ac91-68d08bdd5215', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('2516ad54-bc9a-4dcf-a4a3-cf7d7b98ea36', '40751399-c0ff-4cf2-ac91-68d08bdd5215', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Utilities Setup
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('a98f5fa6-c52e-4004-9f5a-4b0dc11b2797', 'f24fa81f-e705-4f90-bf71-877ab3f3a615', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('46dd9f81-8017-4647-a18a-a74641c054dd', 'f24fa81f-e705-4f90-bf71-877ab3f3a615', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('6b392bcf-0e62-4bed-bd81-52cfd827f784', 'f24fa81f-e705-4f90-bf71-877ab3f3a615', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('978815c5-ee27-409a-95b9-a01bde16d07c', 'f24fa81f-e705-4f90-bf71-877ab3f3a615', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('097ea71e-c5d4-4d01-b0d9-e3881d1b1d42', 'f24fa81f-e705-4f90-bf71-877ab3f3a615', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);

-- Web: Document Upload
INSERT INTO offer_builder_flow_steps (id, flow_id, step_id, step_order, is_required, is_skip_allowed, is_back_navigation_allowed, is_visible) VALUES
  ('66b3ddee-f5d1-4e6c-8e14-5cb97020d095', 'e49c6c1f-da1e-46c9-90da-20385868333c', '3000d2e7-2f5a-4036-bcc2-81bf57936d34', 1, true, false, false, true),
  ('cd8faec7-68ae-485a-91ec-e111bab0fa05', 'e49c6c1f-da1e-46c9-90da-20385868333c', (SELECT id FROM offer_builder_steps WHERE step_type = 'audience_definition' LIMIT 1), 2, true, false, true, true),
  ('e5d1a4a8-b23b-44dd-ba28-64f98e76cf1c', 'e49c6c1f-da1e-46c9-90da-20385868333c', '1e9eb608-82f3-4066-811a-37af00e0b369', 3, false, false, true, true),
  ('67947538-6106-4cf2-bd6b-a02469c17beb', 'e49c6c1f-da1e-46c9-90da-20385868333c', (SELECT id FROM offer_builder_steps WHERE step_type = 'confirmation' LIMIT 1), 4, true, false, true, true),
  ('6b9bbdcb-e342-4d19-a735-3a55281cea18', 'e49c6c1f-da1e-46c9-90da-20385868333c', (SELECT id FROM offer_builder_steps WHERE step_type = 'success_handoff' LIMIT 1), 5, true, false, false, true);


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
  ('2ec98dbe-0deb-48de-93fc-de2253765d66', '2f36f74c-bf0b-4a0e-afd6-a2cf373658ad', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Sign your lease', 'body'),
  ('d011502f-0cc6-48ce-a700-71fdbb93aa3f', '2f36f74c-bf0b-4a0e-afd6-a2cf373658ad', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('1af9b673-308b-402d-9a0a-04f68fb65b5a', '2f36f74c-bf0b-4a0e-afd6-a2cf373658ad', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('7f966962-757e-4d88-90bf-f29d95e54600', '78816563-c048-436c-9cd6-27a09f3205b5', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up autopay', 'body'),
  ('4671897e-c97a-48e8-b70b-78ec1d64b5f2', '78816563-c048-436c-9cd6-27a09f3205b5', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('01dee547-d676-46ca-9c0f-54211c96ba7e', '78816563-c048-436c-9cd6-27a09f3205b5', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('f5969fef-83a5-41a6-bfbc-a5e9515c9d77', '924bbb10-51d9-481a-a541-c6fa472ad8e3', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Get renters insurance', 'body'),
  ('e32ffbb7-cdad-42c2-b8be-1ed45eda4e38', '924bbb10-51d9-481a-a541-c6fa472ad8e3', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('c1ea633f-36ce-4e84-84d3-9b8a44a564df', '924bbb10-51d9-481a-a541-c6fa472ad8e3', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('a717cf82-05ef-469a-a44b-9b2939d241b4', 'c4b4d303-0eb7-447f-9a38-e9a6b0c3b20d', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up utilities', 'body'),
  ('efd7ed0f-f50e-4ee1-8752-e47bdb831ee5', 'c4b4d303-0eb7-447f-9a38-e9a6b0c3b20d', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('784a2f71-d99a-47dc-be0a-f9f7f38fc82b', 'c4b4d303-0eb7-447f-9a38-e9a6b0c3b20d', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('028ca5e3-72bd-4786-a618-46c50c973c75', 'cca6f5db-f454-4e22-9747-3d267a5d1fdd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Upload document', 'body'),
  ('681f3bdd-26d0-4ca7-b8f3-4c99f2c5982f', 'cca6f5db-f454-4e22-9747-3d267a5d1fdd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('99f36ad9-8568-446a-a4c6-0d01f359b3ee', 'cca6f5db-f454-4e22-9747-3d267a5d1fdd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  -- Web flows: Step 1
  ('342882c1-fb68-4bc6-b514-917e38eac4fa', '4df93056-67ab-4cfe-bc18-73d903ece555', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Sign your lease', 'body'),
  ('fc589a5b-0bb9-47a5-86c9-a66ecaa87f48', '4df93056-67ab-4cfe-bc18-73d903ece555', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('3e281583-f624-48b4-82ec-e6f5a61bfc91', '4df93056-67ab-4cfe-bc18-73d903ece555', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('023517ec-ade8-4500-9a49-d705c9a7f7d2', 'c34695cc-eccd-4856-83df-3d6d2d034c3e', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up autopay', 'body'),
  ('dc4bf6f1-50b8-4f5b-b1cf-faff76df95cb', 'c34695cc-eccd-4856-83df-3d6d2d034c3e', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('2b685dfc-de6a-461e-8bef-49fec03b5fca', 'c34695cc-eccd-4856-83df-3d6d2d034c3e', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('75fad5fa-e544-4b35-b957-c2140d0ae0ce', 'e9147955-6168-42e3-96e5-5ee2c03a7e17', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Get renters insurance', 'body'),
  ('b4732c08-d9ee-492b-975e-f316f27a318a', 'e9147955-6168-42e3-96e5-5ee2c03a7e17', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('51e0f398-ac3c-4678-9943-5f8419fe3358', 'e9147955-6168-42e3-96e5-5ee2c03a7e17', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('35e6f886-f8ed-4917-97e5-654272e6feab', 'a98f5fa6-c52e-4004-9f5a-4b0dc11b2797', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Set up utilities', 'body'),
  ('e502489f-1c3f-4d37-9137-a340dbd45d67', 'a98f5fa6-c52e-4004-9f5a-4b0dc11b2797', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('c06a9503-c197-4323-b80f-bf9e1349aaae', 'a98f5fa6-c52e-4004-9f5a-4b0dc11b2797', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body'),

  ('d695a7bd-598f-4c76-84cf-ce1b2dba5c1f', '66b3ddee-f5d1-4e6c-8e14-5cb97020d095', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_name' LIMIT 1), 1, true, true, 'Upload document', 'body'),
  ('c0f7303f-5dad-4537-ade8-691d19c8a817', '66b3ddee-f5d1-4e6c-8e14-5cb97020d095', (SELECT id FROM offer_builder_elements WHERE internal_name = 'task_description' LIMIT 1), 2, false, true, null, 'body'),
  ('f95a7dcd-7ea9-43f9-81ae-a096dffdc081', '66b3ddee-f5d1-4e6c-8e14-5cb97020d095', (SELECT id FROM offer_builder_elements WHERE internal_name = 'is_completion_required' LIMIT 1), 3, true, true, 'false', 'body');

-- Step 2 elements: audience_selection, guest_tags, guest_filters, audience_count
-- Matches production F&F discount pattern (mobile full).
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section) VALUES
  -- Mobile flows: Step 2 (audience)
  ('1df84579-2b6f-4c2f-8d4e-997389ab998b', 'ec85cbdf-f7ee-4dab-96dc-c65faf92cb2c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('2ba83cea-906c-462b-abab-f989f12fcbb2', 'ec85cbdf-f7ee-4dab-96dc-c65faf92cb2c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('ba5cde91-328f-409f-bccc-3e11b397ee78', 'ec85cbdf-f7ee-4dab-96dc-c65faf92cb2c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('271e7a06-d047-4e69-b36b-da550885b2ae', 'ec85cbdf-f7ee-4dab-96dc-c65faf92cb2c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('0fea0f99-8817-4099-bcf8-87403ab26bcc', '36d1453d-df90-4578-b269-89769e247abe', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('d4136d25-7fd2-4694-9a2d-b8193c68a503', '36d1453d-df90-4578-b269-89769e247abe', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('fa49df31-b66e-4194-856c-35b131109f5b', '36d1453d-df90-4578-b269-89769e247abe', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('3222dc5b-edc4-4744-85b0-3fef01a1e166', '36d1453d-df90-4578-b269-89769e247abe', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('14525001-063d-4c60-8381-7fbf652a2956', '719c5490-2c77-4697-9cb2-98430f30d8c0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('78f0bd6d-8fda-4ecd-bc15-9ed419dd803f', '719c5490-2c77-4697-9cb2-98430f30d8c0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('15851f17-b929-46af-ac5e-6ab670b5f173', '719c5490-2c77-4697-9cb2-98430f30d8c0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('8d88c724-8733-4c16-8531-386eb10b269d', '719c5490-2c77-4697-9cb2-98430f30d8c0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('ed9b9db1-5ea9-45ed-bf60-bd79185e6ed5', '77452b96-8b8f-4d08-8ac6-3aed14ffeb7f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('6abc2724-da16-406b-91c6-4a7808366265', '77452b96-8b8f-4d08-8ac6-3aed14ffeb7f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('29de86a6-a781-4ac8-b20b-034e21f36281', '77452b96-8b8f-4d08-8ac6-3aed14ffeb7f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('c2778b4b-0e48-4cf3-b55a-b7a880380caa', '77452b96-8b8f-4d08-8ac6-3aed14ffeb7f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('60d09406-9b71-4c47-97b6-f706692ca0ff', '9d28af62-7a36-4c7a-ba41-1181dcb5a639', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('d6129590-6d93-4f6e-84d5-a5b71ebf891b', '9d28af62-7a36-4c7a-ba41-1181dcb5a639', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('dfc71024-afbf-4b8c-97ab-ffc7c0466261', '9d28af62-7a36-4c7a-ba41-1181dcb5a639', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('1f4048d2-79ed-44da-807c-7f9d3ec11f86', '9d28af62-7a36-4c7a-ba41-1181dcb5a639', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  -- Web flows: Step 2 (audience)
  ('5104271a-dff5-4092-8133-b6fa5ed8c4cc', '5a5d092e-9cdc-463c-89ff-15e243fc59fb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('274f11b2-c693-4500-af63-cd0ec8e08504', '5a5d092e-9cdc-463c-89ff-15e243fc59fb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('3599915a-9e67-47a3-852e-77ab096463fb', '5a5d092e-9cdc-463c-89ff-15e243fc59fb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('168b780e-884a-436e-a52b-abe8d03ab039', '5a5d092e-9cdc-463c-89ff-15e243fc59fb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('b4372f7d-f298-4211-b0d1-ebf1f036d2e0', '0c4d9e46-cc64-414e-afb3-abf27dd013f6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('68bcc6eb-8253-4a0d-83a3-88e26a4f54ed', '0c4d9e46-cc64-414e-afb3-abf27dd013f6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('fe527c7f-9f6a-4ef1-9c70-bf474c44a779', '0c4d9e46-cc64-414e-afb3-abf27dd013f6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('431d4064-9eee-492e-8932-9ae9f928d907', '0c4d9e46-cc64-414e-afb3-abf27dd013f6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('b4bbb2aa-59db-42c1-a0c1-42b7c25dad81', 'b7bb9f24-e49e-470f-b39f-ea2ba5cec5a1', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('ad78075e-7b96-4655-b58c-90ada098d550', 'b7bb9f24-e49e-470f-b39f-ea2ba5cec5a1', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('f8d7c1df-bc07-4a0f-8edd-0c045644d0aa', 'b7bb9f24-e49e-470f-b39f-ea2ba5cec5a1', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('1b9e302a-4390-4e97-98e5-158f6f1c0879', 'b7bb9f24-e49e-470f-b39f-ea2ba5cec5a1', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('39d9160d-9c2f-4d31-863a-c1192add6204', '46dd9f81-8017-4647-a18a-a74641c054dd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('cd9686a7-d6d1-4ef6-9421-8ec06f9bd0c3', '46dd9f81-8017-4647-a18a-a74641c054dd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('50ac3b31-9be6-4c3c-840a-5935654e9d59', '46dd9f81-8017-4647-a18a-a74641c054dd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('7fab509d-5544-4348-a5c5-f623e1c9e713', '46dd9f81-8017-4647-a18a-a74641c054dd', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer'),

  ('c8a9746b-2c22-410b-bf14-aa222b6555b1', 'cd8faec7-68ae-485a-91ec-e111bab0fa05', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_selection' LIMIT 1), 1, false, true, 'all', 'body'),
  ('cea6d547-562a-440a-92eb-9bd7078647d8', 'cd8faec7-68ae-485a-91ec-e111bab0fa05', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_tags' LIMIT 1), 2, false, true, null, 'body'),
  ('97814ce6-fed3-4fe1-905c-f625138285a2', 'cd8faec7-68ae-485a-91ec-e111bab0fa05', (SELECT id FROM offer_builder_elements WHERE internal_name = 'guest_filters' LIMIT 1), 3, false, true, null, 'body'),
  ('6e9e5cd6-bb3b-41a0-9f16-8f2b3773ed42', 'cd8faec7-68ae-485a-91ec-e111bab0fa05', (SELECT id FROM offer_builder_elements WHERE internal_name = 'audience_count' LIMIT 1), 4, false, true, null, 'footer');

-- Step 3 (action_configuration): empty placeholder — other team adds elements per type.

-- Step 4 elements: offer_name, input_summary, create_offer
-- Matches production F&F discount confirmation pattern.
INSERT INTO offer_builder_flow_step_elements (id, flow_step_id, element_id, element_order, is_required, is_visible, default_value, section) VALUES
  -- Mobile flows: Step 4 (confirmation)
  ('cf38ea19-0f2c-47ed-a858-040b909bfa4c', '4bb54a6c-1088-48de-b82e-78bf93b4a43c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('a265edef-26d0-4a9b-8768-e0999a06373a', '4bb54a6c-1088-48de-b82e-78bf93b4a43c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('e9314e62-2496-435d-8b04-c323913b811a', '4bb54a6c-1088-48de-b82e-78bf93b4a43c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('0d9bc2e0-4b9a-4573-88d8-53757fb7715c', 'df6e082c-d208-4f60-8f5c-7a495fc34653', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('d6e55117-9f59-4357-8b27-09c351c5851a', 'df6e082c-d208-4f60-8f5c-7a495fc34653', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('1459fdfc-4ce6-4526-90f3-92c91cd71912', 'df6e082c-d208-4f60-8f5c-7a495fc34653', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('2005bd70-b912-4138-8bde-9526836adb1c', 'f9635165-b6a2-4a37-877b-5f031916c82f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('dfdfd332-0db6-4dc2-adb5-2226512cb28e', 'f9635165-b6a2-4a37-877b-5f031916c82f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('c823cea5-b12e-4ab4-8dae-0dba847d57d5', 'f9635165-b6a2-4a37-877b-5f031916c82f', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('22fce76d-6dbf-4c7f-b887-d4a145681c71', '57be3e80-0ce7-4f6b-9d8b-73a5bf13290e', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('a7c68941-86e7-49e7-917c-372c4f717136', '57be3e80-0ce7-4f6b-9d8b-73a5bf13290e', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('bca5522c-b1c6-4b14-85a5-b1b0794c2d8a', '57be3e80-0ce7-4f6b-9d8b-73a5bf13290e', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('f9281dae-1115-4cc4-b9da-cb9e8d18d4f1', 'c9d6a596-4c5f-4c69-8680-16d2bb79d21c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('ad80f824-f334-414c-b45b-8c2c45165aa1', 'c9d6a596-4c5f-4c69-8680-16d2bb79d21c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('66785cdd-5fe5-467f-bd4f-b59e49e8af22', 'c9d6a596-4c5f-4c69-8680-16d2bb79d21c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  -- Web flows: Step 4 (confirmation)
  ('b1cc3228-8956-45d9-a05b-52bf48ea9f87', '7755d8f7-f12f-4203-a0ae-150ef4436ad0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('632f16ba-cc6c-48cf-9e3c-e8fc150435df', '7755d8f7-f12f-4203-a0ae-150ef4436ad0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('f20de827-018e-47c4-a5ca-4063b13d6534', '7755d8f7-f12f-4203-a0ae-150ef4436ad0', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('107af27a-956f-47a3-8e74-89d3179bc235', '3354627f-bf0f-481f-b601-4d081b7c62f2', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('e9547dba-373a-4855-8085-4d2d5f322177', '3354627f-bf0f-481f-b601-4d081b7c62f2', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('11c4e965-748e-4e3c-a7e6-46e8e6c08dc7', '3354627f-bf0f-481f-b601-4d081b7c62f2', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('7ba65c41-f148-4760-86a2-6f975d2da39d', 'f66c133f-c734-4261-a2d2-0561bf2bebb6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('a8774457-16bd-4c94-8296-85508262c8b6', 'f66c133f-c734-4261-a2d2-0561bf2bebb6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('c8c136b7-8a1c-405a-9b99-54e72152eb63', 'f66c133f-c734-4261-a2d2-0561bf2bebb6', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('0d72a0b8-4955-4bdb-a767-81b77135975f', '978815c5-ee27-409a-95b9-a01bde16d07c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('31195abd-49ef-4f75-b778-3e420d29d7fa', '978815c5-ee27-409a-95b9-a01bde16d07c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('fe13817f-7e08-4551-b598-16b23c21b0a2', '978815c5-ee27-409a-95b9-a01bde16d07c', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta'),

  ('855f5a2d-9733-4419-b5f1-4e7404d90b0f', '67947538-6106-4cf2-bd6b-a02469c17beb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'offer_name' LIMIT 1), 1, true, true, '{task_name}', 'body'),
  ('01c83dc1-8674-4b7f-bc17-3f96822c3b25', '67947538-6106-4cf2-bd6b-a02469c17beb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'input_summary' LIMIT 1), 2, false, true, null, 'body'),
  ('8a89033f-9ef8-47b5-876f-cbddb2885da0', '67947538-6106-4cf2-bd6b-a02469c17beb', (SELECT id FROM offer_builder_elements WHERE internal_name = 'create_offer' LIMIT 1), 3, false, true, null, 'cta');

-- Step 5 (success_handoff): no elements (matches production pattern).


-- ============================================================
-- PART 8: ACTIONS (one per checklist task type)
-- ============================================================

INSERT INTO actions (id, action_type, action_config)
VALUES
  ('eaa7e031-1b50-4953-b39c-6b59f379bbb4', 'CONFIRM_LEASE_SIGNING', '{"taskName": "Sign your lease"}'::jsonb),
  ('eff0dc89-51c6-4833-8aa8-096fe1528191', 'SETUP_AUTOPAY', null),
  ('6e50ae98-6386-4e9c-b963-a42ac32328df', 'GET_RENTERS_INSURANCE', null),
  ('a629bfb7-ade2-43ad-9cf8-2195d738c92e', 'CHECKLIST_TASK', '{"taskName": "Set up utilities"}'::jsonb),
  ('6d2417fe-f5aa-49b8-907a-01db8296eabf', 'UPLOAD_DOCUMENT', '{"maxSize": "10MB"}'::jsonb);


-- ============================================================
-- PART 9: JOURNEY TEMPLATE
-- ============================================================

INSERT INTO journey_templates
  (id, journey_type, portal, name, description, offer_group_type)
VALUES
  ('84c8fd19-997e-4d11-9465-e331ffe185f8',
   'MOVE_IN_CHECKLIST', 'property', 'Move-In Checklist',
   'Guide new residents through essential move-in tasks.',
   'MOVE_IN_CHECKLIST');


-- ============================================================
-- PART 10: JOURNEY BUILDER FLOW
-- ============================================================

INSERT INTO journey_builder_flows
  (id, journey_template_id, title, description, is_reward_selection_required)
VALUES
  ('ddf286ea-5e6c-43d2-986f-067f11c37002',
   '84c8fd19-997e-4d11-9465-e331ffe185f8',
   'Move-In Checklist',
   'Configure the tasks for your move-in checklist. Each task becomes an item residents can complete.',
   false);


-- ============================================================
-- PART 11: JOURNEY OFFER TEMPLATES
-- ============================================================

INSERT INTO journey_offer_templates
  (id, journey_template_id, name, reward_type, action_id)
VALUES
  ('6a125329-0faf-43df-8b43-6e14e0ebd3b8', '84c8fd19-997e-4d11-9465-e331ffe185f8', 'Lease Signing Confirmation', 'NONE', 'eaa7e031-1b50-4953-b39c-6b59f379bbb4'),
  ('18283832-67da-4e27-a780-574d58f11dad', '84c8fd19-997e-4d11-9465-e331ffe185f8', 'Autopay Setup', 'NONE', 'eff0dc89-51c6-4833-8aa8-096fe1528191'),
  ('ae2acf09-c2c7-426c-b0f2-2425a49c3079', '84c8fd19-997e-4d11-9465-e331ffe185f8', 'Renters Insurance', 'NONE', '6e50ae98-6386-4e9c-b963-a42ac32328df'),
  ('7f5896fd-7970-49ee-b623-4171c2ece8c9', '84c8fd19-997e-4d11-9465-e331ffe185f8', 'Utilities Setup', 'NONE', 'a629bfb7-ade2-43ad-9cf8-2195d738c92e'),
  ('a5334b6b-b06c-42ae-bf47-c94595d5d781', '84c8fd19-997e-4d11-9465-e331ffe185f8', 'Document Upload', 'NONE', '6d2417fe-f5aa-49b8-907a-01db8296eabf');


-- ============================================================
-- PART 12: JOURNEY BUILDER FLOW STEPS
-- ============================================================

INSERT INTO journey_builder_flow_steps
  (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon,
   default_body, template_type, template_id, builder_entrypoint, show_merchant_selector)
VALUES
  ('fb5d0ba1-4a71-4388-a31e-e6adacf883aa',
   'ddf286ea-5e6c-43d2-986f-067f11c37002', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   1, false, 'Sign Lease', 'file-text-bold',
   '[{"icon": null, "order": 1, "value": "Confirm that the resident has signed their lease agreement."}]'::jsonb,
   'OFFER', '6a125329-0faf-43df-8b43-6e14e0ebd3b8',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=a4b668d9-fa29-4b6d-aa17-fddd30a75014&platform={platform}&audienceType=full',
   false),

  ('7454d053-0cc1-4711-9103-636c0275101e',
   'ddf286ea-5e6c-43d2-986f-067f11c37002', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   2, false, 'Set Up Autopay', 'credit-card-bold',
   '[{"icon": null, "order": 1, "value": "Encourage residents to set up automatic rent payments."}]'::jsonb,
   'OFFER', '18283832-67da-4e27-a780-574d58f11dad',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=1f2d384f-5d3f-4da3-8e9c-71dffefd5e5a&platform={platform}&audienceType=full',
   false),

  ('12de48c9-e359-4d4f-b5b0-fedec79c9eb5',
   'ddf286ea-5e6c-43d2-986f-067f11c37002', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   3, false, 'Get Renters Insurance', 'shield-check-bold',
   '[{"icon": null, "order": 1, "value": "Prompt residents to obtain renters insurance for their unit."}]'::jsonb,
   'OFFER', 'ae2acf09-c2c7-426c-b0f2-2425a49c3079',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=5107b023-9efc-4b0b-9e26-0365d1cb6ef2&platform={platform}&audienceType=full',
   false),

  ('19227a03-b7a8-458a-82d3-9e8e81dc1f4a',
   'ddf286ea-5e6c-43d2-986f-067f11c37002', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   4, false, 'Set Up Utilities', 'lightning-bold',
   '[{"icon": null, "order": 1, "value": "Remind residents to transfer or set up utility accounts."}]'::jsonb,
   'OFFER', '7f5896fd-7970-49ee-b623-4171c2ece8c9',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=c514294a-e4c6-45a9-81dd-eed9e0f14461&platform={platform}&audienceType=full',
   false),

  ('61384ced-06a6-4976-b577-ec9a2362ebcf',
   'ddf286ea-5e6c-43d2-986f-067f11c37002', '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
   5, false, 'Upload Document', 'upload-bold',
   '[{"icon": null, "order": 1, "value": "Request residents upload a required document such as proof of insurance or ID."}]'::jsonb,
   'OFFER', 'a5334b6b-b06c-42ae-bf47-c94595d5d781',
   '/portal-gateway/v1/offer-builder/flows?rewardTypeId=99736fc0-f444-4a54-ad4b-83c19a74d91f&platform={platform}&audienceType=full',
   false);
