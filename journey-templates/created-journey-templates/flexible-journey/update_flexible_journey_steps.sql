-- ============================================================
-- FLEXIBLE_JOURNEY Template Update - Copy Changes + New Step + Groups
-- ============================================================
-- Updates:
--   1. Step 2 copy: "Invite guests in" with new description
--   2. Step 3 copy: "Deliver a first guest experience" with new description (stays at step_order=3)
--   3. Step 4 renamed: "Thank guests" with new description, reordered to step_order=5
--   4. NEW step inserted at step_order=4: "Deliver a second guest experience"
--   5. NEW groups: "Before", "During", "Checkout and after" with step assignments
--
-- Final order:
--   1. Audience (unchanged, no group)
--   2. Invite guests in (message) - group: "Before"
--   3. Deliver a first guest experience (offer) - group: "During"
--   4. Deliver a second guest experience (offer) - NEW - group: "During"
--   5. Thank guests (message) - group: "Checkout and after"
-- ============================================================

-- Flow ID reference
-- flow_id: 'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a'

-- ============================================================
-- Step 0: Create groups
-- ============================================================

INSERT INTO journey_builder_groups (id, title, description)
VALUES
  ('g1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c', 'Before', null),
  ('g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d', 'During', null),
  ('g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e', 'Checkout and after', null);

-- ============================================================
-- Step 1: Update step_order values first to avoid conflicts
-- ============================================================

-- Move current step 4 (thank guests) to step_order=5
UPDATE journey_builder_flow_steps
SET step_order = 5
WHERE id = 'b6c7d8e9-f0a1-4b2c-3d4e-5f6a7b8c9d0e';

-- ============================================================
-- Step 2: Update copy for existing steps
-- ============================================================

-- Update Step 2: "Invite guests in" - group: "Before"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Invite guests in',
  default_body = '[{"icon": null, "order": 1, "value": "Send a personalized message inviting guests to your restaurant."}]'::jsonb,
  group_id = 'g1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c'
WHERE id = 'f4a5b6c7-d8e9-4f0a-1b2c-3d4e5f6a7b8c';

-- Update Step 3: "Deliver a first guest experience" - group: "During"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Deliver a first guest experience',
  default_body = '[{"icon": null, "order": 1, "value": "Choose an experience you''d like to offer these guests to make them feel special."}]'::jsonb,
  group_id = 'g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d'
WHERE id = 'a5b6c7d8-e9f0-4a1b-2c3d-4e5f6a7b8c9d';

-- Update Step 5 (was Step 4): "Thank guests" - group: "Checkout and after"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Thank guests',
  default_body = '[{"icon": null, "order": 1, "value": "Send a personalized note to thank guests for visiting, and invite them back in."}]'::jsonb,
  group_id = 'g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e'
WHERE id = 'b6c7d8e9-f0a1-4b2c-3d4e-5f6a7b8c9d0e';

-- ============================================================
-- Step 3: Insert new step at position 4
-- ============================================================

-- Insert Step 4: "Deliver a second guest experience" - group: "During"
INSERT INTO journey_builder_flow_steps
  (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon, default_body, body, builder_entrypoint, template_type, template_id, show_merchant_selector, group_id)
VALUES
  (
    'c8d9e0f1-a2b3-4c5d-6e7f-8a9b0c1d2e3f',  -- new unique ID
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',  -- flow_id
    '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',  -- offer step_id from V110 (same as other offer step)
    4,
    false,
    'Deliver a second guest experience',
    'gift-bold',
    '[{"icon": null, "order": 1, "value": "Choose another experience to offer your guests"}]'::jsonb,
    '[{"icon": "cocktail-regular", "order": 1, "value": "{reward.name}"}]'::jsonb,
    '/main/modals/journeys/{id}/offer-select-type',
    'OFFER',
    null,
    false,
    'g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d'  -- "During" group
  );
