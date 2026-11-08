-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/MapEditor/MapLoader.lua
-- *  PURPOSE:     Map Editor Map Loader class
-- *
-- ****************************************************************************

MapLoader = inherit(Singleton)

function MapLoader:constructor()
    self.m_Maps = {} -- contains objects !sorted by Map!
    self.m_MapRemovals = {} -- containts removed world objects !sorted by Map!
    self.m_MapInfos = {}
    self.m_Objects = {} -- containts !all! objects
    self.m_Categories = {}
    self.m_GangwarMaps = {}
end

function MapLoader:destructor()
    for id, map in ipairs(self.m_Maps) do

        for key, object in ipairs(map) do
            object:destroy()
        end
    end
end

function MapLoader:loadAllFromDatabase()
    local categories = sql:queryFetch("SELECT * FROM ??_map_editor_categories", sql:getPrefix())
    for i, v in pairs(categories) do
        self.m_Categories[v.Id] = v.Name
    end
    
    local maps = sql:queryFetch("SELECT * FROM ??_map_editor_maps", sql:getPrefix())
    for key, mRow in pairs(maps) do
        self.m_MapInfos[mRow.Id] = {mRow.Name, Account.getNameFromId(mRow.Creator), mRow.Activated, mRow.SaveObjects, mRow.Deactivatable, mRow.Category and mRow.Category or 0, tonumber(mRow.GangwarAreaId)}
        if tonumber(mRow.GangwarAreaId) then
            self.m_GangwarMaps[tonumber(mRow.GangwarAreaId)] = mRow.Id
        elseif mRow.Activated == 1 then
            self:loadFromDatabase(mRow.Id)
        end
    end
end

function MapLoader:createObjectFromRow(oRow, dimension)
    local object = createObject(oRow.Model, oRow.PosX, oRow.PosY, oRow.PosZ, oRow.RotX, oRow.RotY, oRow.RotZ)
    object:setScale(oRow.ScaleX, oRow.ScaleY, oRow.ScaleZ)
    object:setInterior(oRow.Interior)
    object:setDimension(dimension or oRow.Dimension)
    object:setCollisionsEnabled(toboolean(oRow.Collision))
    object:setDoubleSided(toboolean(oRow.Doublesided))
    object.m_TextureData = oRow.Textures and fromJSON(oRow.Textures) or {}
    object.m_Textures = {}
    object.m_LodEnabled = toboolean(oRow.LodEnabled)
    object:setData("breakable", toboolean(oRow.Breakable), toboolean(oRow.Breakable))

    self:loadTextures(object)
    self:createLowLOD(object)
    return object
end

function MapLoader:loadFromDatabase(id, dimension)
    if not self.m_Maps[id] then
        self.m_MapInfos[id][3] = 1
        self.m_Maps[id] = {}
        self.m_MapRemovals[id] = {}

        local objects = sql:queryFetch("SELECT * FROM ??_map_editor_objects WHERE MapId = ?", sql:getPrefix(), id)
        for key, oRow in pairs(objects) do
            if oRow.Type == 1 then
                local index = #self.m_Maps[id]+1
                local object = self:createObjectFromRow(oRow, dimension)

                self.m_Maps[id][index] = object
                object.m_Creator = oRow.Creator
                object.m_ObjectId = oRow.Id
                object.m_MapId = id
                object.m_Index = index
                object:setData("MapEditor:object", true, true)
                object:setData("MapEditor:id", oRow.Id, true)
                object:setData("MapEditor:mapId", id, true)

                self:addRef(object)
            elseif oRow.Type == 0 and not self:isGangwarMap(id) then
                local index = #self.m_MapRemovals[id]+1
                local radius = tonumber(oRow.Radius) or 0

                self.m_MapRemovals[id][index] = {insertId=oRow.Id, worldModelId=oRow.Model, wX=oRow.PosX, wY=oRow.PosY, wZ=oRow.PosZ, wrX=oRow.RotX, wrY=oRow.RotY, wrZ=oRow.RotZ, interior=oRow.Interior, radius=radius, creator=oRow.Creator}
                removeWorldModel(oRow.Model, radius, oRow.PosX, oRow.PosY, oRow.PosZ, oRow.Interior)
            end
        end
        triggerClientEvent(PlayerManager:getSingleton():getReadyPlayers(), "applyBreakableState", resourceRoot)
        return true
    end
    
    return false
end

function MapLoader:addObjectToMap(object, mapId, creator)
    if self.m_Maps[mapId] then
        local model = object:getModel()
        local x, y, z = getElementPosition(object)
        local rx, ry, rz = getElementRotation(object)
        local sx, sy, sz = getObjectScale(object)
        local interior = object:getInterior()
        local dimension = object:getDimension()
        local breakable = object:getData("breakable")
        local collision = object:getCollisionsEnabled()
        local doublesided = object:isDoubleSided()
        local textures = object.m_TextureData
        local lodEnabled = object.m_LodEnabled
        local creatorId = creator:getId() or 0
        local result, numrows, insertId = false, false, false

        if self:isMapSavingEnabled(mapId) then
            result, numrows, insertId = sql:queryFetch("INSERT INTO ??_map_editor_objects (Type, Model, PosX, PosY, PosZ, RotX, RotY, RotZ, ScaleX, ScaleY, ScaleZ, Interior, Dimension, Breakable, Collision, Doublesided, Textures, LodEnabled, MapId, Creator) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
                sql:getPrefix(), 1, model, math.round(x, 4), math.round(y, 4), math.round(z, 4), math.round(rx, 4), math.round(ry, 4), math.round(rz, 4), math.round(sx, 6), math.round(sy, 6), math.round(sz, 6), interior, dimension, fromboolean(breakable), fromboolean(collision), fromboolean(doublesided), toJSON(textures), fromboolean(lodEnabled), mapId, creatorId)
        end

        local index = #self.m_Maps[mapId]+1

        self.m_Maps[mapId][index] = object
        self.m_Maps[mapId][index].m_Creator = creatorId
        self.m_Maps[mapId][index].m_ObjectId = insertId
        self.m_Maps[mapId][index].m_MapId = mapId
        self.m_Maps[mapId][index].m_Index = index
        self.m_Maps[mapId][index].m_Textures = {}
        self.m_Maps[mapId][index]:setData("MapEditor:object", true, true)
        self.m_Maps[mapId][index]:setData("MapEditor:id", insertId, true)
        self.m_Maps[mapId][index]:setData("MapEditor:mapId", mapId, true)

        self:addRef(self.m_Maps[mapId][index])

        return true
    end
end

function MapLoader:updateObject(object)
    if object.m_MapId then
        local model = object:getModel()
        local x, y, z = getElementPosition(object)
        local rx, ry, rz = getElementRotation(object)
        local sx, sy, sz = getObjectScale(object)
        local interior = object:getInterior()
        local dimension = object:getDimension()
        local breakable = object:getData("breakable")
        local collision = object:getCollisionsEnabled()
        local doublesided = object:isDoubleSided()
        local textures = object.m_TextureData
        local lodEnabled = object.m_LodEnabled
        local creatorId = client:getId() or 0
        local objectId = object.m_ObjectId

        self:loadTextures(object)
        self:createLowLOD(object)

        if self:isMapSavingEnabled(object.m_MapId) then
            local result = sql:queryExec("UPDATE ??_map_editor_objects SET Model = ?, PosX = ?, PosY = ?, PosZ = ?, RotX = ?, RotY = ?, RotZ = ?, ScaleX = ?, ScaleY = ?, ScaleZ = ?, Interior = ?, Dimension = ?, Breakable = ?, Collision = ?, Doublesided = ?, Textures = ?, LodEnabled = ?, Creator = ? WHERE Id = ?", 
                sql:getPrefix(), model, math.round(x, 4), math.round(y, 4), math.round(z, 4), math.round(rx, 4), math.round(ry, 4), math.round(rz, 4), math.round(sx, 6), math.round(sy, 6), math.round(sz, 6), interior, dimension, fromboolean(breakable), fromboolean(collision), fromboolean(doublesided), toJSON(textures), fromboolean(lodEnabled), creatorId, objectId)
            
            return result
        end
    end
end

function MapLoader:removeObject(object)
    if object.m_ObjectId then
        sql:queryExec("DELETE FROM ??_map_editor_objects WHERE Id = ?", sql:getPrefix(), object.m_ObjectId)
    end
    if object.m_MapId then
        local mapId = object.m_MapId
        local index = object.m_Index
        
        self:removeRef(self.m_Maps[mapId][index])
        
        self.m_Maps[mapId][index]:destroy()
        table.remove(self.m_Maps[mapId], index)
        for key, obj in ipairs(self.m_Maps[mapId]) do
            obj.m_Index = key
        end

        return true
    end
end

function MapLoader:removeWorldModel(worldModelId, wX, wY, wZ, wrX, wrY, wrZ, radius, worldLODModelId, interior, mapId, creator)
    if removeWorldModel(worldModelId, radius, wX, wY, wZ, interior) then
        local index = #self.m_MapRemovals[mapId]+1
        local result, numrows, insertId = sql:queryFetch("INSERT INTO ??_map_editor_objects (Type, Model, PosX, PosY, PosZ, RotX, RotY, RotZ, Interior, MapId, Radius, Creator) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            sql:getPrefix(), 0, worldModelId, wX, wY, wZ, wrX, wrY, wrZ, interior, mapId, radius, creator)

        self.m_MapRemovals[mapId][index] = {insertId=insertId, worldModelId=worldModelId, wX=wX, wY=wY, wZ=wZ, wrX=wrX, wrY=wrY, wrZ=wrZ, interior=interior, radius=radius, creator=creator}
    else 
        return false
    end
    if worldLODModelId and worldLODModelId ~= 0 then
        if removeWorldModel(worldLODModelId, radius, wX, wY, wZ, interior) then
            local index = #self.m_MapRemovals[mapId]+1
            local result, numrows, insertId = sql:queryFetch("INSERT INTO ??_map_editor_objects (Type, Model, PosX, PosY, PosZ, RotX, RotY, RotZ, Interior, MapId, Radius, Creator) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                sql:getPrefix(), 0, worldLODModelId, wX, wY, wZ, wrX, wrY, wrZ, interior, mapId, radius, creator)

            self.m_MapRemovals[mapId][index] = {insertId=insertId, worldModelId=worldModelId, wX=wX, wY=wY, wZ=wZ, wrX=wrX, wrY=wrY, wrZ=wrZ, interior=interior, radius=radius, creator=creator}
            return 2
        end
    end
    return 1
end

function MapLoader:restoreWorldModel(mapId, index)
    local insertId = self.m_MapRemovals[mapId][index].insertId
    local worldModelId = self.m_MapRemovals[mapId][index].worldModelId
    local wX = self.m_MapRemovals[mapId][index].wX
    local wY = self.m_MapRemovals[mapId][index].wY
    local wZ = self.m_MapRemovals[mapId][index].wZ
    local interior = self.m_MapRemovals[mapId][index].interior

    if restoreWorldModel(worldModelId, 0.1, wX, wY, wZ, interior) then
        self.m_MapRemovals[mapId][index] = nil
        local result = sql:queryExec("DELETE FROM ??_map_editor_objects WHERE Id = ?", sql:getPrefix(), insertId)
        return true
    end
end

function MapLoader:loadTextures(object)
    for textureName, texturePath in pairs(object.m_TextureData) do
        local texture = ElementTexture:new(object, texturePath, textureName, true, false, nil, true, false)
        if texture then
            table.insert(object.m_Textures, texture)
        end
    end

    for index, texture in pairs(object.m_Textures) do
        local existingTextureName = texture.m_Texture
        local textureFound = false
        for textureName, texturePath in pairs(object.m_TextureData) do
            if existingTextureName == textureName then
                textureFound = true
            end
        end
        
        if textureFound == false then
            table.remove(object.m_Textures, index)
            delete(texture)
        end
    end
end

function MapLoader:createLowLOD(object)
    local model = object:getModel()
    local x, y, z = getElementPosition(object)
    local rx, ry, rz = getElementRotation(object)

    if object:getLowLOD() then
        object:getLowLOD():destroy()
    end

    if object.m_LodEnabled then
        local id = LOD_MAP[model] or model
        local lowLOD = createObject(id, x, y, z, rx, ry, rz, true)
        lowLOD:setInterior(object:getInterior())
        lowLOD:setDimension(object:getDimension())
        object:setLowLOD(lowLOD)
    end
end

function MapLoader:destroyMapObject(object)
    if not isElement(object) then return end
    local lowLOD = object:getLowLOD()
    if lowLOD then
        lowLOD:destroy()
    end
    object:destroy()
end

function MapLoader:addRef(object)
    self.m_Objects[#self.m_Objects+1] = object
end

function MapLoader:removeRef(object)
    for key, value in ipairs(self.m_Objects) do
        if object == value then
            table.remove(self.m_Objects, key)
        end
    end
end

function MapLoader:createNewMap(name, creator)
    if not name:match("^[a-zA-Z0-9_.%[%]]*$") then
        return "invalid name"
    end
    for i = 1, #self.m_MapInfos do
        if self.m_MapInfos[i][1] == name then
            return "already exists"
        end
    end

    local result, numrows, insertId = sql:queryFetch("INSERT INTO ??_map_editor_maps (Name, Creator, SaveObjects, Activated, Deactivatable) VALUES(?, ?, ?, ?, ?)", sql:getPrefix(), name, creator:getId(), 1, 1, 1)
    if result then
        self.m_MapInfos[insertId] = {name, creator:getName(), 1, 1, 1, 0}
        self.m_Maps[insertId] = {}
        self.m_MapRemovals[insertId] = {}
        return true
    end
end

function MapLoader:createNewCategory(name)
    if not name:match("^[a-zA-Z0-9_.%[%]]*$") then
        return "invalid name"
    end
    if table.find(self.m_Categories, name) then
        return "already exists"
    end

    local result = sql:queryExec("INSERT INTO ??_map_editor_categories (Name) VALUES(?)", sql:getPrefix(), name)
    if result then
        table.insert(self.m_Categories, name)
        return true
    end
end

function MapLoader:deactivateMap(id)
    if self.m_MapInfos[id] then
        if self.m_MapInfos[id][5] ~= 1 then
            return false
        end
        local result = sql:queryExec("UPDATE ??_map_editor_maps SET Activated = 0 WHERE Id = ?", sql:getPrefix(), id)
        self.m_MapInfos[id][3] = 0
        if self.m_Maps[id] then
            for key, object in ipairs(self.m_Maps[id]) do
                object:destroy()

                self:removeRef(object)

            end
        end
        self.m_Maps[id] = nil
        if self.m_MapRemovals[id] then
            for index, tbl in pairs(self.m_MapRemovals[id]) do
                local worldModelId = self.m_MapRemovals[id][index].worldModelId
                local wX = self.m_MapRemovals[id][index].wX
                local wY = self.m_MapRemovals[id][index].wY
                local wZ = self.m_MapRemovals[id][index].wZ
                local interior = self.m_MapRemovals[id][index].interior
                restoreWorldModel(worldModelId, 0.1, wX, wY, wZ, interior)
            end
        end

        return true
    end
end

function MapLoader:setMapName(id, name)
    if not name:match("^[a-zA-Z0-9_.%[%]]*$") then
        return "invalid name"
    end
    for i = 1, #self.m_MapInfos do
        if self.m_MapInfos[i][1] == name then
            return "already exists"
        end
    end
    
    local result = sql:queryExec("UPDATE ??_map_editor_maps SET Name = ? WHERE Id = ?", sql:getPrefix(), name, id)
    if result then
        self.m_MapInfos[id][1] = name
        return true
    end
end

function MapLoader:setMapObjectSavingEnabled(id, state)
    local result = sql:queryExec("UPDATE ??_map_editor_maps SET SaveObjects = ? WHERE Id = ?", sql:getPrefix(), fromboolean(state), id)
    if result then
        self.m_MapInfos[id][4] = fromboolean(state)
        return true
    end
end

function MapLoader:setMapDeactivatable(id, state)
    local result = sql:queryExec("UPDATE ??_map_editor_maps SET Deactivatable = ? WHERE Id = ?", sql:getPrefix(), fromboolean(state), id)
    if result then
        self.m_MapInfos[id][5] = fromboolean(state)
        return true
    end
end

function MapLoader:setMapCategory(id, categoryId)
    local result = sql:queryExec("UPDATE ??_map_editor_maps SET Category = ? WHERE Id = ?", sql:getPrefix(), categoryId, id)
    if result then
        self.m_MapInfos[id][6] = categoryId
        return true
    end
end

function MapLoader:getMapInfos()
    return self.m_MapInfos
end

function MapLoader:getMaps()
    return self.m_Maps
end

function MapLoader:getMapStatus(id)
    return self.m_Maps[id] and true or false
end

function MapLoader:isMapSavingEnabled(id)
    return self.m_MapInfos[id] and toboolean(self.m_MapInfos[id][4])
end

function MapLoader:getMapRemovals()
    return self.m_MapRemovals
end

function MapLoader:getMapCategories()
    return self.m_Categories
end

function MapLoader:isGangwarMap(id)
    return self.m_MapInfos[id] and self.m_MapInfos[id][7] ~= nil
end

function MapLoader:getGangwarMapId(areaId)
    return self.m_GangwarMaps[areaId]
end

function MapLoader:createGangwarMap(areaId, creator)
    if self.m_GangwarMaps[areaId] then
        return self.m_GangwarMaps[areaId]
    end
    local name = ("Gangwar_%d"):format(areaId)
    local result, numrows, insertId = sql:queryFetch("INSERT INTO ??_map_editor_maps (Name, Creator, SaveObjects, Activated, Deactivatable, GangwarAreaId) VALUES(?, ?, ?, ?, ?, ?)", sql:getPrefix(), name, creator:getId(), 1, 0, 1, areaId)
    if result and insertId then
        self.m_MapInfos[insertId] = {name, creator:getName(), 0, 1, 1, 0, areaId}
        self.m_GangwarMaps[areaId] = insertId
        return insertId
    end
end

function MapLoader:unloadMap(id)
    if self.m_Maps[id] then
        for key, object in ipairs(self.m_Maps[id]) do
            self:removeRef(object)
            self:destroyMapObject(object)
        end
    end
    self.m_Maps[id] = nil
    self.m_MapRemovals[id] = nil
    if self.m_MapInfos[id] then
        self.m_MapInfos[id][3] = 0
    end
end

function MapLoader:createGangwarInstance(areaId, dimension)
    local objects = {}
    local mapId = self.m_GangwarMaps[areaId]
    if not mapId then
        return objects
    end
    local rows = sql:queryFetch("SELECT * FROM ??_map_editor_objects WHERE MapId = ? AND Type = 1", sql:getPrefix(), mapId) or {}
    for key, oRow in ipairs(rows) do
        objects[#objects+1] = self:createObjectFromRow(oRow, dimension)
    end
    if #objects > 0 then
        triggerClientEvent(PlayerManager:getSingleton():getReadyPlayers(), "applyBreakableState", resourceRoot)
    end
    return objects
end

function MapLoader:destroyGangwarInstance(objects)
    for key, object in ipairs(objects or {}) do
        self:destroyMapObject(object)
    end
end

function MapLoader:getGangwarObjectCounts()
    local counts = {}
    local rows = sql:queryFetch("SELECT o.MapId, COUNT(*) AS Amount FROM ??_map_editor_objects o INNER JOIN ??_map_editor_maps m ON m.Id = o.MapId WHERE o.Type = 1 AND m.GangwarAreaId IS NOT NULL GROUP BY o.MapId", sql:getPrefix(), sql:getPrefix()) or {}
    for key, row in ipairs(rows) do
        counts[row.MapId] = tonumber(row.Amount)
    end
    return counts
end