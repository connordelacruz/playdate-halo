local pd <const> = playdate
-- ================================================================================
-- Save/Load Game Preferences
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- Filename where prefs save data is stored
local kDataFilename <const> = 'game-prefs-data'


-- ================================================================================
-- Preferences Manager
-- ================================================================================
class('Preferences').extends()

function Preferences:init()
    -- Preferences with defaults.
    -- Will be overwritten by :loadData()
    self.data = {
        -- TODO: decide what should be the default
        enableAutoShoot = false,
    }
    -- "Constants" for pref keys so we're not just using string literals
    self.keys = {}
    for k,_ in pairs(self.data) do
        self.keys[k] = k
    end

    -- Load saved prefs
    self:loadData()
    -- Register data save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)

    -- Register menu items
    -- TODO: if we add more than 1 or 2 prefs, we should have an options screen and use that instead
    self:registerMenuItems()
end

function Preferences:saveData()
    DEBUG_MANAGER:vPrint('Preferences:saveData() called. Data:')
    DEBUG_MANAGER:vPrintTable(self.data)
    pd.datastore.write(self.data, kDataFilename)
end

function Preferences:loadData()
    local loadedData = pd.datastore.read(kDataFilename)
    if loadedData == nil then
        DEBUG_MANAGER:vPrint('Preferences: no save data found.')
    else
        DEBUG_MANAGER:vPrint('Preferences: save data found:')
        DEBUG_MANAGER:vPrintTable(loadedData)
        -- Iterate through loaded data, that way any keys that get added later can 
        -- use their defaults set in init().
        for k,v in pairs(loadedData) do
            self.data[k] = v
        end
    end
end

function Preferences:registerMenuItems()
    local menu = pd.getSystemMenu()
    local enableAutoShootMenuItem, error = menu:addCheckmarkMenuItem(
        'auto-shoot',
        self.data.enableAutoShoot,
        function (val)
            self:set('enableAutoShoot', val)
        end
    )
    -- TODO: print error!
end

-- --------------------------------------------------------------------------------
-- Preference change functions
-- --------------------------------------------------------------------------------

-- Set value for a preference.
-- Emits a preference change event with the preference key and the new value
function Preferences:set(prefKey, val)
    self.data[prefKey] = val
    EVENTS:emit(EVENT_TYPES.preferenceChange, prefKey, val)
    DEBUG_MANAGER:vPrint('Preferences: ' .. prefKey .. ' set to: ' .. tostring(val))
end

-- Return a value for a preference.
function Preferences:get(prefKey)
    return self.data[prefKey]
end