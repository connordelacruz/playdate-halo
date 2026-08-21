local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- State "interface" for FSM pattern.
--
-- Note: When declaring State subclasses, be sure to set the `key` prop to a unique
--       string, as this will be used in the FSMSprite subclass to initialize its 
--       `states` and `state` values.
--
-- --------------------------------------------------------------------------------
-- Example Usage:
-- --------------------------------------------------------------------------------
--
-- -- Define common constructor for states for a given sprite
-- class('BallState').extends('State')
-- 
-- function BallState:init(ball)
--     self.ball = ball
-- end)
-- 
-- -- Inactive state (do nothing)
-- local kInactiveState <const> = 'inactive'
-- class('BallInactiveState', {
--     key = kInactiveState,
-- }).extends('BallState')
-- 
-- -- Active state (update position)
-- local kActiveState <const> = 'active'
-- class('BallActiveState', {
--     key = kActiveState,
-- }).extends('BallState')

-- function BallActiveState:enter()
--     -- Make sure no freeze frames are carried over
--     self.ball:resetHitFreeze()
-- end

-- function BallActiveState:update()
--     self.ball:updatePosition()
--     self.ball:checkIfOutOfBounds()
-- end
-- ================================================================================
class('State', {
    -- Key to use in FSMSprite's self.states list. MUST be unique for each state.
    key = 'NOT SET',
}).extends()

-- Constructor should be overridden.
function State:init(object)
    self.object = object
end

-- Method called when we switch to this state.
-- (Optional to implement)
function State:enter()
    return
end

-- Method called each frame.
-- (Must be implemented, otherwise what are you doing lol)
function State:update()
    return
end

-- Method called when we switch out of this state.
-- (Optional to implement)
function State:exit()
    return
end

-- ================================================================================
-- "Interface" for sprites that implement FSM states.
--
-- Note: Classes that implement this MUST initialize self.state and self.states
--       in their init() function.
--       
--       When defining the FSMSprite subclass, set the following properties:
--        - stateClasses: List all state classes for the sprite
--        - initialStateKey: String that corresponds to the `key` prop of the
--          initial state class
--
--       Then, in the sprite's init() method, simply call 
--       self:initStatesAndSetInitial()
--
-- --------------------------------------------------------------------------------
-- Example Usage:
-- --------------------------------------------------------------------------------
--
-- Define class, set stateClasses and initialStateKey
-- class('Ball', {
--     stateClasses = {
--         BallInactiveState,
--         BallActiveState,
--     },
--     initialStateKey = BallInactiveState.key,
-- }).extends('FSMSprite')
-- 
-- function Ball:init()
--     ...
--     -- Setup states and set initial state
--     self:initStatesAndSetInitial()
--     ...
-- end
-- ================================================================================
class('FSMSprite', {
    -- List of state classes for this sprite. Used to populate self.states when calling initStateObjects()
    stateClasses = {},
    -- Key for initial state to set when calling initStatesAndSetInitial()
    initialStateKey = 'NOT SET',
}).extends(gfx.sprite)

-- --------------------------------------------------------------------------------
-- Initialization Helpers
-- --------------------------------------------------------------------------------

-- Initialize self.states with instances of classes defined in stateClasses, indexed by each class' key prop.
-- Call this in implementing class's init() before calling setInitialState()
function FSMSprite:initStateObjects()
    self.states = {}
    for i=1,#self.stateClasses do
        local stateInstance = self.stateClasses[i](self)
        self.states[stateInstance.key] = stateInstance
    end
end

-- Calls initStateObjects(), then sets initial state based on initialStateKey prop.
function FSMSprite:initStatesAndSetInitial()
    self:initStateObjects()
    self:setInitialState(self.initialStateKey)
end

-- --------------------------------------------------------------------------------
-- State Setters
-- --------------------------------------------------------------------------------

-- Switch to a new state.
-- Note: newState must be a valid key into self.states.
--       self.state must be an instance of a State object.   
function FSMSprite:setState(newState)
    self.state:exit()
    self.state = self.states[newState]
    self.state:enter()
end

-- Shorthand to set initial state.
-- (Basicall the same as setState() but doesn't call exit() because there's no old state)
function FSMSprite:setInitialState(initialState)
    self.state = self.states[initialState]
    self.state:enter()
end

-- --------------------------------------------------------------------------------
-- Update
-- --------------------------------------------------------------------------------

-- Delegate update() to current state.
function FSMSprite:update()
    self.state:update()
end