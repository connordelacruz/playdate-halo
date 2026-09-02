local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Grunt Entity Class
-- ================================================================================
class('Grunt', {
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 50,
    points = 100,
    startingWeaponClass = PlasmaPistolWeapon,
    -- Images/spritesheets, animation delays, start/end frames:
    -- Idle + walking
    idleWalkSpritesheet = gfx.imagetable.new('images/grunt/grunt-idle-walk'),
    idleImageFrames = {
        [DIRECTION_RIGHT] = 1,
        [DIRECTION_LEFT] = 8,
    },
    walkingLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 2,
            endFrame = 7,
        },
        [DIRECTION_LEFT] = {
            startFrame = 8,
            endFrame = 14,
        },
    },
    walkingLoopDelay = 100,
    -- Death
    deathSpritesheet = gfx.imagetable.new('images/grunt/grunt-death'),
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