local pd <const> = playdate
-- ===============================================================================
-- Constants
-- ===============================================================================
-- Default scene name if none is provided
local kDefaultSceneName <const> = 'no-scene'

-- ===============================================================================
-- Data Manager Class
-- ===============================================================================
class('DataManager').extends()

-- TODO: decouple from debug, take as a param?
function DataManager:init()
    self.saveFunctions = {}
    -- Invoke self:saveAll() on sleep/termination
    pd.gameWillTerminate = function ()
        self:saveAll()
    end
    pd.deviceWillSleep = function ()
        self:saveAll()
    end
end

-- TODO: LOGGING FOR REGISTER FUNCS!

function DataManager:registerSaveFunction(key, func, scene)
    if scene == nil then
        scene = kDefaultSceneName
    end
    if self.saveFunctions[scene] == nil then
        self.saveFunctions[scene] = {}
    end
    if self.saveFunctions[scene][key] == nil then
        self.saveFunctions[scene][key] = func
    end
end

function DataManager:deregisterSaveFunction(key, scene)
    if scene == nil then
        scene = kDefaultSceneName
    end
    if type(self.saveFunctions[scene]) == 'table' and self.saveFunctions[scene][key] ~= nil then
        self.saveFunctions[key] = nil
    end
end

function DataManager:deregisterAllSceneSaveFunctions(scene)
    if self.saveFunctions[scene] ~= nil then
        self.saveFunctions[scene] = nil
    end
end

function DataManager:saveAll()
    DEBUG_MANAGER:vPrint('DataManager: Calling all registered save functions...')
    for scene,saveFuncs in pairs(self.saveFunctions) do
        self:saveAllInScene(scene, saveFuncs)
    end
end

function DataManager:saveAllInScene(scene, saveFuncs)
    if saveFuncs == nil then
        saveFuncs = self.saveFunctions[scene]
    end
    DEBUG_MANAGER:vPrint('DataManager: Attempting to save all for scene: ' .. scene)
    if saveFuncs == nil then
        DEBUG_MANAGER:vPrint('No save functions registered for scene.', 1)
        return
    end
    for key,func in pairs(saveFuncs) do
        if type(func) == 'function' then
            DEBUG_MANAGER:vPrint('- ' .. key, 1)
            func()
        end
    end
end