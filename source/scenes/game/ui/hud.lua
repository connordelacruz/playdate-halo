local pd <const> = playdate
local gfx <const> = pd.graphics
-- playout
local box <const> = playout.box.new
local txt <const> = playout.text.new
local img <const> = playout.image.new
-- ================================================================================
-- Heads Up Display UI
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- TODO: add common style stuff
-- Monospace font for score TODO: find one that fits desired style
local kScoreFont <const> = gfx.font.new('fonts/Roobert-11-Mono-Condensed')

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

function HUDElement:init(x, y, centerX, centerY)
    self:setZIndex(Z_INDEX.ui)
    self:setIgnoresDrawOffset(true)

    self:initUI()

    -- Event names mapped to listener functions.
    -- Implementing classes should define this before calling parent constructor.
    -- TODO: document that in "doc block"
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
        -- TODO: listeners for shield updates
    }
    HealthHUDElement.super.init(self, ...)
end

-- TODO: temp UI, make pretty
function HealthHUDElement:buildUITree()
    self.shieldsTxt = txt(
        'Shields: 0',
        {
            stroke = 1,
        }
    )
    self.healthTxt = txt(
        'Health: 0',
        {
            stroke = 1,
        }
    )
    local container = box(
        {
            hAlign = playout.kAlignStart,
            padding = 4,
        },
        {
            self.shieldsTxt,
            self.healthTxt,
        }
    )
    return playout.tree.new(container)
end

function HealthHUDElement:updateValues(player)
    self:updateShields(player.shields)
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

-- --------------------------------------------------------------------------------
-- Weapon and Ammo
-- --------------------------------------------------------------------------------
class('WeaponHUDElement').extends('HUDElement')

function WeaponHUDElement:init(...)
    self.eventListeners = {
        [EVENT_TYPES.playerWeaponPickup] = function (weapon)
            self:updateValues(weapon)
        end,
    }
    WeaponHUDElement.super.init(self, ...)
end

-- TODO: temp UI, make it pretty
function WeaponHUDElement:buildUITree()
    -- TODO: will there be a case where there's no weapon normally?
    self.weaponNameTxt = txt(
        'None',
        {
            stroke = 1,
            alignment = kTextAlignment.right,
        }
    )
    self.ammoTxt = txt(
        'x0',
        {
            stroke = 1,
            alignment = kTextAlignment.right,
        }
    )
    local container = box(
        {
            hAlign = playout.kAlignEnd,
            padding = 4,
        },
        {
            self.weaponNameTxt,
            self.ammoTxt,
        }
    )
    return playout.tree.new(container)
end

function WeaponHUDElement:updateValues(weapon)
    -- TODO: account for nil??
    self:updateWeaponName(weapon.name)
    self:updateAmmo(weapon.ammo)
end

function WeaponHUDElement:updateWeaponName(name)
    DEBUG_MANAGER:vPrint(name)
    self.weaponNameTxt.text = name
    self:updateUI()
end

-- TODO: bottomless?
function WeaponHUDElement:updateAmmo(ammo)
    DEBUG_MANAGER:vPrint(ammo)
    self.ammoTxt.text = 'x' .. tostring(ammo)
    self:updateUI()
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
            font = kScoreFont,
            stroke = 1,
        }
    )
    local container = box(
        {
            padding = 4,
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