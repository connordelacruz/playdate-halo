import 'scenes/game/ui/__init__'
import 'scenes/game/weapons/__init__'
import 'scenes/game/items/__init__'
import 'scenes/game/entities/__init__'
import 'scenes/game/lifecycle'
import 'scenes/game/camera'
import 'scenes/game/scorekeeper'
import 'scenes/game/stage'

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

    -- Create stage and boundaries
    -- TODO: stage size + using stage to place entities instead of PD coordinates
    self.stage = Stage(SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2)
    -- Initialize score keeper
    self.scoreKeeper = ScoreKeeper()

    -- Initialize HUD
    self.hud = HUD()
    -- Spawn player in the center
    self.player = Player(SCREEN_WIDTH / 4, SCREEN_CENTER_Y)
    -- Start with an assault rifle
    self.player:giveWeapon(AssaultRifleWeapon)

    -- Create camera and attach to player's reticle
    self.camera = Camera()
    self.camera:attachTo(self.player.reticle)

    -- DEBUG: Spawn some hard-coded enemies for testing
    self.enemies = {
        -- GunnerDummy(SCREEN_WIDTH * 3 / 4, SCREEN_CENTER_Y, self.player),
        Elite(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4, self.player),
        -- Grunt(SCREEN_WIDTH - SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4, self.player),
        Elite(SCREEN_WIDTH - SCREEN_WIDTH / 4, 3 * SCREEN_HEIGHT / 4, self.player),
        -- Grunt(SCREEN_WIDTH / 4, 3 * SCREEN_HEIGHT / 4, self.player),
    }

    -- DEBUG: Spawn items for testing
    self.items = {
        WeaponPickup(SCREEN_WIDTH / 4, 3 * SCREEN_HEIGHT / 4, PlasmaPistolWeapon),
    }

    -- Register end game menu item
    self:registerMenuItems()
end

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