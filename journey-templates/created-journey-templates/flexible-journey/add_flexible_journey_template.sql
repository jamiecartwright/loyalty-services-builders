-- ============================================================
-- FLEXIBLE_JOURNEY Template Migration
-- ============================================================
-- Adds a fully customizable journey template that allows merchants
-- to define their own audience rules, offers, and messaging.
--
-- Steps:
--   1. Audience (required) - Filter guestbook for targeting
--   2. Before: Invite guests in (optional) - Pre-visit message
--   3. During: Deliver guest experience (optional) - Offer/reward
--   4. After: Thank guests (optional) - Post-visit message
-- ============================================================

-- Step 1: Insert base template
INSERT INTO journey_templates
  (id, journey_type, portal, name, description, image_url)
VALUES
  (
    'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
    'FLEXIBLE_JOURNEY',
    'merchant',
    'Build a custom guest experience',
    'Create a custom experience by choosing your selected guests, the experience you want to offer, and how you''d like to welcome them in.',
    null
  );

-- Step 2: Insert builder flow
INSERT INTO journey_builder_flows
  (id, journey_template_id, background_image_url, title, description, is_reward_selection_required)
VALUES
  (
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
    'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
    null,
    'Build a custom guest experience',
    'Create a custom experience by choosing your selected guests, the experience you want to offer, and how you''d like to welcome them in.',
    true
  );

-- Step 3: Insert builder flow steps
-- Note: Reusing existing step_ids from journey_steps table (created in V110)
-- 
-- JSONB format matches existing production data (flat structure):
--   [{"icon": null, "order": 1, "value": "text"}]

INSERT INTO journey_builder_flow_steps
  (id, flow_id, step_id, step_order, is_required, badge_label, badge_icon, default_body, body, builder_entrypoint, template_type, template_id, show_merchant_selector)
VALUES
  -- Step 1: Audience (required)
  (
    'e3f4a5b6-c7d8-4e9f-0a1b-2c3d4e5f6a7b',
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
    '5f6a7b8c-9d0e-1f2a-3b4c-5d6e7f8a9b0c',  -- audience step_id from V110
    1,
    true,
    'Audience',
    'users-bold',
    '[{"icon": null, "order": 1, "value": "Reach out to valued guests based on visits, spend, tags, and more."}]'::jsonb,
    null,
    '/main/modals/journeys/{id}/audience',
    'AUDIENCE',
    'c7d8e9f0-a1b2-4c3d-4e5f-6a7b8c9d0e1f',  -- references audience template below
    false
  ),
  -- Step 2: Before - Invite guests in (optional)
  (
    'f4a5b6c7-d8e9-4f0a-1b2c-3d4e5f6a7b8c',
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
    '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d',  -- message step_id from V110
    2,
    false,
    'Before: Invite guests in',
    'chat-dots-bold',
    '[{"icon": null, "order": 1, "value": "Send a personalized message inviting or welcoming guests to your restaurant"}]'::jsonb,
    '[{"icon": "clock-regular", "order": 1, "value": "{campaign.schedule}"}, {"icon": "text-box", "order": 2, "value": "{campaign.textContent}"}]'::jsonb,
    '/main/modals/journeys/{id}/messaging-campaign-type',
    'SMS_CAMPAIGN',
    null,
    false
  ),
  -- Step 3: During - Deliver guest experience (optional)
  (
    'a5b6c7d8-e9f0-4a1b-2c3d-4e5f6a7b8c9d',
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
    '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',  -- offer step_id from V110
    3,
    false,
    'During: Deliver a guest experience',
    'gift-bold',
    '[{"icon": null, "order": 1, "value": "Choose which experience you''d like to automatically offer these guests to make them feel special."}]'::jsonb,
    '[{"icon": "cocktail-regular", "order": 1, "value": "{reward.name}"}]'::jsonb,
    '/main/modals/journeys/{id}/offer-select-type',
    'OFFER',
    null,
    false
  ),
  -- Step 4: After - Thank guests (optional)
  (
    'b6c7d8e9-f0a1-4b2c-3d4e-5f6a7b8c9d0e',
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
    '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d',  -- message step_id from V110 (reused for second message)
    4,
    false,
    'After: Thanks guests',
    'chat-dots-bold',
    '[{"icon": null, "order": 1, "value": "Send a note to thank guests for visiting and inviting them back in."}]'::jsonb,
    '[{"icon": "clock-regular", "order": 1, "value": "{campaign.schedule}"}, {"icon": "text-box", "order": 2, "value": "{campaign.textContent}"}]'::jsonb,
    '/main/modals/journeys/{id}/messaging-campaign-type',
    'SMS_CAMPAIGN',
    null,
    false
  );

-- Step 4: Insert audience template (empty rules - user defines everything)
INSERT INTO journey_audience_templates
  (id, journey_template_id, name, description, rules)
VALUES
  (
    'c7d8e9f0-a1b2-4c3d-4e5f-6a7b8c9d0e1f',
    'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
    'Choose an audience',
    'Filter who you would like to target',
    '[]'::jsonb
  );

-- Note: No journey_offer_templates or journey_sms_campaign_templates
-- are created because FLEXIBLE_JOURNEY has no presets - users configure from scratch.
