-- Core libs
import 'CoreLibs/animation'
import 'CoreLibs/animator'
import 'CoreLibs/crank'
import 'CoreLibs/easing'
import 'CoreLibs/frameTimer'
import 'CoreLibs/graphics'
import 'CoreLibs/keyboard'
import 'CoreLibs/object'
import 'CoreLibs/math'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'
import 'CoreLibs/ui'
-- Global variables
import 'globals'
-- Toybox-managed libraries
import 'toyboxes'
-- Core utilities
import 'util/core/__init__'
-- Optional utilities (uncomment as needed)
import 'util/data'
import 'util/events'
import 'util/music'
-- import 'util/screenshake'
-- Scenes
import 'scenes/__init__'


local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Debug
-- ===============================================================================
-- Debug flag names
local kDebugFlagNames <const> = {
    'skipTitleScreen',
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
-- --------------------------------------------------------------------------------
-- Scenes
-- --------------------------------------------------------------------------------
-- Skip the title screen and start the game scene at launch
DEBUG_MANAGER:setFlag('skipTitleScreen')

-- ===============================================================================
-- Utility Objects
-- (Be sure to uncomment imports!)
-- ===============================================================================
-- Save/Load Data
DATA_MANAGER = DataManager()

-- Event Listener System
EVENTS = Events(DEBUG_MANAGER)

-- Music Manager (Note: Dependent on DATA_MANAGER for prefs)
MUSIC_MANAGER = MusicManager()

-- Screen Shaker
-- SCREEN_SHAKE = ScreenShake()

-- ===============================================================================
-- Scenes
-- ===============================================================================
-- Global enum of scenes
SCENES = {
    title = TitleScene,
    game = GameScene,
}
-- Scene Manager
SCENE_MANAGER = SceneManager()
-- Load initial scene
local initialScene = DEBUG_MANAGER:isFlagSet('skipTitleScreen') and SCENES.game or SCENES.title
SCENE_MANAGER:loadInitialScene(initialScene)

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
    SCENE_MANAGER:update()
end
