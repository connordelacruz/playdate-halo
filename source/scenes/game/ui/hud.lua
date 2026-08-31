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
    -- TODO: initialize sub-components
end

-- ================================================================================
-- HUD Elements
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Parent class for HUD elements
-- --------------------------------------------------------------------------------
class('HUDElement').extends(gfx.sprite)

function HUDElement:init(x, y)
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

-- De-register listeners on removal
function HUDElement:remove()
    EVENTS:deregisterListeners(self.eventListeners)
    HUDElement.super.remove(self)
end

-- --------------------------------------------------------------------------------
-- Health and Shields
-- --------------------------------------------------------------------------------