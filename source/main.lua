-- Core libs
import 'CoreLibs/animation'
import 'CoreLibs/animator'
import 'CoreLibs/crank'
import 'CoreLibs/frameTimer'
import 'CoreLibs/graphics'
import 'CoreLibs/keyboard'
import 'CoreLibs/object'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'
import 'CoreLibs/ui'
-- Global variables
import 'globals'
-- Toybox-managed libraries
-- import 'toyboxes'
-- Core utilities
import 'util/core/__init__'
-- Optional utilities (uncomment as needed)
-- import 'util/data'
-- import 'util/music'
-- import 'util/screenshake'
-- Scenes
import 'scenes/game/scene'


local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Debug
-- ===============================================================================
-- Debug flag names
local kDebugFlagNames <const> = {
    -- Define debug flag name strings here
}
-- DebugManager object
DEBUG_MANAGER = DebugManager(kDebugFlagNames)

-- --------------------------------------------------------------------------------
-- Uncomment to disable all debug flags
-- --------------------------------------------------------------------------------
-- DEBUG_MANAGER:disable()
-- --------------------------------------------------------------------------------
-- General Debug Options
-- --------------------------------------------------------------------------------
-- Verbose logging.
DEBUG_MANAGER:setFlag('verbose')

-- ===============================================================================
-- Scenes
-- ===============================================================================
-- Global enum of scenes
SCENES = {
    game = GameScene,
}
-- Scene Manager
SCENE_MANAGER = SceneManager()
-- Load initial scene
SCENE_MANAGER:loadInitialScene(SCENES.game)

-- ===============================================================================
-- Utility Objects
-- (Be sure to uncomment imports!)
-- ===============================================================================
-- Save/Load Data
-- DATA_MANAGER = DataManager()

-- Music Manager (Note: Dependent on DATA_MANAGER for prefs)
-- MUSIC_MANAGER = MusicManager()

-- Screen Shaker
-- SCREEN_SHAKE = ScreenShake()

-- ===============================================================================
-- Setup
-- ===============================================================================
local function setup()
    pd.display.setRefreshRate(50)
end

setup()

-- ===============================================================================
-- Game Loop
-- ===============================================================================
function pd.update()
    updateDeltaTime()
    gfx.sprite.update()
    pd.timer.updateTimers()
    pd.frameTimer.updateTimers()
end
