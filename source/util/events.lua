local pd <const> = playdate
-- ================================================================================
-- Event Trigger/Listener System
-- 
-- Inspired by: https://alexswan.dev/posts/playdate-event-system
-- ================================================================================
class('Events').extends()

function Events:init(debugManager)
    self.callbacks = {}
    -- (Optional) for debug logging
    self.debugManager = debugManager
end

-- Register an event listener.
function Events:on(event, callback)
    self.callbacks[event] = self.callbacks[event] or {}
    local callbackIndex = #self.callbacks[event]+1
    self.callbacks[event][callbackIndex] = callback
    self:log('Registered listener: event=' .. event .. ', i=' .. tostring(callbackIndex))
end

-- Deregister an event listener.
function Events:off(event, callback)
    if self.callbacks[event] == nil then
        self:log('off() called, but no listeners for event=' .. event)
        return
    end
    for i=1,#self.callbacks[event] do
        local current = self.callbacks[event][i]
        if current == callback then
            table.remove(self.callbacks[event], i)
            self:log('De-registered listener: event=' .. event .. ', i=' .. tostring(i))
            break
        end
    end
end

-- Trigger an event.
-- Additional parameters passed to executed callback functions.
function Events:emit(event, ...)
    self:log('Emitting event: ' .. event)
    if self.callbacks[event] == nil then
        self:log('- No listeners for event', 1)
        return
    end
    -- Copy in case array changes during execution.
    local eventCallbacks = table.shallowcopy(self.callbacks[event])
    for i=1,#eventCallbacks do
        self:log('- Executing callback i=' .. tostring(i), 1)
        eventCallbacks[i](...)
    end
end

-- --------------------------------------------------------------------------------
-- Batches
-- --------------------------------------------------------------------------------

-- Register multiple event listeners.
-- Parameter should be a table mapping event => callback
function Events:registerListeners(eventCallbacks)
    for event,callback in pairs(eventCallbacks) do
        self:on(event, callback)
    end
end

-- De-register multiple event listeners.
-- Parameter should be a table mapping event => callback
function Events:deregisterListeners(eventCallbacks)
    for event,callback in pairs(eventCallbacks) do
        self:off(event, callback)
    end
end

-- --------------------------------------------------------------------------------
-- Logging
-- --------------------------------------------------------------------------------

-- Shorthand for calling self.debugManager:vPrint() (after checking it exists)
-- Will prefix text with 'Events: ' unless indentLevel is > 0
function Events:log(text, indentLevel)
    if indentLevel == nil then
        indentLevel = 0
    end
    -- Prefix top-level logging with class name
    if indentLevel == 0 then
        text = 'Events: ' .. tostring(text)
    end
    if self.debugManager then
        self.debugManager:vPrint(text, indentLevel)
    end
end