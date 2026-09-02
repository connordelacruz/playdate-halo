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
}).extends('Enemy')

function Grunt:init(x, y, player)
    Grunt.super.init(self, x, y, player)

    -- Initialize states
    self:initStatesAndSetInitial()
    -- TODO: unnecessary:
    -- Move to initial position and add sprite
    self:moveTo(x, y)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

-- TODO: figure out commonalities w/ Player, extract logic up to Entity
function Grunt:initImages()
    self.idleWalkSpritesheet = gfx.imagetable.new('images/grunt/grunt-idle-walk')
    -- Frame 1 = idle, frames 2 - 7 = walking
    -- Frames 1 - 7 = facing right, frames 8 - 14 = facing left
    self.idleImages = {
        [DIRECTION_RIGHT] = self.idleWalkSpritesheet[1],
        [DIRECTION_LEFT] = self.idleWalkSpritesheet[8],
    }
    local walkingDelay = 100
    local walkingLoopRight = gfx.animation.loop.new(walkingDelay, self.idleWalkSpritesheet)
    walkingLoopRight.startFrame = 2
    walkingLoopRight.endFrame = 7
    local walkingLoopLeft = gfx.animation.loop.new(walkingDelay, self.idleWalkSpritesheet)
    walkingLoopLeft.startFrame = 8
    walkingLoopLeft.endFrame = 14
    self.walkingLoops = {
        [DIRECTION_RIGHT] = walkingLoopRight,
        [DIRECTION_LEFT] = walkingLoopLeft,
    }

    self.deathSpritesheet = gfx.imagetable.new('images/grunt/grunt-death')
    -- Frames 1-4 = facing right, frames 5-8 = facing left
    local deathDelay = 100
    local deathLoopRight = gfx.animation.loop.new(deathDelay, self.deathSpritesheet, false)
    -- Pause until needed
    deathLoopRight.paused = true
    deathLoopRight.startFrame = 1
    deathLoopRight.endFrame = 4
    local deathLoopLeft = gfx.animation.loop.new(deathDelay, self.deathSpritesheet, false)
    -- Pause until needed
    deathLoopLeft.paused = true
    deathLoopLeft.startFrame = 5
    deathLoopLeft.endFrame = 8
    self.deathLoops = {
        [DIRECTION_RIGHT] = deathLoopRight,
        [DIRECTION_LEFT] = deathLoopLeft,
    }

    -- Default fallback image
    self.defaultImage = self.idleImages[DIRECTION_RIGHT]
end

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