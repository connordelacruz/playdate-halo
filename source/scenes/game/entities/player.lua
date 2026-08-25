local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Player Attributes
-- --------------------------------------------------------------------------------
-- Base movement speed (px / sec)
local kPlayerSpeed <const> = 120
-- Base shields and health
local kPlayerBaseHealth <const> = 3
local kPlayerBaseShields <const> = 5
-- --------------------------------------------------------------------------------
-- Reticle
-- --------------------------------------------------------------------------------
-- Size of the reticle sprite
local kReticleSize <const> = 13

-- ================================================================================
-- Player States
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Common Constructor
-- --------------------------------------------------------------------------------
class('PlayerState').extends('State')

function PlayerState:init(player)
    self.player = player
end

-- --------------------------------------------------------------------------------
-- Active
-- --------------------------------------------------------------------------------
local kActiveState <const> = 'active'
class('PlayerActiveState', {
    key = kActiveState,
}).extends('PlayerState')

function PlayerActiveState:update()
    self.player:handleInput()
    self.player:setActiveImage()
end

-- ================================================================================
-- Player Sprite
-- ================================================================================
class('Player', {
    stateClasses = {
        PlayerActiveState,
    },
    initialStateKey = PlayerActiveState.key,
    -- Entity attributes:
    isFriendly = true,
    baseHealth = kPlayerBaseHealth,
    baseShields = kPlayerBaseShields,
    baseSpeed = kPlayerSpeed,
}).extends('Entity')

function Player:init(x, y)
    -- Initialize entity instance variables
    Player.super.init(self, x, y)

    -- Initialize spritesheets and animations
    self:initImages()
    -- Set initial image
    self:setActiveImage()

    -- Collisions
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.player)

    -- Reticle sprite
    local reticleRotationRadius = self.height // 2 + kReticleSize
    -- TODO: remove on self:remove()?
    self.reticle = Reticle(x, y, self:calculateAimingAngle(), reticleRotationRadius)

    -- Initialize states
    self:initStatesAndSetInitial()
    -- Move to initial position and add sprite
    self:moveTo(x, y)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Images and Animations
-- --------------------------------------------------------------------------------

-- Initialize images and animations.
function Player:initImages()
    -- Idle and Walking
    self.idleWalkSpritesheet = gfx.imagetable.new('images/chief/chief-idle-walk')
    -- Frame 1 = idle, frames 2 - 4 = walk animation
    -- Frames 1 - 4 = facing right, frames 5 - 8 = facing left
    self.idleImages = {
        [DIRECTION_RIGHT] = self.idleWalkSpritesheet[1],
        [DIRECTION_LEFT] = self.idleWalkSpritesheet[5],
    }
    local walkingDelay = 100
    local walkingLoopRight = gfx.animation.loop.new(walkingDelay, self.idleWalkSpritesheet)
    walkingLoopRight.startFrame = 2
    walkingLoopRight.endFrame = 4
    local walkingLoopLeft = gfx.animation.loop.new(walkingDelay, self.idleWalkSpritesheet)
    walkingLoopLeft.startFrame = 6
    walkingLoopLeft.endFrame = 8
    self.walkingLoops = {
        [DIRECTION_RIGHT] = walkingLoopRight,
        [DIRECTION_LEFT] = walkingLoopLeft,
    }

    -- Default fallback image
    self.defaultImage = self.idleImages[DIRECTION_RIGHT]
end

-- Set image for active state (walking or idle).
function Player:setActiveImage()
    local newImage = self.defaultImage
    if self.isMoving then
        newImage = self.walkingLoops[self.direction]:image()
    else
        newImage = self.idleImages[self.direction]
    end
    self:setImage(newImage)
end

-- --------------------------------------------------------------------------------
-- Input Handling
-- --------------------------------------------------------------------------------

-- Handles D-pad, button, and crank input.
function Player:handleInput()
    -- Button inputs
    local current, pressed, released = pd.getButtonState()
    self:handleMovement(current, pressed, released)
    self:handleButtons(current, pressed, released)
    -- Crank inputs
    self:handleAiming()
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

-- Check for D-Pad inputs and handle player movement.
-- Updates self.isMoving.
function Player:handleMovement(current, pressed, released)
    local dx = 0
    local dy = 0
    -- Determine direction player should move
    if (current & pd.kButtonUp) > 0 then
        dy -= 1
    end
    if (current & pd.kButtonDown) > 0 then
        dy += 1
    end
    if (current & pd.kButtonLeft) > 0 then
        dx -= 1
    end
    if (current & pd.kButtonRight) > 0 then
        dx += 1
    end

    -- Handle movement
    if dx ~= 0 or dy ~= 0 then
        self.isMoving = true
        -- Calculate distance to step
        local distance = self.speed * DELTA_TIME
        -- Divide distance by sqrt 2 for diagonal movement
        if dx ~= 0 and dy ~= 0 then
            distance = distance / math.sqrt(2)
        end
        -- Calculate desired position and move with collisions
        local targetX = self.x + dx * distance
        local targetY = self.y + dy * distance
        self:moveWithCollisions(targetX, targetY)
    else
        self.isMoving = false
    end
end

-- --------------------------------------------------------------------------------
-- Buttons
-- --------------------------------------------------------------------------------

-- Handle A/B buttons.
function Player:handleButtons(current, pressed, released)
    -- TODO: Maybe it would feel better to mash or hold B for shooting instead of auto-shooting? Try it out once more stuff is implemented
    -- Toggle weapon fire on B-press
    if (pressed & pd.kButtonB) > 0 then
        self:toggleWeaponFire()
    end
end

-- --------------------------------------------------------------------------------
-- Aiming and Direction
-- --------------------------------------------------------------------------------

-- Calculates the aiming angle based on the crank.
-- Applies an offset so pointing the crank up angles the reticle up.
function Player:calculateAimingAngle()
    return self:constrainAngle(pd.getCrankPosition() - 90)
end

-- Update reticle position and self.direction.
-- Call after updating player position.
function Player:handleAiming()
    self:updateDirectionFromAimingAngle()
    self.reticle:updatePosition(self.x, self.y, self:calculateAimingAngle())
end

-- --------------------------------------------------------------------------------
-- Weapons
-- --------------------------------------------------------------------------------

-- Toggle whether held weapon is firing or not.
-- Does nothing if no weapon held.
function Player:toggleWeaponFire()
    if self.weapon ~= nil then
        self.weapon:toggleFire()
    end
end


-- ================================================================================
-- Reticle Sprite
-- ================================================================================
class('Reticle').extends(gfx.sprite)

function Reticle:init(originX, originY, degrees, radius)
    -- Radius for the invisible circle around player that the reticle rotates around
    self.radius = radius
    -- TODO: z-index
    self:setImage(self:createImage(kReticleSize, kReticleSize))

    self:updatePosition(originX, originY, degrees)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

-- TODO: this honestly isn't bad, maybe just add white outlines around it
function Reticle:createImage(w, h)
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setLineWidth(1)
        gfx.drawCircleInRect(0, 0, w, h)
        gfx.drawLine(0, h // 2, w, h // 2)
        gfx.drawLine(w // 2, 0, w // 2, h)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(w / 2, h / 2, 1.5)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawPixel(w // 2, h // 2)
    gfx.popContext()
    return image
end

-- --------------------------------------------------------------------------------
-- Move Reticle
-- --------------------------------------------------------------------------------

function Reticle:updatePosition(originX, originY, degrees)
    local x = originX + (self.radius * math.cos(math.rad(degrees)))
    local y = originY + (self.radius * math.sin(math.rad(degrees)))
    self:moveTo(x, y)
end