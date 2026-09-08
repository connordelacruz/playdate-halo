local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Player Attributes
-- --------------------------------------------------------------------------------
-- TODO: just move these to the class definition
-- Base movement speed (px / sec)
local kPlayerSpeed <const> = 120
-- Base shields and health
local kPlayerBaseHealth <const> = 4
local kPlayerBaseShields <const> = 6
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
    self.player:setIdleWalkingImage()
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
    startingWeaponClass = MagnumWeapon,
    -- Event types:
    spawnEventType = EVENT_TYPES.playerSpawn,
    damageReceivedEventType = EVENT_TYPES.playerDamageReceived,
    healthChangeEventType = EVENT_TYPES.playerHealthChange,
    shieldChangeEventType = EVENT_TYPES.playerShieldChange,
    shieldLowEventType = EVENT_TYPES.playerShieldLow,
    shieldEmptyEventType = EVENT_TYPES.playerShieldEmpty,
    shieldRechargingEventType = EVENT_TYPES.playerShieldRecharging,
    shieldFullEventType = EVENT_TYPES.playerShieldFull,
    deathEventType = EVENT_TYPES.playerDeath,
    weaponPickupEventType = EVENT_TYPES.playerWeaponPickup,
    ammoChangeEventType = EVENT_TYPES.playerAmmoChange,
    ammoEmptyEventType = EVENT_TYPES.playerAmmoEmpty,
    -- Images/spritesheets, animation delays, start/end frames:
    -- Idle + walking
    idleWalkSpritesheet = gfx.imagetable.new('images/chief/chief-idle-walk'),
    idleImageFrames = {
        [DIRECTION_RIGHT] = 1,
        [DIRECTION_LEFT] = 5,
    },
    walkingLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 2,
            endFrame = 4,
        },
        [DIRECTION_LEFT] = {
            startFrame = 6,
            endFrame = 8,
        },
    },
    walkingLoopDelay = 100,
    -- Death
    deathSpritesheet = gfx.imagetable.new('images/chief/chief-death'),
    deathLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 1,
            endFrame = 2,
        },
        [DIRECTION_LEFT] = {
            startFrame = 3,
            endFrame = 4,
        },
    },
    deathLoopDelay = 100,
    -- DEBUG
    invincible = DEBUG_MANAGER:isFlagSet('degreelessnessMode'),
}).extends('Entity')

function Player:init(x, y)
    -- Initialize entity instance variables, images, collide rect
    Player.super.init(self, x, y)
    -- Player always faces aiming angle
    self.faceAimingAngle = true
    -- Stores the function to call when handling shooting input for the selected control style.
    self.weaponInputHandler = nil
    self:setShootControlStyle()
    -- Event listeners
    self.eventListeners = {
        [EVENT_TYPES.preferenceChange] = function (...)
            self:preferenceChangeListener(...)
        end,
        [EVENT_TYPES.playerAmmoEmpty] = function (weapon)
            self:onPlayerAmmoEmpty()
        end,
    }
    EVENTS:registerListeners(self.eventListeners)

    -- Collisions
    self:setTag(TAGS.player)

    -- Reticle sprite
    local reticleRotationRadius = self.height // 2 + kReticleSize
    self.reticle = Reticle(x, y, self:calculateAimingAngle(), reticleRotationRadius)

    -- Initialize states
    self:initStatesAndSetInitial()
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
        local _, _, collisions, _ = self:moveWithCollisions(targetX, targetY)
        self:handleCollisions(collisions)
    else
        self.isMoving = false
    end
end

-- --------------------------------------------------------------------------------
-- Collisions
-- --------------------------------------------------------------------------------

function Player:handleCollisions(collisions)
    for i=1,#collisions do
        local collision = collisions[i]
        local other = collision.other
        local tag = other:getTag()
        -- Item pickups
        if tag == TAGS.item then
            other:pickup(self)
        end
    end
end

-- --------------------------------------------------------------------------------
-- Buttons
-- --------------------------------------------------------------------------------

-- Handle A/B buttons.
function Player:handleButtons(current, pressed, released)
    self:handleWeaponInput(current, pressed, released)
end

-- Handle weapon firing.
-- Note: self.weaponInputHandler must be set via setShootControlStyle() first.
function Player:handleWeaponInput(current, pressed, released)
    self:weaponInputHandler(current, pressed, released)
end

-- Control Style: Automatic
function Player:handleWeaponInputAutomatic(current, pressed, released)
    -- Toggle weapon fire on/off with B press
    if (pressed & pd.kButtonB) > 0 then
        self:toggleWeaponFire()
    end
end

-- Control Style: Manual
function Player:handleWeaponInputManual(current, pressed, released)
    if (pressed & pd.kButtonB) > 0 then
        -- First press = fire once (accounting for weapon cooldown)
        self:attemptToFireWeapon()
    elseif (current & pd.kButtonB) > 0 then
        -- Held after first press = toggle fire on
        self:toggleWeaponFire(true)
    elseif (released & pd.kButtonB) > 0 then
        -- Released = toggle fire off
        self:toggleWeaponFire(false)
    end
end

-- Switch control styles.
-- Setting param to true will enable auto shoot, otherwise enable manual.
-- If not provided, will pull from system prefs.
function Player:setShootControlStyle(automatic)
    if automatic == nil then
        automatic = PREFERENCES:get(PREFERENCES.keys.enableAutoShoot)
    end
    DEBUG_MANAGER:vPrint('Player: setting auto shoot to ' .. tostring(automatic))
    if automatic then
        self.weaponInputHandler = self.handleWeaponInputAutomatic
    else
        self.weaponInputHandler = self.handleWeaponInputManual
    end
end

-- Event listener for pref changes.
-- If autoshoot changed, update control style
function Player:preferenceChangeListener(prefKey, val)
    if prefKey == PREFERENCES.keys.enableAutoShoot then
        -- Toggle fire off before switching styles
        self:toggleWeaponFire(false)
        self:emitPlayerAutoShootToggleEvent()
        self:setShootControlStyle()
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

-- Override toggleWeaponFire() to emit auto shoot toggle event
function Player:toggleWeaponFire(flag)
    Player.super.toggleWeaponFire(self, flag)
    if PREFERENCES:get(PREFERENCES.keys.enableAutoShoot) then
        self:emitPlayerAutoShootToggleEvent()
    end
end

-- Event listener for running out of ammo.
-- Switch to starting weapon.
function Player:onPlayerAmmoEmpty()
    -- TODO: some kinda feedback to indicate weapon switch due to no ammo
    -- Stop firing
    self:toggleWeaponFire(false)
    -- Switch to starting weapon
    self:giveStartingWeapon()
end

-- --------------------------------------------------------------------------------
-- Event Emitters
-- --------------------------------------------------------------------------------

function Player:emitPlayerAutoShootToggleEvent()
    EVENTS:emit(EVENT_TYPES.playerAutoShootToggle, self.weapon:isFiring())
end

-- --------------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------------

-- Remove reticle and de-register event listeners when Player is removed.
function Player:remove()
    self.reticle:remove()
    EVENTS:deregisterListeners(self.eventListeners)
    Player.super.remove(self)
end


-- ================================================================================
-- Reticle Sprite
-- ================================================================================
class('Reticle').extends(gfx.sprite)

function Reticle:init(originX, originY, degrees, radius)
    -- Radius for the invisible circle around player that the reticle rotates around
    self.radius = radius
    self:setZIndex(Z_INDEX.reticle)
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
        -- Background white circle
        gfx.setLineWidth(3)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleInRect(0, 0, w, h)
        -- Reticle circle
        gfx.setLineWidth(1)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleInRect(0, 0, w, h)
        -- Reticle crosshair
        gfx.drawLine(0, h // 2, w, h // 2)
        gfx.drawLine(w // 2, 0, w // 2, h)
        -- Cut a hole in the crosshair
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(w / 2, h / 2, 1.5)
        -- Center dot
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