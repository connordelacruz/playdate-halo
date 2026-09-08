import 'scenes/game/ui/gameover'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Game State Manager
-- ================================================================================
-- ================================================================================
-- Constants
-- ================================================================================
-- Duration to show "Game Over" before ending the game scene
local kGameOverDuration <const> = 3000

-- ================================================================================
-- States
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Common Constructor
-- --------------------------------------------------------------------------------
class('GameState').extends('State')

function GameState:init(gameMaster)
    self.gm = gameMaster
end

-- --------------------------------------------------------------------------------
-- Active Game
-- --------------------------------------------------------------------------------
class('GameActiveState', {
    key = 'active',
}).extends('GameState')

-- --------------------------------------------------------------------------------
-- "Game Over" Screen
-- --------------------------------------------------------------------------------
class('GameOverState', {
    key = 'game-over',
}).extends('GameState')

function GameOverState:enter()
    self.gm:emitGameOverEvent()
    self.gameOverTimestamp = pd.getCurrentTimeMilliseconds()
    self.gm:showGameOverText()
end

function GameOverState:update()
    if self.gameOverTimestamp + kGameOverDuration <= pd.getCurrentTimeMilliseconds() then
        self:exit()
    end
end

function GameOverState:exit()
    SCENE_MANAGER:switchScene(SCENES.title)
end

-- ================================================================================
-- Game Master
-- ================================================================================
class('GameMaster', {
    stateClasses = {
        GameActiveState,
        GameOverState,
    },
    initialStateKey = GameActiveState.key,
}).extends('FSMSprite')

function GameMaster:init()
    self:initStatesAndSetInitial()

    self.eventListeners = {
        [EVENT_TYPES.playerDeath] = function(entity)
            self:onPlayerDeath(entity)
        end,
    }
    EVENTS:registerListeners(self.eventListeners)

    self:add()
end

-- --------------------------------------------------------------------------------
-- Event Listeners
-- --------------------------------------------------------------------------------

-- Callback for 'playerDeath' event.
function GameMaster:onPlayerDeath(entity)
    -- If the player died, trigger game over
    self:triggerGameOver()
end

-- --------------------------------------------------------------------------------
-- Event Triggers
-- --------------------------------------------------------------------------------

function GameMaster:emitGameOverEvent()
    EVENTS:emit(EVENT_TYPES.gameOver, self)
end


-- --------------------------------------------------------------------------------
-- State
-- --------------------------------------------------------------------------------

function GameMaster:triggerGameOver()
    self:setState(GameOverState.key)
end

-- --------------------------------------------------------------------------------
-- UI
-- --------------------------------------------------------------------------------

function GameMaster:showGameOverText()
    -- TODO: animate in or whatever
    local gameOverUI = GameOverUI(SCREEN_CENTER_X, SCREEN_CENTER_Y)
end

-- --------------------------------------------------------------------------------
-- Cleanup
-- --------------------------------------------------------------------------------

-- De-register event listeners on remove()
function GameMaster:remove()
    EVENTS:deregisterListeners(self.eventListeners)
    GameMaster.super.remove(self)
end