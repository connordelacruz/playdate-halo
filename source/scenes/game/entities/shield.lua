local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Manage an Entity's shield value and feedback effects
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Durations
-- --------------------------------------------------------------------------------
-- Duration to wait after taking damage to begin recharging
local kShieldRechargeAfterDamageDuration <const> = 3000
-- When recharging, wait this amount of time before incrementing shields again
local kShieldRechargeCooldownDuration <const> = 500

-- ================================================================================
-- States
-- ================================================================================
class('ShieldState').extends('State')

function ShieldState:init(shield)
    self.shield = shield
end

-- --------------------------------------------------------------------------------
-- Shields full
-- --------------------------------------------------------------------------------
class('ShieldFullState', {
    key = 'full',
}).extends('ShieldState')

-- Switch to partial/empty if no longer fully charged
function ShieldFullState:update()
    if not self.shield:isFullyCharged() then
        if self.shield.value > 0 then
            self.shield:setPartialState()
        else
            self.shield:setEmptyState()
        end
    end
end

-- --------------------------------------------------------------------------------
-- Shields partially damaged
-- --------------------------------------------------------------------------------
class('ShieldPartialState', {
    key = 'partial',
}).extends('ShieldState')

function ShieldPartialState:update()
    if self.shield:isDamageCooldownOver() then
        -- Recharge if cooldown has passed since last damage
        self.shield:setRechargingState()
    elseif self.shield.value <= 0 then
        -- Switch to empty
        self.shield:setEmptyState()
    end
end

-- --------------------------------------------------------------------------------
-- Shields empty
-- (same basic behavior as partial, but with visual effects)
-- --------------------------------------------------------------------------------
class('ShieldEmptyState', {
    key = 'empty',
}).extends('ShieldState')

-- TODO: "particle" effect

function ShieldEmptyState:enter()
    -- TODO: use a wrapper, should never be accessing values this deep
    self.shield.entity:emitShieldEmptyEvent()
end

function ShieldEmptyState:update()
    if self.shield:isDamageCooldownOver() then
        -- Recharge if cooldown has passed since last damage
        self.shield:setRechargingState()
    end
end

-- --------------------------------------------------------------------------------
-- Shields recharging
-- --------------------------------------------------------------------------------
class('ShieldRechargingState', {
    key = 'recharging',
}).extends('ShieldPartialState')

function ShieldRechargingState:enter()
    -- TODO: use a wrapper, should never be accessing values this deep
    self.shield.entity:emitShieldRechargingEvent()
end

function ShieldRechargingState:update()
    if not self.shield:isDamageCooldownOver() then
        -- If suddenly the damage cooldown is not over, we're taking damage, switch states appropriately
        -- TODO: this logic is reused in full state, extract to parent class func
        if self.shield.value > 0 then
            self.shield:setPartialState()
        else
            self.shield:setEmptyState()
        end
    else
        -- Recharge shield
        self.shield:attemptToRecharge()
        -- If shields are now full, switch states
        if self.shield:isFullyCharged() then
            self.shield:setFullState()
        end
    end

end

-- ================================================================================
-- Shield object
-- ================================================================================
class('Shield', {
    stateClasses = {
        ShieldFullState,
        ShieldPartialState,
        ShieldEmptyState,
        ShieldRechargingState,
    },
    initialStateKey = ShieldFullState.key,
}).extends('FSMSprite')

function Shield:init(entity)
    self.entity = entity
    -- Value when shields are full
    self.max = self.entity.baseShields
    -- Current shield value
    self.value = self.max
    -- For recharge, timestamp since last time a point was recharged
    self.lastRechargeTimestamp = -1

    self:initStatesAndSetInitial()
    self:add()
end

-- --------------------------------------------------------------------------------
-- Shield Value
-- --------------------------------------------------------------------------------

-- Set shield value, emit event.
function Shield:setValue(v)
    self.value = v
    self.entity:emitShieldChangeEvent()
end

-- Add to shield value.
-- Will not exceed max.
function Shield:addValue(v)
    local newValue = self.value + v
    if newValue <= self.max then
        self:setValue(newValue)
    end
end

-- Subtract from shield value.
-- If new value would be < 0, set value to 0 and return the remainder.
function Shield:subtractValue(v)
    local newValue = self.value - v
    local remainingDamage = 0
    if newValue < 0 then
        remainingDamage = -newValue
        newValue = 0
    end
    self:setValue(newValue)
    return remainingDamage
end

-- Returns true if shield value is at its max.
function Shield:isFullyCharged()
    return self.value == self.max
end

-- Returns true if shield is at 0.
function Shield:isEmpty()
    return self.value <= 0
end

-- --------------------------------------------------------------------------------
-- Recharging
-- --------------------------------------------------------------------------------

-- Returns true if duration since entity last took damage has passed and shield can start recharging.
function Shield:isDamageCooldownOver()
    return (pd.getCurrentTimeMilliseconds() - self.entity.damageReceivedTimestamp >= kShieldRechargeAfterDamageDuration) or (self.entity.damageReceivedTimestamp < 0)
end

-- Update timestamp of last recharge increment to current time.
function Shield:updateLastRechargeTimestamp()
    self.lastRechargeTimestamp = pd.getCurrentTimeMilliseconds()
end

-- Returns true if recharge cooldown has passed.
function Shield:isRechargeCooldownOver()
    return (pd.getCurrentTimeMilliseconds() - self.lastRechargeTimestamp >= kShieldRechargeCooldownDuration) or (self.lastRechargeTimestamp < 0)
end

-- Recharge shield by 1 point, update timestamp.
function Shield:rechargeBy1()
    self:addValue(1)
    self:updateLastRechargeTimestamp()
end

-- Attempt to recharge if cooldown has passed.
function Shield:attemptToRecharge()
    if self:isRechargeCooldownOver() then
        self:rechargeBy1()
    end
end

-- --------------------------------------------------------------------------------
-- State Setters
-- --------------------------------------------------------------------------------

function Shield:setFullState()
    self:setState(ShieldFullState.key)
end

function Shield:setPartialState()
    self:setState(ShieldPartialState.key)
end

function Shield:setEmptyState()
    self:setState(ShieldEmptyState.key)
end

function Shield:setRechargingState()
    self:setState(ShieldRechargingState.key)
end