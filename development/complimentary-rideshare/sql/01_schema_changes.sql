-- ============================================================================
-- COMPLIMENTARY RIDESHARE: SCHEMA CHANGES
-- ============================================================================
-- These changes require engineering work and must be applied FIRST
-- before the configuration SQL can be run.
--
-- Related tickets:
--   MR-2541: Create synthetic_reward_type_groups table
--   MR-2542: Seed complimentary rideshare group and reward types
-- ============================================================================

-- ============================================================================
-- PART 1: Create Reward Type Groups Table
-- ============================================================================

CREATE TABLE synthetic_reward_type_groups (
    id              VARCHAR(36)     PRIMARY KEY DEFAULT spanner.generate_uuid(),
    internal_name   TEXT            NOT NULL UNIQUE,
    external_label  TEXT            NOT NULL,
    description     TEXT,
    icon            TEXT,
    display_rank    INTEGER         NOT NULL DEFAULT 0,
    issuer_type     TEXT            NOT NULL,
    is_enabled      BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE synthetic_reward_type_groups IS 
    'Groups multiple synthetic reward types under a single selection card on the reward type selection screen';
COMMENT ON COLUMN synthetic_reward_type_groups.internal_name IS 
    'Machine-readable identifier (e.g., complimentary_rideshare)';
COMMENT ON COLUMN synthetic_reward_type_groups.external_label IS 
    'User-facing label shown on selection card (e.g., Complimentary Ride)';
COMMENT ON COLUMN synthetic_reward_type_groups.issuer_type IS 
    'Filters groups by issuer type (DINING, HOME, RIDESHARE, PROPERTY)';

-- ============================================================================
-- PART 2: Add group_id Foreign Key to Reward Types
-- ============================================================================

ALTER TABLE synthetic_reward_types
ADD COLUMN group_id VARCHAR(36) REFERENCES synthetic_reward_type_groups(id);

-- ============================================================================
-- PART 2B: Add description column to Element Options
-- ============================================================================
-- Needed for car type descriptions ("Luxury rides, professional drivers", etc.)

ALTER TABLE offer_builder_element_options
ADD COLUMN description TEXT;

COMMENT ON COLUMN offer_builder_element_options.description IS
    'Optional description shown below the option label (e.g., "Luxury rides, professional drivers")';

COMMENT ON COLUMN synthetic_reward_types.group_id IS 
    'If set, this type is a child of the specified group and should not appear directly on the main selection screen';

-- ============================================================================
-- PART 3: Seed Complimentary Rideshare Group
-- ============================================================================

INSERT INTO synthetic_reward_type_groups 
    (id, internal_name, external_label, description, icon, display_rank, issuer_type, is_enabled)
VALUES 
    (
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',  -- Fixed UUID for reference
        'complimentary_rideshare', 
        'Complimentary Ride', 
        'Gift guests a seamless way to go to and from your location',
        'car-front-regular',
        3,  -- Display after complimentary item (1) and discount (2)
        'DINING',
        TRUE
    );

-- ============================================================================
-- PART 4: Create/Update Rideshare Reward Types
-- ============================================================================

-- Option A: Update existing complimentary_rideshare_credit to be "TO" variant
-- (Use this if we want to keep the existing UUID)
UPDATE synthetic_reward_types 
SET 
    internal_name = 'complimentary_ride_to_merchant',
    external_label = 'Ride to merchant',
    description = 'Help guests get to your location with a complimentary ride credit',
    icon = 'car-front-regular',
    group_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    issuer_type = 'DINING',
    display_rank = 1
WHERE id = '5828f406-c7fe-4125-ab3b-d594a8d0a0a7';

-- Create new "FROM" variant
INSERT INTO synthetic_reward_types 
    (id, internal_name, external_label, description, icon, value_type, bilt_category, 
     value_format, currency, is_enabled, display_rank, issuer_type, group_id)
VALUES 
    (
        'b2c3d4e5-f6a7-8901-bcde-f23456789012',  -- New UUID
        'complimentary_ride_from_merchant',
        'Ride from merchant',
        'Help guests get home safely with a complimentary ride credit',
        'car-front-regular',
        'REDEEM_DOLLAR_CREDIT',
        'RIDESHARE',
        'FLAT',
        'DOLLARS',
        TRUE,
        2,
        'DINING',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    );

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check group was created
SELECT * FROM synthetic_reward_type_groups WHERE internal_name = 'complimentary_rideshare';

-- Check child types are linked
SELECT 
    g.external_label as group_name,
    t.id,
    t.internal_name,
    t.external_label,
    t.display_rank
FROM synthetic_reward_types t
JOIN synthetic_reward_type_groups g ON t.group_id = g.id
WHERE g.internal_name = 'complimentary_rideshare'
ORDER BY t.display_rank;
