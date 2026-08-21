-- ================================================================================
-- Debug Manager Class
-- ================================================================================
class('DebugManager').extends()

-- Parameter is an array of strings for debug flag names
-- Note: 'verbose' flag will always be added, do not define in flagNames
function DebugManager:init(flagNames)
    -- Bitmask with all currently set flags
    self.flags = 0
    -- Whether to enable or disable debug functionality
    self.enabled = true

    -- Generate mask values for each flag
    self.debugFlags = self:generateDebugMasks(flagNames)
end

-- --------------------------------------------------------------------------------
-- Enable/Disable Debug
--
-- If disabled, :isFlagSet() will always return false.
-- --------------------------------------------------------------------------------

function DebugManager:enable()
    self.enabled = true
end

function DebugManager:disable()
    self.enabled = false
end

-- --------------------------------------------------------------------------------
-- Flag Functions
-- --------------------------------------------------------------------------------

-- Initialization: Used to build flag mask values from flag names
function DebugManager:generateDebugMasks(flagNames)
    -- Always add the verbose flag
    table.insert(flagNames, 1, 'verbose')
    -- Assign a power of 2 to each flag
    local masks = {}
    for i = 1, #flagNames do
        masks[flagNames[i]] = 2 ^ (i - 1)
    end
    return masks
end

-- Helper: Check that a flag name is actually a defined flag
function DebugManager:isValidFlag(flagName)
    return self.debugFlags[flagName] ~= nil
end

-- Enable a flag
function DebugManager:setFlag(flagName)
    if self:isValidFlag(flagName) then
        self.flags = self.flags | self.debugFlags[flagName]
    else
        self:vPrint('DebugManager: attempted to set flag "' .. flagName .. '", but no such flag exists.')
    end
end

-- Disable a flag
function DebugManager:unsetFlag(flagName)
    if self:isValidFlag(flagName) then
        self.flags = self.flags & ~self.debugFlags[flagName]
    else
        self:vPrint('DebugManager: attempted to unset flag "' .. flagName .. '", but no such flag exists.')
    end
end

-- Check if a flag is set
function DebugManager:isFlagSet(flagName)
    return self.enabled and self:isValidFlag(flagName) and (self.flags & self.debugFlags[flagName]) > 0
end

-- --------------------------------------------------------------------------------
-- Verbose Printing
-- --------------------------------------------------------------------------------

-- NOTE: text param should be able to be parsed into a string with tostring().
function DebugManager:vPrint(text, indentLevel)
    if not self:isFlagSet('verbose') then
        return
    end
    local indent = self:getIndentString(indentLevel)
    print(indent .. tostring(text))
end

-- NOTE: dumping tables can freeze things up pretty bad with nested tables.
-- The default depth for dumping tables is 1 if not specified.
function DebugManager:vPrintTable(table, indentLevel, maxDepth)
    if not self:isFlagSet('verbose') then
        return
    end
    if maxDepth == nil then
        maxDepth = 1
    end
    print(self:tableToString(table, indentLevel, maxDepth))
end

-- --------------------------------------------------------------------------------
-- Logging Utilities
-- --------------------------------------------------------------------------------

function DebugManager:getIndentString(indentLevel)
    if type(indentLevel) ~= 'number' or indentLevel < 0 then
        indentLevel = 0
    end
    return string.rep('  ', indentLevel)
end

-- --------------------------------------------------------------------------------
-- Table Logging Helpers
-- --------------------------------------------------------------------------------

function DebugManager:tableToString(table, indentLevel, maxDepth)
    -- Param defaults
    if maxDepth == nil then
        maxDepth = 999
    end
    if indentLevel == nil then
        indentLevel = 1
    end

    local indent = self:getIndentString(indentLevel)
    local out = '{'

    for k, v in pairs(table) do
        local line = '\n' .. indent .. k .. ' = '
        local vType = type(v)
        if vType == 'table' then
            if indentLevel < maxDepth then
                line = line .. self:tableToString(v, indentLevel + 1)
            else
                line = line .. tostring(v)
            end
        elseif vType == 'string' then
            line = line .. v
        else
            line = line .. tostring(v)
        end
        out = out .. line
    end

    out = out .. '\n' .. indent .. '}'
    return out
end
