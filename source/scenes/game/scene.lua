import 'scenes/game/ui/__init__'
import 'scenes/game/weapons/__init__'
import 'scenes/game/items/__init__'
import 'scenes/game/entities/__init__'
import 'scenes/game/lifecycle'
import 'scenes/game/camera'
import 'scenes/game/scorekeeper'
import 'scenes/game/levels/__init__'

local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Game Scene Class
-- ================================================================================
class('GameScene', {
    name = 'game-scene',
}).extends('Scene')

function GameScene:init()
    self.gm = GameMaster()
    -- Initialize score keeper
    self.scoreKeeper = ScoreKeeper()
    -- Initialize HUD
    self.hud = HUD()

    self.levelData = TiledParser.loadLevel('tiled/stage1.json')
    -- Initialize stage, player, and enemies
    self:initLevel()
    -- Create camera and attach to player's reticle
    self.camera = Camera(self.player.reticle)

    -- DEBUG: Spawn items for testing
    self.items = {
        -- WeaponPickup(SCREEN_WIDTH / 4, 3 * SCREEN_HEIGHT / 4, PlasmaPistolWeapon),
    }

    -- Register end game menu item
    self:registerMenuItems()
end

-- --------------------------------------------------------------------------------
-- Initialize level objects
-- --------------------------------------------------------------------------------

-- Note: self.levelData must first be set to return value of TiledParser.loadLevel()
function GameScene:initLevel()
    DEBUG_MANAGER:vPrint('GameScene: initializing scene...')
    local levelData = self.levelData
    -- Initialize stage boundaries
    self.stage = Stage(levelData.stage.width, levelData.stage.height)
    DEBUG_MANAGER:vPrint('GameScene.stage: ' .. tostring(self.stage.width) .. 'x' .. tostring(self.stage.height))

    local spawns = levelData.spawns
    -- Spawn player
    self.player = Player(spawns.player.x, spawns.player.y)
    DEBUG_MANAGER:vPrint('GameScene.player spawned @ (' .. tostring(self.player.x) .. ', ' .. tostring(self.player.y) .. ')')
    -- TODO: "power weapon" start extracted somewhere else?
    self.player:giveWeapon(AssaultRifleWeapon)
    -- Spawn enemies
    self.enemies = {}
    local enemySpawns = spawns.enemies
    -- TODO: prob abstract this
    local enemyClassMap = {
        Elite = Elite,
        Grunt = Grunt,
    }
    for i=1,#enemySpawns do
        local enemySpawn = enemySpawns[i]
        if enemySpawn ~= nil and enemyClassMap[enemySpawn.type] ~= nil then
            local newEnemy = enemyClassMap[enemySpawn.type](enemySpawn.x, enemySpawn.y, self.player)
            self.enemies[#self.enemies + 1] = newEnemy
            DEBUG_MANAGER:vPrint('GameScene: ' .. enemySpawn.type .. ' spawned @ (' .. tostring(newEnemy.x) .. ', ' .. tostring(newEnemy.y) .. ')')
        else
            DEBUG_MANAGER:vPrint('GameScene: WARNING: unable to spawn enemy from map object:')
            DEBUG_MANAGER:vPrintTable(enemySpawn, 1)
        end
    end
    -- TODO: emit initialized event?
end

-- --------------------------------------------------------------------------------
-- Menu Items
-- --------------------------------------------------------------------------------

-- Register "end game" menu item
function GameScene:registerMenuItems()
    self.menuItems = {}
    local menu = pd.getSystemMenu()
    local quitToTitleMenuItem, error = menu:addMenuItem(
        'End Game',
        function ()
            DEBUG_MANAGER:vPrint('GameScene: "End Game" menu item clicked')
            -- Kill player to trigger game over
            self.player:kill()
            -- De-register menu item so game over can't be double triggered
            self:deregisterMenuItems()
        end
    )
    if quitToTitleMenuItem == nil then
        DEBUG_MANAGER:vPrint('GameScene: Failed to add menu item:')
        DEBUG_MANAGER:vPrint(error, 1)
    else
        self.menuItems[#self.menuItems+1] = quitToTitleMenuItem
    end
end

function GameScene:deregisterMenuItems()
    local menu = pd.getSystemMenu()
    for i=1,#self.menuItems do
        menu:removeMenuItem(self.menuItems[i])
    end
    self.menuItems = {}
end

-- --------------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------------

-- Show crank indicator if docked.
function GameScene:update()
    if pd.isCrankDocked() then
        pd.ui.crankIndicator:draw()
    end
end

-- De-register any menu items on remove()
function GameScene:remove()
    self:deregisterMenuItems()
    GameScene.super.remove(self)
end