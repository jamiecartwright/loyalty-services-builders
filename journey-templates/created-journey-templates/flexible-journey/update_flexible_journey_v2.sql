-- ============================================================
-- FLEXIBLE_JOURNEY Template Update V2 - New Copy from Figma
-- ============================================================
-- Updates:
--   1. Group title changes (Before visit, During visit, Checkout + Post visit, Next Visit)
--   2. Step 2 copy: "Send guests a note before reservation"
--   3. Step 3 copy: "Deliver a complimentary item"
--   4. Step 4 copy: "Add a friends & family discount"
--   5. Step 5 copy: "Send guests a note after reservation"
--   6. NEW Step 6: "Deliver a complimentary item" (Next Visit group)
--
-- Final order:
--   1. Audience (unchanged, no group)
--   2. Send guests a note before reservation (message) - group: "Before visit"
--   3. Deliver a complimentary item (offer) - group: "During visit"
--   4. Add a friends & family discount (offer) - group: "During visit"
--   5. Send guests a note after reservation (message) - group: "Checkout + Post visit"
--   6. Deliver a complimentary item (offer) - NEW - group: "Next Visit"
-- ============================================================

-- Flow ID reference
-- flow_id: 'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a'

-- ============================================================
-- Step 0: Update group titles
-- ============================================================

UPDATE journey_builder_groups
SET title = 'Before visit'
WHERE id = 'g1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c';

UPDATE journey_builder_groups
SET title = 'During visit'
WHERE id = 'g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d';

UPDATE journey_builder_groups
SET title = 'Checkout + Post visit'
WHERE id = 'g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e';

UPDATE journey_builder_groups
SET title = 'Next Visit'
WHERE id = 'g4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f';

-- ============================================================
-- Step 1: Update copy for existing steps
-- ============================================================

-- Update Step 2: "Send guests a note before reservation" - group: "Before visit"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Send guests a note before reservation',
  default_body = '[{"icon": null, "order": 1, "value": "Our concierge can send your guests a custom note before they arrive"}]'::jsonb
WHERE id = 'f4a5b6c7-d8e9-4f0a-1b2c-3d4e5f6a7b8c';

-- Update Step 3: "Deliver a complimentary item" - group: "During visit"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Deliver a complimentary item',
  default_body = '[{"icon": null, "order": 1, "value": "Surprise guests with a gift automatically sent from the kitchen"}]'::jsonb
WHERE id = 'a5b6c7d8-e9f0-4a1b-2c3d-4e5f6a7b8c9d';

-- Update Step 4: "Add a friends & family discount" - group: "During visit"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Add a friends & family discount',
  default_body = '[{"icon": null, "order": 1, "value": "Apply a discount to make guests feel like a VIP"}]'::jsonb
WHERE id = 'c8d9e0f1-a2b3-4c5d-6e7f-8a9b0c1d2e3f';

-- Update Step 5: "Send guests a note after reservation" - group: "Checkout + Post visit"
UPDATE journey_builder_flow_steps
SET 
  badge_label = 'Send guests a note after reservation',
  default_body = '[{"icon": null, "order": 1, "value": "Our concierge will send a note to thank guests for visiting and invite them back"}]'::jsonb
WHERE id = 'b6c7d8e9-f0a1-4b2c-3d4e-5f6a7b8c9d0e';

-- ============================================================
-- Step 2: Insert new step 6 - "Deliver a complimentary item" (Next Visit)
-- ============================================================

INSERT INTO journey_builder_flow_steps
  (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon, default_body, body, builder_entrypoint, template_type, template_id, show_merchant_selector, group_id)
VALUES
  (
    'd9e0f1a2-b3c4-5d6e-7f8a-9b0c1d2e3f4a',  -- new unique ID
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',  -- flow_id
    '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',  -- offer step_id (same as other offer steps)
    6,
    false,
    'Deliver a complimentary item',
    'gift-bold',
    '[{"icon": null, "order": 1, "value": "Send a gift from the kitchen when the guest returns for their next visit"}]'::jsonb,
    '[{"icon": "cocktail-regular", "order": 1, "value": "{reward.name}"}]'::jsonb,
    '/main/modals/journeys/{id}/offer-select-type',
    'OFFER',
    null,
    false,
    'g4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f'  -- "Next Visit" group
  );

-- ============================================================
-- Final step order after updates:
--   1. Audience (unchanged)
--   2. Send guests a note before reservation (message) - Before visit
--   3. Deliver a complimentary item (offer) - During visit
--   4. Add a friends & family discount (offer) - During visit
--   5. Send guests a note after reservation (message) - Checkout + Post visit
--   6. Deliver a complimentary item (offer) - Next Visit  ← NEW
-- ============================================================
