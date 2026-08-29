local pd <const> = playdate
local gfx <const> = pd.graphics
-- playout
local box <const> = playout.box.new
local txt <const> = playout.text.new
local img <const> = playout.image.new
-- ================================================================================
-- "Game Over" text
-- ================================================================================
-- ================================================================================
-- States
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Common Constructor
-- --------------------------------------------------------------------------------
class('GameOverUIState').extends('State')

function GameOverUIState:init(sprite)
    self.sprite = sprite
end

-- --------------------------------------------------------------------------------
-- Active: Show on screen
-- --------------------------------------------------------------------------------
class('GameOverUIActiveState', {
    key = 'active',
}).extends('GameOverUIState')

-- ================================================================================
-- Sprite
-- ================================================================================
class('GameOverUI', {
    stateClasses = {
        GameOverUIActiveState,
    },
    initialStateKey = GameOverUIActiveState.key,
}).extends('FSMSprite')
-- TODO: add animations n make it look nicer eventually

function GameOverUI:init(x, y)
    -- TODO: make some kinda ui sprite class that shares common stuff
    self:initStatesAndSetInitial()
    self:initUI()

    self:setIgnoresDrawOffset(true)
    self:setZIndex(Z_INDEX.popup)
    self:moveTo(x, y)
    self:add()
end

function GameOverUI:initUI()
    self.uiTree = self:buildUITree()
    local uiImage = self.uiTree:draw()
    self:setImage(uiImage)
end

function GameOverUI:buildUITree()
    local gameOverTxt = txt(
        'GAME OVER',
        {
            alignment = kTextAlignment.center,
            color = gfx.kColorWhite,
        }
    )
    local gameOverContainer = box(
        {
            padding = 4,
            backgroundColor = gfx.kColorBlack,
        },
        {
            gameOverTxt,
        }
    )
    return playout.tree.new(gameOverContainer)
end