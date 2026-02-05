-- ============================================================
-- Update Existing Journey Templates with Group Assignments
-- ============================================================
-- Updates for the existing 3 journey templates:
--   1. FIRST_TIME_GUESTS - reorder steps, assign groups
--   2. LOW_REVIEW_ENGAGEMENT - assign groups
--   3. BUSINESS_ACROSS_LOCATIONS - assign groups (new "Next visit" group)
--
-- Note: Uses groups created for FLEXIBLE_JOURNEY plus one new group
-- ============================================================

-- Group IDs:
--   Before:              g1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c
--   During:              g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d
--   Checkout and after:  g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e
--   Next visit:          g4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f (NEW)

-- ============================================================
-- Create new "Next visit" group
-- ============================================================

INSERT INTO journey_builder_groups (id, title, description)
VALUES ('g4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f', 'Next visit', null);

-- ============================================================
-- FIRST_TIME_GUESTS
-- ============================================================
-- Reorder: Offer becomes Step 2, Message becomes Step 3
-- Offer → "During", Message → "Checkout and after"

-- Swap step_order: Message (currently 2) → 3
UPDATE journey_builder_flow_steps
SET step_order = 3
WHERE id = '9f0e1d2c-3b4a-4596-8778-9a0b1c2d3e4f';

-- Swap step_order: Offer (currently 3) → 2
UPDATE journey_builder_flow_steps
SET step_order = 2
WHERE id = '5a6b7c8d-9e0f-41a2-b3c4-d5e6f7a8b9c0';

-- Step 2 (now Offer): → "During"
UPDATE journey_builder_flow_steps
SET group_id = 'g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d'
WHERE id = '5a6b7c8d-9e0f-41a2-b3c4-d5e6f7a8b9c0';

-- Step 3 (now Message): → "Checkout and after"
UPDATE journey_builder_flow_steps
SET group_id = 'g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e'
WHERE id = '9f0e1d2c-3b4a-4596-8778-9a0b1c2d3e4f';

-- ============================================================
-- LOW_REVIEW_ENGAGEMENT
-- ============================================================

-- Step 2: Message → "Before"
UPDATE journey_builder_flow_steps
SET group_id = 'g1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c'
WHERE id = 'b3c4d5e6-f7a8-49b0-c1d2-3e4f5a6b7c8d';

-- Step 3: Offer → "During"
UPDATE journey_builder_flow_steps
SET group_id = 'g2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d'
WHERE id = 'c5d6e7f8-a9b0-4c1d-2e3f-4a5b6c7d8e9f';

-- ============================================================
-- BUSINESS_ACROSS_LOCATIONS
-- ============================================================

-- Step 2: Message → "Checkout and after"
UPDATE journey_builder_flow_steps
SET group_id = 'g3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e'
WHERE id = 'e1f2a3b4-c5d6-47e8-9a0b-1c2d3e4f5a6b';

-- Step 3: Offer → "Next visit"
UPDATE journey_builder_flow_steps
SET group_id = 'g4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f'
WHERE id = 'f5a6b7c8-d9e0-41f2-3a4b-5c6d7e8f9a0b';
