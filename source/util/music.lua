local pd <const> = playdate
-- ================================================================================
-- Constants
-- ================================================================================
-- Volume level to set player to when not muted.
local kPlayerVolume <const> = 1.0
-- Filename where playback prefs are stored
local kDataFilename <const> = 'music-prefs-data'

-- ================================================================================
-- Music Manager
-- ================================================================================
class('MusicManager').extends()

-- TODO: decouple from DEBUG_MANAGER and DATA_MANAGER
function MusicManager:init()
    -- --------------------------------------------------------------------------------
    -- Instance Variables
    -- --------------------------------------------------------------------------------
    -- Path to currently loaded track.
    -- Music will only play if this is set to a valid path.
    self.loadedTrack = nil
    -- Fileplayer object
    self.player = pd.sound.fileplayer.new()
    self.player:setVolume(kPlayerVolume)
    -- True if music playback preference is enabled, false if disabled.
    -- :loadData() will overwrite this default value.
    self.playMusic = true

    -- --------------------------------------------------------------------------------
    -- Music Playback Prefs
    -- --------------------------------------------------------------------------------
    -- Load saved music playback prefs
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function()
        self:saveData()
    end)
    -- Menu item for toggling music playback
    self:registerMenuItem()
end

-- --------------------------------------------------------------------------------
-- Load/Eject Track
-- --------------------------------------------------------------------------------

-- Sets self.loadedTrack, then loads it in self.player.
-- Ejects previous track first.
function MusicManager:loadTrack(trackPath)
    self:ejectTrack()
    DEBUG_MANAGER:vPrint('MusicManager: Loading track path: ' .. tostring(trackPath))
    self.loadedTrack = trackPath
    self.player:load(self.loadedTrack)
end

-- Unsets self.loadedTrack.
-- Stops player first.
function MusicManager:ejectTrack()
    DEBUG_MANAGER:vPrint('MusicManager: Ejecting track.')
    self:stop()
    self.loadedTrack = nil
end

-- Shorthand for calling :loadTrack() and then calling :play()
function MusicManager:loadAndPlayTrack(trackPath)
    self:loadTrack(trackPath)
    self:play()
end

-- --------------------------------------------------------------------------------
-- Player Controls
-- --------------------------------------------------------------------------------

-- Attempt to play currently loaded track.
function MusicManager:play()
    -- If no track "inserted", or music playback is disabled, just return
    if not self.playMusic or self.loadedTrack == nil then
        -- DEBUG
        local debugMsg = 'MusicManager: play() called, but '
        if not self.playMusic then
            debugMsg = debugMsg .. 'music playback disabled'
        else
            debugMsg = debugMsg .. 'no track is loaded'
        end
        debugMsg = debugMsg .. ', will not play.'
        DEBUG_MANAGER:vPrint(debugMsg)

        return
    end

    local loadedSuccessfully, error = self.player:play(0)
    -- DEBUG
    if loadedSuccessfully then
        DEBUG_MANAGER:vPrint('MusicManager: Track loaded successfully.')
    else
        DEBUG_MANAGER:vPrint('MusicManager: ERROR: Unable to play track:')
        DEBUG_MANAGER:vPrint(error, 1)
    end
end

-- Pause player.
function MusicManager:pause()
    self.player:pause()
end

-- Stop player.
function MusicManager:stop()
    self.player:stop()
end

-- Stop player and mute.
function MusicManager:mute()
    self:stop()
    self.player:setVolume(0.0)
end

-- Unmute.
-- If play = true, call self:play().
function MusicManager:unmute(play)
    self.player:setVolume(kPlayerVolume)
    if play then
        self:play()
    end
end

-- --------------------------------------------------------------------------------
-- System Menu Options + Save/Load Prefs
-- --------------------------------------------------------------------------------

-- Set self.playMusic.
-- If play is true, call :unmute(true)
-- If play is false, call :mute()
function MusicManager:togglePlayback(play)
    self.playMusic = play
    if play then
        self:unmute(true)
    else
        self:mute()
    end
end

-- Register 'play music' menu item.
function MusicManager:registerMenuItem()
    local menu = pd.getSystemMenu()
    local toggleMusicMenuItem, error = menu:addCheckmarkMenuItem(
        'play music', self.playMusic, function(val)
            DEBUG_MANAGER:vPrint('MusicManager: Music playback set to ' .. tostring(val))
            self:togglePlayback(val)
        end
    )
    if toggleMusicMenuItem == nil then
        DEBUG_MANAGER:vPrint('MusicManager: Unable to add music playback menu item:')
        DEBUG_MANAGER:vPrint(error, 1)
    end
end

-- Save music playback preference data.
function MusicManager:saveData()
    local data = { playMusic = self.playMusic }
    DEBUG_MANAGER:vPrint('MusicManager:saveData() called. Data:')
    DEBUG_MANAGER:vPrintTable(data)
    pd.datastore.write(data, kDataFilename)
end

-- Load music playback preference data.
function MusicManager:loadData()
    local loadedData = pd.datastore.read(kDataFilename)
    if loadedData == nil then
        DEBUG_MANAGER:vPrint('MusicManager: no save data found.')
        self:togglePlayback(true)
    else
        DEBUG_MANAGER:vPrint('MusicManager: save data found. Play music setting = ' .. tostring(loadedData.playMusic))
        self:togglePlayback(loadedData.playMusic)
    end
end
