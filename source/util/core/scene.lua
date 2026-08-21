local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Scene Class
-- ===============================================================================
class('Scene', {
    -- Identifier for scene
    name = 'unnamed-scene',
}).extends(gfx.sprite)

-- Function to call when switching scenes before transition starts and cleanup.
-- Use this for things like removing input handlers.
function Scene:exit()
    return
end

-- Function to call after transition to this scene completes.
function Scene:transitionComplete()
    return
end

-- Function to call each frame via SceneManager:update().
-- This is for things that need updating outside of sprites, timers, etc.
-- E.g. if a scene needs to use the crank, put the crank indicator code here.
function Scene:update()
    return
end

-- ===============================================================================
-- Scene Manager Class
-- 
-- Based on https://github.com/SquidGodDev/Playdate-Scene-Management
-- ===============================================================================
class('SceneManager').extends()

-- TODO: this is fine for prototyping, but he mentions some drawbacks in his video that would be important to consider:
--          https://youtu.be/3LoMft137z8?si=030EkkgOlddfg976&t=802
-- TODO: most pressing (pun not intended) is that inputs still get parsed mid transition

function SceneManager:init()
    -- Timer length for transition
    -- TODO: convert to constant
    self.transitionTime = 500
    -- Whether we're currently transitioning
    self.transitioning = false
    -- The current scene object. Gets set after transitioning to a scene.
    self.currentSceneObject = nil
    -- Scene class we should transition to. Gets set in switchScene().
    self.newSceneClass = nil
end

-- --------------------------------------------------------------------------------
-- Scene Management Functions
-- --------------------------------------------------------------------------------

-- Set newScene and sceneArgs in preparation for loading a scene.
function SceneManager:prepareNewScene(scene, ...)
    self.newSceneClass = scene
    local args = {...}
    self.sceneArgs = args
end

-- Switch the current scene to a new one.
function SceneManager:switchScene(scene, ...)
    if self.transitioning then
        return
    end
    self.transitioning = true
    -- Exit previous scene
    self.currentSceneObject:exit()
    -- Prep new scene and begin transition
    self:prepareNewScene(scene, ...)
    self:startTransition()
end

-- Load first scene (no cleanup or transitions).
function SceneManager:loadInitialScene(scene, ...)
    self:prepareNewScene(scene, ...)
    self:loadNewScene()
    -- Since there's no transition, trigger transitionComplete() on scene
    self:transitionComplete()
end

-- Load a new scene. Called after fade out transition ends, before fade in.
function SceneManager:loadNewScene()
    if self.currentSceneObject ~= nil then
        self:cleanupScene()
    end
    -- Initialize scene class stored in self.newScene and assign the 
    -- object to self.currentScene
    self.currentSceneObject = self.newSceneClass(table.unpack(self.sceneArgs))
    self.newSceneClass = nil
end

-- Call update() on current scene.
-- This should be called in the main update() loop at the end
-- (after updating sprites, timers, etc).
function SceneManager:update()
    self.currentSceneObject:update()
end

-- --------------------------------------------------------------------------------
-- Cleanup Functions
-- --------------------------------------------------------------------------------

-- Cleanup the scene.
-- Called before loading a new one, after transition out but before transition in.
function SceneManager:cleanupScene()
    -- Remove all sprites
    self:cleanupSprites()
    -- Remove timers
    self:removeAllTimers()
    -- TODO: Maybe if we support different transitions, we don't necessarily want to reset offset??
    --       like if a transition moves the screen in and out of view w/ offsets
    -- Reset screen offset
    pd.display.setOffset(0, 0)
end

-- Remove all* sprites.
-- NOTE: Skips sprites that have property doNotCleanup set to true.
function SceneManager:cleanupSprites()
    gfx.sprite.performOnAllSprites(function (sprite)
        if not sprite.doNotCleanup then
            sprite:remove()
        end
    end)
end

function SceneManager:removeAllTimers()
    local timers = pd.timer.allTimers()
    for i=1,#timers do
        timers[i]:remove()
    end
end

-- --------------------------------------------------------------------------------
-- Transition Logic Functions
-- --------------------------------------------------------------------------------

function SceneManager:startTransition()
    -- Fade out old scene timer
    local transitionTimer = self:fadeTransition(0, 1)
    transitionTimer.timerEndedCallback = function ()
        self:transitionOutTimerCallback()
    end
end

function SceneManager:transitionOutTimerCallback()
        self:loadNewScene()
        -- Fade in new scene timer
        local transitionTimer = self:fadeTransition(1, 0)
        transitionTimer.timerEndedCallback = function ()
            self:transitionInTimerCallback()
        end
end

function SceneManager:transitionInTimerCallback()
    self.transitioning = false
    self.transitionSprite:remove()
    -- Inform scene that transition has completed.
    self:transitionComplete()
end

-- Trigger transitionComplete() on scene after switching and finishing the transition.
function SceneManager:transitionComplete()
    self.currentSceneObject:transitionComplete()
end

-- --------------------------------------------------------------------------------
-- Fade Out/In Transition Functions
-- --------------------------------------------------------------------------------

-- Pre-compute fade out rect images
local fadedRects = {}
for alpha = 0, 1, 0.01 do
    local fadedImage = gfx.image.new(400, 240)
    gfx.pushContext(fadedImage)
        local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
        filledRect:drawFaded(0, 0, alpha, gfx.image.kDitherTypeBayer8x8)
    gfx.popContext()
    fadedRects[math.floor(alpha * 100)] = fadedImage
end
-- Loop doesn't add last image, so here it is manually
fadedRects[100] = gfx.image.new(400, 240, gfx.kColorBlack)

function SceneManager:fadeTransition(startValue, endValue)
    local transitionSprite = self:createTransitionSprite()
    transitionSprite:setImage(self:getFadedImage(startValue))

    local transitionTimer = pd.timer.new(self.transitionTime, startValue, endValue, pd.easingFunctions.inOutCubic)
    transitionTimer.updateCallback = function(timer)
        transitionSprite:setImage(self:getFadedImage(timer.value))
    end
    return transitionTimer
end

function SceneManager:createTransitionSprite()
    -- TODO: is it necessary to set an image here if we're immediately overriding it??
    -- TODO: screen size/center constants AT TOP OF FILE
    local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
    local transitionSprite = gfx.sprite.new(filledRect)
    transitionSprite:moveTo(200, 120)
    -- Set z-index to max
    transitionSprite:setZIndex(32767)
    transitionSprite:setIgnoresDrawOffset(true)
    transitionSprite:add()
    -- TODO: is this really necessary if we're also returning it? or vice versa?
    self.transitionSprite = transitionSprite
    return transitionSprite
end

function SceneManager:getFadedImage(alpha)
    return fadedRects[math.floor(alpha * 100)]
end

-- ===============================================================================
-- DEBUG: Placeholder Scene
-- ===============================================================================
class('PlaceholderScene', {
    name = 'placeholder',
}).extends('Scene')

function PlaceholderScene:init()
    self.placeholderTextSprite = self:createPlaceholderTextSprite()
    self.placeholderTextSprite:moveTo(pd.display.getWidth() // 2, pd.display.getHeight() // 2)
    self.placeholderTextSprite:add()
end

function PlaceholderScene:createPlaceholderTextSprite()
    local placeholderText = 'Placeholder Scene'
    local w, h = gfx.getTextSize(placeholderText)
    local placeholderImage = gfx.image.new(w, h)
    gfx.pushContext(placeholderImage)
        gfx.drawText(placeholderText, 0, 0)
    gfx.popContext()
    local placeholderTextSprite = gfx.sprite.new(placeholderImage)
    return placeholderTextSprite
end