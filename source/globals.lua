local pd <const> = playdate
-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Shorthand for screen dimensions
-- --------------------------------------------------------------------------------
SCREEN_WIDTH = pd.display.getWidth()
SCREEN_HEIGHT = pd.display.getHeight()
SCREEN_CENTER_X = SCREEN_WIDTH / 2
SCREEN_CENTER_Y = SCREEN_HEIGHT / 2
-- --------------------------------------------------------------------------------
-- Indexes for facing directions (left or right)
-- --------------------------------------------------------------------------------
DIRECTION_RIGHT = 1
DIRECTION_LEFT = 2

-- --------------------------------------------------------------------------------
-- Collisions
-- --------------------------------------------------------------------------------
-- Tag names
-- TODO: use masks? can define collides with behavior
local kTagNames <const> = {
    -- Player
    'player',
    -- Enemy
    'enemy',
    -- Projectiles
    'projectile',
    -- Level boundaries
    'wall',
}
-- Generate tag values from above names
local function generateTags()
    local tags = {}
    for i=1,#kTagNames do
        tags[kTagNames[i]] = i
    end
    return tags
end
-- Tags
TAGS = generateTags()

-- --------------------------------------------------------------------------------
-- Z-Index Values
-- --------------------------------------------------------------------------------
-- Range: (-32768, 32767)
Z_INDEX = {
    -- Entities
    entity = 1000,
    -- Stage background
    background = -9999,
}