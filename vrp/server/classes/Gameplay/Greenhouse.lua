-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Greenhouse.lua
-- *  PURPOSE:     Greenhouse class
-- *
-- ****************************************************************************

Greenhouse = inherit(Object)

function Greenhouse:constructor(player)
    self.m_Player = player
    self.m_Dimension = DimensionManager:getSingleton():getFreeDimension()
    self.m_MapParser = MapParser:new(":exo_maps/greenhouse.map")
    self.m_MapParser:create(self.m_Dimension)

    for k, plant in pairs(self:getPlants()) do
        plant:setDimension(self.m_Dimension)
	end

    player:setDimension(self.m_Dimension)
    player:setPosition(-1008.7, -932.08, 129.27)
    player:setRotation(0, 0, 90, "default", true)
    player:setCameraTarget(player)
    player:triggerEvent("HUDRadar:hideRadar")

    self.m_ExitMarker = createMarker(-1007.7, -932.08, 129.27-1, "cylinder", 1.2, 255, 255, 255, 125)
    self.m_ExitMarker:setDimension(self.m_Dimension)
	addEventHandler("onMarkerHit", self.m_ExitMarker, function(hitElement, dim)
		if hitElement:getType() == "player" and dim then
            QuestionBox:new(hitElement, _("Willst du dein Gewächshaus verlassen?", hitElement), "greenhouseExit", nil, false, false)
        end
	end)
end

function Greenhouse:getPlants()
    local tbl = {}
    for k, plant in pairs(GrowableManager:getSingleton().Map) do
        if plant.m_InGreenhouse and plant.m_OwnerId == self.m_Player:getId() then
            table.insert(tbl, plant)
        end
	end
    return tbl
end

function Greenhouse:destructor()
    local player = self.m_Player
    if player:getDimension() == self.m_Dimension then
        player:setDimension(0)
        player:setPosition(2426.84, 119.69, 26.47)
        player:setRotation(0, 0, 0, "default", true)
        player:setCameraTarget(player)
        player:triggerEvent("HUDRadar:showRadar")
    end

    for k, plant in pairs(self:getPlants()) do
        plant:setDimension(PRIVATE_DIMENSION_SERVER)
	end
    
	self.m_ExitMarker:destroy()
    DimensionManager:getSingleton():freeDimension(self.m_Dimension)
    delete(self.m_MapParser)
end