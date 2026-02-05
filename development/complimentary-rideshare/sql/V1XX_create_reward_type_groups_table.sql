-- Migration: Create synthetic_reward_type_groups table
-- Description: Enables grouping multiple reward types under a single selection card
-- 
-- NOTE: Replace V1XX with actual version number when ready to apply

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

-- Table documentation
COMMENT ON TABLE synthetic_reward_type_groups IS 
    'Groups multiple synthetic reward types under a single selection card on the reward type selection screen';

COMMENT ON COLUMN synthetic_reward_type_groups.id IS 
    'Primary key UUID';
    
COMMENT ON COLUMN synthetic_reward_type_groups.internal_name IS 
    'Machine-readable identifier (e.g., complimentary_rideshare). Must be unique.';
    
COMMENT ON COLUMN synthetic_reward_type_groups.external_label IS 
    'User-facing label displayed on the selection card (e.g., Complimentary Ride)';
    
COMMENT ON COLUMN synthetic_reward_type_groups.description IS 
    'User-facing description displayed below the label';
    
COMMENT ON COLUMN synthetic_reward_type_groups.icon IS 
    'Icon identifier for the selection card (e.g., car-front-regular)';
    
COMMENT ON COLUMN synthetic_reward_type_groups.display_rank IS 
    'Order in which groups appear on the selection screen (lower = higher priority)';
    
COMMENT ON COLUMN synthetic_reward_type_groups.issuer_type IS 
    'Filters which groups appear for which issuer types (DINING, HOME, RIDESHARE)';
    
COMMENT ON COLUMN synthetic_reward_type_groups.is_enabled IS 
    'Whether this group is currently active and should be shown';
