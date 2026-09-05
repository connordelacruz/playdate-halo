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
-- Events
-- --------------------------------------------------------------------------------
-- Events for Entity objects.
local kEntityEventNames <const> = {
    -- Entity is initialized
    'spawn',
    -- Entity receives damage (to shields or health)
    'damageReceived',
    -- Health value changes
    'healthChange',
    -- Shield value changes
    'shieldChange',
    -- Shield value is 0
    'shieldEmpty',
    -- Shield is recharging
    'shieldRecharging',
    -- Entity dies
    'death',
    -- Entity gets a new weapon
    'weaponPickup',
}

-- Events for player.
-- All Entity events, but prefixed with 'player' and honoring camel case.
-- (E.g. 'spawn' -> 'playerSpawn')
local function generatePlayerEventNames()
    local playerEventNames = {}
    for i=1,#kEntityEventNames do
        local name = kEntityEventNames[i]
        -- Prefix and capitalize first letter of generic name
        playerEventNames[i] = 'player' .. name:gsub('^%l', string.upper)
    end
    return playerEventNames
end
local kPlayerEventNames <const> = generatePlayerEventNames()

-- Events for scoring.
local kScoreEventNames <const> = {
    'scoreChange',
}

-- Events for game lifecycle
local kGameLifecycleEvents <const> = {
    'gameOver',
}

-- Build event name list.
local function generateEventNames()
    local eventNames = {}
    for i=1,#kEntityEventNames do
        eventNames[#eventNames+1] = kEntityEventNames[i]
    end
    for i=1,#kPlayerEventNames do
        eventNames[#eventNames+1] = kPlayerEventNames[i]
    end
    for i=1,#kScoreEventNames do
        eventNames[#eventNames+1] = kScoreEventNames[i]
    end
    for i=1,#kGameLifecycleEvents do
        eventNames[#eventNames+1] = kGameLifecycleEvents[i]
    end

    return eventNames
end
local kEventNames <const> = generateEventNames()

-- Generate event types global from above names
local function generateEventTypes()
    local eventTypes = {}
    for i=1,#kEventNames do
        eventTypes[kEventNames[i]] = kEventNames[i]
    end
    return eventTypes
end
-- Event types
EVENT_TYPES = generateEventTypes()

-- --------------------------------------------------------------------------------
-- Z-Index Values
-- --------------------------------------------------------------------------------
-- Range: (-32768, 32767)
Z_INDEX = {
    -- UI popovers
    popup = 9999,
    -- UI overlays
    ui = 8000,
    -- Reticle
    reticle = 6000,
    -- Entities
    entity = 1000,
    -- Stage background
    background = -9999,
}