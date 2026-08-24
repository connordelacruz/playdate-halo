local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Player Attributes
-- --------------------------------------------------------------------------------
-- Sprite size
local kPlayerWidth <const> = 16
local kPlayerHeight <const> = 24
-- Base movement speed (px / sec)
local kPlayerSpeed <const> = 140
-- --------------------------------------------------------------------------------
-- Reticle
-- --------------------------------------------------------------------------------
-- Size of the reticle sprite
local kReticleSize <const> = 13
-- Radius of the invisible circle around the player that the reticle rotates on
local kReticleRadius <const> = kPlayerHeight // 2 + kReticleSize

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
end

-- ================================================================================
-- Player Sprite
-- ================================================================================
-- TODO: parent class Entity that can share logic with Enemy
class('Player', {
    stateClasses = {
        PlayerActiveState,
    },
    initialStateKey = PlayerActiveState.key
}).extends('Entity')

function Player:init(x, y)
    -- Attributes
    self.speed = kPlayerSpeed
    -- Held weapon
    self.weapon = nil

    -- TODO: real sprites
    self:setImage(self:createPlaceholderImage(kPlayerWidth, kPlayerHeight))
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.player)

    -- Reticle sprite
    self.reticle = Reticle(x, y, self:calculateAimingAngle())

    -- Initialize states
    self:initStatesAndSetInitial()
    -- Move to initial position and add sprite
    self:moveTo(x, y)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

-- DEBUG: Generate placeholder image
function Player:createPlaceholderImage(w, h)
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.fillRoundRect(0, 0, w, h, 4)
    gfx.popContext()
    return image
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

-- Check for D-Pad inputs and handle player movement
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
        local distance = self.speed * DELTA_TIME
        -- Divide distance by sqrt 2 for diagonal movement
        if dx ~= 0 and dy ~= 0 then
            distance = distance / math.sqrt(2)
        end
        -- Calculate desired position and move with collisions
        local targetX = self.x + dx * distance
        local targetY = self.y + dy * distance
        self:moveWithCollisions(targetX, targetY)
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
-- Aiming
-- --------------------------------------------------------------------------------

-- Calculates the aiming angle based on the crank.
-- Applies an offset so pointing the crank up angles the reticle up.
function Player:calculateAimingAngle()
    return pd.getCrankPosition() - 90
end

-- Update reticle position. Call after updating player position
function Player:handleAiming()
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

function Reticle:init(originX, originY, degrees)
    -- Radius for the invisible circle around player that the reticle rotates around
    self.radius = kReticleRadius
    -- TODO: z-index
    self:setImage(self:createImage(kReticleSize, kReticleSize))

    self:updatePosition(originX, originY, degrees)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

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