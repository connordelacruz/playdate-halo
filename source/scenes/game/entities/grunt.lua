local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Grunt Enemy
-- ================================================================================

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

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

-- TODO: figure out commonalities w/ Player, extract logic up to Entity

-- Set image for an active state (walking or idle).
function Grunt:setActiveImage()
    local newImage = self.defaultImage
    if self.isMoving then
        newImage = self.walkingLoops[self.direction]:image()
    else
        newImage = self.idleImages[self.direction]
    end
    self:setImage(newImage)
end

-- Unpause death animation.
function Grunt:playDeathAnimation()
    self.deathLoops[self.direction].paused = false
end

-- Set image from death animation. Return whether it's still playing.
function Grunt:setDeathImage()
    self:setImage(self.deathLoops[self.direction]:image())
    return self.deathLoops[self.direction]:isValid()
end