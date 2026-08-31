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
-- HUD Sprite Class
-- 
-- Contains and manages each HUD element
-- ================================================================================
class('HUD').extends(gfx.sprite)

function HUD:init()
    self.elements = {
        HealthHUDElement(0, 0, 0.0, 0.0),
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
function HUDElement:updateUI()
    -- TODO: make it optional to recompute layout
    self.uiTree:layout()
    self.uiTree:draw()
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

function HealthHUDElement:init(x, y, centerX, centerY)
    self.eventListeners = {
        [EVENT_TYPES.playerSpawn] = function (player)
            self:updateValues(player)
        end
        -- TODO: listeners for health/shield updates
    }
    HealthHUDElement.super.init(self, x, y, centerX, centerY)
end

-- TODO: temp UI, make pretty
function HealthHUDElement:buildUITree()
    -- TODO: Initial values from where??
    self.shieldsTxt = txt(
        'shields: 0',
        {
            stroke = 1,
        }
    )
    self.healthTxt = txt(
        'health: 0',
        {
            stroke = 1,
        }
    )
    local container = box(
        {
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
    -- TODO: make pretty
    self.shieldsTxt.text = 'shields: ' .. tostring(val)
    self:updateUI()
end

function HealthHUDElement:updateHealth(val)
    -- TODO: make pretty
    self.healthTxt.text = 'health: ' .. tostring(val)
    self:updateUI()
end