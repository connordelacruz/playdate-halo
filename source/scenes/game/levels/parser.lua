local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Parse JSON exported from Tiled and initialize a stage
-- ================================================================================
class('TiledParser').extends()

-- TODO: just parse out the stage size and coordinates of player and enemy spawns.
-- TODO: for now, just place objects at the spawns. We'll add spawner logic later

-- Returns a table with the following structure:
-- {
--     stage = {
--         width = <stage width (px)>,
--         height = <stage height (px)>,
--     },
--     spawns = {
--         player = {
--             x = <x coord>,
--             y = <y coord>,
--         },
--         enemies = {
--             {
--                 x = <x coord>,
--                 y = <y coord>,
--                 type = <'EnemyClassName'>,
--             },
--             ...
--         },
--     },
-- }
function TiledParser.loadLevel(jsonPath)
    local decoded = json.decodeFile(jsonPath)
    -- Tile size and dimensions
    local width = decoded.width
    local height = decoded.height
    local tileWidth = decoded.tilewidth
    local tileHeight = decoded.tileheight
    local pixelWidth = width * tileWidth
    local pixelHeight = height * tileHeight

    local levelData = {
        stage = {
            width = pixelWidth,
            height = pixelHeight,
        },
    }

    -- TODO: create Stage(), center should be 0,0

    for i=1,#decoded.layers do
        local layer = decoded.layers[i]
        -- TODO: gotta define our naming conventions, but for now this is fine
        if layer.name == 'spawns' then
            levelData.spawns = TiledParser.parseSpawns(layer)
        end
    end

    return levelData
end

function TiledParser.parseSpawns(spawnsLayer)
    local spawns = {
        player = {},
        enemies = {},
    }
    for i=1,#spawnsLayer.objects do
        local object = spawnsLayer.objects[i]
        -- TODO: can we define constants for these names in the export file somehow?
        if object.type == 'PlayerSpawn' then
            spawns.player.x = object.x
            spawns.player.y = object.y
        elseif object.type == 'EnemySpawn' then
            spawns.enemies[#spawns.enemies+1] = TiledParser.parseEnemySpawn(object)
        end
    end
    return spawns
end

function TiledParser.parseEnemySpawn(enemySpawnObject)
    local enemySpawn = {
        x = enemySpawnObject.x,
        y = enemySpawnObject.y,
        type = 'Grunt',
    }
    -- TODO: eventually we'll want to be more dynamic with what gets spawned, but for now do this to practice with custom props
    for i=1,#enemySpawnObject.properties do
        local prop = enemySpawnObject.properties[i]
        if prop.name == 'type' then
            enemySpawn.type = prop.value
        end
    end
    return enemySpawn
end