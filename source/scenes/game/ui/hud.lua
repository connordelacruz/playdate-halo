local pd <const> = playdate
local gfx <const> = pd.graphics
-- playout
local box <const> = playout.box.new
local txt <const> = playout.text.new
local img <const> = playout.image.new
-- ================================================================================
-- Heads Up Display UI and Related Sounds
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Styling
-- --------------------------------------------------------------------------------
-- Text
local kHUDFont <const> = gfx.font.new('fonts/Roobert-11-Mono-Condensed')
local kTextStroke <const> = 1
local kTextStyles <const> = {
    font = kHUDFont,
    -- NOTE: playout.text does not honor these styles:
    stroke = kTextStroke,
}
-- Containers
local kContainerPadding <const> = 4
local kContainerStyles <const> = {
    padding = kContainerPadding,
}
-- --------------------------------------------------------------------------------
-- HUD sound effects
-- --------------------------------------------------------------------------------
local kShieldHitSound <const> = pd.sound.sampleplayer.new('sounds/shield/shield_hit.wav')
local kShieldLowSound <const> = pd.sound.sampleplayer.new('sounds/shield/shield_low.wav')
-- TODO: move to Shield
local kShieldPopSound <const> = pd.sound.sampleplayer.new('sounds/shield/shield_pop_spartan.wav')
local kShieldDepletedSound <const> = pd.sound.sampleplayer.new('sounds/shield/shield_depleted.wav')
local kShieldRechargeSound <const> = pd.sound.sampleplayer.new('sounds/shield/shield_recharge.wav')
-- --------------------------------------------------------------------------------
-- Screen shake amounts
-- --------------------------------------------------------------------------------
-- Shield breaks
local kShieldDepletedShakeAmount <const> = 5
-- Base amount to shake screen when receiving health damage
local kHealthDamageBaseShakeAmount <const> = 5
-- Additional amount to shake screen for each point below base health
local kHealthDamageShakeAmountModifier <const> = 2
-- Screen shake on player death
local kDeathShakeAmount <const> = 15

-- ================================================================================
-- HUD Sprite Class
-- 
-- Contains and manages each HUD element
-- ================================================================================
class('HUD').extends(gfx.sprite)

function HUD:init()
    self.elements = {
        HealthHUDElement(0, 0, 0.0, 0.0),
        ScoreHUDElement(SCREEN_CENTER_X, 0, 0.5, 0.0),
        WeaponHUDElement(SCREEN_WIDTH, 0, 1.0, 0.0),
    }
    self:add()
end

-- Remove HUD elements when top level sprite removed
function HUD:remove()
    for i=1,#self.elements do
        self.elements[i]:remove()
    end
    HUD.super.remove(self)
end

-- ================================================================================
-- HUD Elements
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Parent class for HUD elements
-- --------------------------------------------------------------------------------
class('HUDElement').extends(gfx.sprite)

-- NOTE: child classes should initialize self.eventListeners before calling parent constructor
function HUDElement:init(x, y, centerX, centerY)
    self:setZIndex(Z_INDEX.ui)
    self:setIgnoresDrawOffset(true)

    self:initUI()

    -- Event names mapped to listener functions.
    -- Implementing classes should define this before calling parent constructor.
    if self.eventListeners == nil then
        self.eventListeners = {}
    end
    EVENTS:registerListeners(self.eventListeners)

    -- Default to top-left corner if center values not set
    if centerX == nil then
        centerX = 0.0
    end
    if centerY == nil then
        centerY = 0.0
    end
    self:setCenter(centerX, centerY)

    self:moveTo(x, y)
    self:add()
end

-- TODO: this could be abstracted further into a generic UISprite class
-- Function to initialize UI graphics and set sprite image
function HUDElement:initUI()
    self.uiTree = self:buildUITree()
    local uiImage = self.uiTree:draw()
    self:setImage(uiImage)
end

-- Build playout UI tree.
function HUDElement:buildUITree()
    -- Implementing class should override this function
    local tmpTxt = txt(
        'placeholder',
        {
            alignment = kTextAlignment.center,
            stroke = 1,
        }
    )
    local tmpContainer = box(
        {
            padding = 4,
        },
        {
            tmpTxt,
        }
    )
    return playout.tree.new(tmpContainer)
end

-- Update UI.
function HUDElement:updateUI(skipLayoutRecompute)
    if not skipLayoutRecompute then
        self.uiTree:layout()
    end
    self:setImage(self.uiTree:draw())
end

-- De-register listeners on removal
function HUDElement:remove()
    EVENTS:deregisterListeners(self.eventListeners)
    HUDElement.super.remove(self)
end

-- --------------------------------------------------------------------------------
-- Health and Shields
-- --------------------------------------------------------------------------------
class('HealthHUDElement').extends('HUDElement')

function HealthHUDElement:init(...)
    self.eventListeners = {
        [EVENT_TYPES.playerSpawn] = function (player)
            self:updateValues(player)
        end,
        [EVENT_TYPES.playerHealthChange] = function (player)
            self:updateHealth(player.health)
        end,
        [EVENT_TYPES.playerShieldChange] = function (player)
            self:updateShields(player.shield.value)
        end,
        [EVENT_TYPES.playerDamageReceived] = function (player, shieldsUpWhenDamaged)
            self:handleDamageReceivedFeedback(player, shieldsUpWhenDamaged)
        end,
        [EVENT_TYPES.playerShieldLow] = function (player)
            self:handleShieldLowFeedback()
        end,
        [EVENT_TYPES.playerShieldEmpty] = function (player)
            self:handleShieldDepletedFeedback()
        end,
        [EVENT_TYPES.playerShieldRecharging] = function (player)
            self:handleShieldRechargingFeedback()
        end,
        [EVENT_TYPES.playerShieldFull] = function (player)
            self:stopShieldRechargeSound()
        end,
        [EVENT_TYPES.playerDeath] = function (player)
            self:handleDeathFeedback()
        end,
        [EVENT_TYPES.gameOver] = function (gm)
            -- Stop shield depleted loop
            self:toggleShieldDepletedSound(false)
        end,
    }
    HealthHUDElement.super.init(self, ...)
end

function HealthHUDElement:buildUITree()
    self.shieldsTxt = txt(
        'Shields: 0',
        {
            style = kTextStyles,
            stroke = kTextStroke,
        }
    )
    self.healthTxt = txt(
        'Health: 0',
        {
            style = kTextStyles,
            stroke = kTextStroke,
        }
    )
    local container = box(
        {
            hAlign = playout.kAlignStart,
            style = kContainerStyles,
        },
        {
            self.shieldsTxt,
            self.healthTxt,
        }
    )
    return playout.tree.new(container)
end

function HealthHUDElement:updateValues(player)
    self:updateShields(player.shield.value)
    self:updateHealth(player.health)
end

function HealthHUDElement:updateShields(val)
    self.shieldsTxt.text = 'Shields: ' .. tostring(val)
    self:updateUI()
end

function HealthHUDElement:updateHealth(val)
    self.healthTxt.text = 'Health: ' .. tostring(val)
    self:updateUI()
end

-- Shield hit sound
function HealthHUDElement:playShieldHitSound()
    kShieldHitSound:play(1)
end

-- Shield recharging sound
function HealthHUDElement:playShieldRechargeSound()
    kShieldRechargeSound:play(1)
end

-- Stop recharging sound
function HealthHUDElement:stopShieldRechargeSound()
    -- TODO: fade out??
    kShieldRechargeSound:stop()
end

-- Shield low sound.
-- Play on a loop. Should be toggled off when shields recharge, are depleted, or player dies.
function HealthHUDElement:toggleShieldLowSound(flag)
    if flag then
        kShieldLowSound:play(0)
    else
        kShieldLowSound:stop()
    end
end

-- Shield depleted sound.
-- Play on a loop. Should be toggled off when shields recharge or player dies.
function HealthHUDElement:toggleShieldDepletedSound(flag)
    if flag then
        kShieldDepletedSound:play(0)
    else
        kShieldDepletedSound:stop()
    end
end

-- Audio/visual feedback for damage
function HealthHUDElement:handleDamageReceivedFeedback(player, shieldsUpWhenDamaged)
    self:stopShieldRechargeSound()
    if shieldsUpWhenDamaged then
        self:playShieldHitSound()
    else
        local healthDiff = player.baseHealth - player.health
        local shakeAmount = kHealthDamageBaseShakeAmount + (healthDiff * kHealthDamageShakeAmountModifier)
        SCREEN_SHAKE:setShakeAmount(shakeAmount)
    end
end

-- Audio/visual feedback for shields low
function HealthHUDElement:handleShieldLowFeedback()
    self:toggleShieldLowSound(true)
end

-- Audio/visual feedback for shields down
function HealthHUDElement:handleShieldDepletedFeedback()
    -- Disable low sound
    self:toggleShieldLowSound(false)
    -- Start looping shield depleted sound
    self:toggleShieldDepletedSound(true)
    -- Shake that screen
    SCREEN_SHAKE:setShakeAmount(kShieldDepletedShakeAmount)
end

-- Audio/visual feedback for shield recharging
function HealthHUDElement:handleShieldRechargingFeedback()
    self:toggleShieldLowSound(false)
    self:toggleShieldDepletedSound(false)
    self:playShieldRechargeSound()
end

-- Audio/visual feedback for player death
function HealthHUDElement:handleDeathFeedback()
    self:toggleShieldLowSound(false)
    self:toggleShieldDepletedSound(false)
    SCREEN_SHAKE:setShakeAmount(kDeathShakeAmount)
end

-- --------------------------------------------------------------------------------
-- Score
-- --------------------------------------------------------------------------------
class('ScoreHUDElement').extends('HUDElement')

function ScoreHUDElement:init(...)
    self.eventListeners = {
        [EVENT_TYPES.scoreChange] = function (score)
            self:updateScore(score)
        end
    }
    ScoreHUDElement.super.init(self, ...)
end

-- Helper to 0-pad score
function ScoreHUDElement:formatScore(val)
    return string.format('%09d', val)
end

function ScoreHUDElement:buildUITree()
    self.scoreTxt = txt(
        self:formatScore(0),
        {
            alignment = kTextAlignment.center,
            style = kTextStyles,
            stroke = kTextStroke,
        }
    )
    local container = box(
        {
            style = kContainerStyles,
        },
        {
            self.scoreTxt,
        }
    )
    return playout.tree.new(container)
end

function ScoreHUDElement:updateScore(score)
    self.scoreTxt.text = self:formatScore(score)
    self:updateUI(true)
end

-- --------------------------------------------------------------------------------
-- Weapon and Ammo
-- --------------------------------------------------------------------------------
class('WeaponHUDElement').extends('HUDElement')

function WeaponHUDElement:init(...)
    self:initWeaponBackgroundImage()

    self.eventListeners = {
        [EVENT_TYPES.playerWeaponPickup] = function (weapon)
            self:updateValues(weapon)
        end,
    }
    WeaponHUDElement.super.init(self, ...)
end

function WeaponHUDElement:buildUITree()
    -- TODO: remove weapon name stuff
    self.weaponNameTxt = txt(
        'None',
        {
            alignment = kTextAlignment.right,
            style = kTextStyles,
            stroke = kTextStroke,
        }
    )
    self.ammoTxt = txt(
        self:formatAmmo(0),
        {
            alignment = kTextAlignment.right,
            style = kTextStyles,
            stroke = kTextStroke,
        }
    )
    self.weaponIconImg = img(self:createDummyWeaponImage())

    -- TODO: white bg, 1 px border
    local container = box(
        {
            -- hAlign = playout.kAlignEnd,
            direction = playout.kDirectionHorizontal,
            style = kContainerStyles,
        },
        {
            -- self.weaponNameTxt,
            self.ammoTxt,
            self.weaponIconImg,
        }
    )
    return playout.tree.new(container)
end

-- Initialize fixed-size image to use below weapon icons
function WeaponHUDElement:initWeaponBackgroundImage()
    -- This should be larger than all the currently-planned weapon images, and is fixed so we won't need to recompute the layout
    self.backgroundImage = gfx.image.new(50, 20, gfx.kColorWhite)
end

-- Create image for weapon icon
function WeaponHUDElement:createWeaponImage(weapon)
    local image = self.backgroundImage:copy()
    gfx.pushContext(image)
        weapon.icon:drawAnchored(image.width / 2, image.height / 2, 0.5, 0.5)
    gfx.popContext()
    return image
end

-- Dummy image, use base Weapon class icon
function WeaponHUDElement:createDummyWeaponImage()
    return self:createWeaponImage(Weapon)
end

-- Helper to 0-pad ammo
function WeaponHUDElement:formatAmmo(val)
    return string.format('%03d', val)
end

-- TODO: SMALL ICONS LOOK WEIRD. Maybe do recompute image layout and just not ammo?
-- TODO: UPDATE ALL TO USE ICON and REMOVE (or redesign??) NAME STUFF:
-- TODO: after 0 pad, updateUI() calls should not recompute layout

function WeaponHUDElement:updateValues(weapon)
    self:updateWeaponIcon(weapon)
    -- self:updateWeaponName(weapon.name)
    self:updateAmmo(weapon.ammo)
end

function WeaponHUDElement:updateWeaponIcon(weapon)
    self.weaponIconImg.img = self:createWeaponImage(weapon)
    self:updateUI()
end

-- TODO: remove
function WeaponHUDElement:updateWeaponName(name)
    DEBUG_MANAGER:vPrint(name)
    self.weaponNameTxt.text = name
    self:updateUI()
end

-- TODO: bottomless?
function WeaponHUDElement:updateAmmo(ammo)
    self.ammoTxt.text = self:formatAmmo(ammo)
    self:updateUI()
end