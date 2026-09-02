local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Elite Entity Class
-- ================================================================================
class('Elite', {
    baseHealth = 2,
    baseShields = 3,
    baseSpeed = 80,
    points = 500,
    startingWeaponClass = PlasmaRifleWeapon,
    -- Images/spritesheets, animation delays, start/end frames:
    -- Idle + walking
    idleWalkSpritesheet = gfx.imagetable.new('images/elite/elite-idle-walk'),
    idleImageFrames = {
        [DIRECTION_RIGHT] = 2,
        [DIRECTION_LEFT] = 8,
    },
    walkingLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 1,
            endFrame = 6,
        },
        [DIRECTION_LEFT] = {
            startFrame = 7,
            endFrame = 12,
        },
    },
    walkingLoopDelay = 100,
    -- Death
    deathSpritesheet = gfx.imagetable.new('images/elite/elite-death'),
    deathLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 1,
            endFrame = 4,
        },
        [DIRECTION_LEFT] = {
            startFrame = 5,
            endFrame = 8,
        },
    },
    deathLoopDelay = 100,
}).extends('Enemy')
