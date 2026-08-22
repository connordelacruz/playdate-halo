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
-- Collisions
-- --------------------------------------------------------------------------------
-- Tag names
local kTagNames <const> = {
    -- Player
    'player',
    -- Enemy
    'enemy',
    -- Projectiles
    'projectileFriendly',
    'projectileEnemy',
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
Z_INDEX = {
    -- Define common z-index vals here
}