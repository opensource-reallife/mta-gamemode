-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Gangwar/GangwarMapEditor.lua
-- *  PURPOSE:     Gangwar map editor
-- *
-- ****************************************************************************

GangwarMapEditor = inherit(Singleton)
addRemoteEvents{"GangwarMapEditor:requestData", "GangwarMapEditor:editArea"}

function GangwarMapEditor:constructor()
	self.m_Previews = {}
	addCommandHandler("gwmapeditor", bind(self.Command_open, self))
	addEventHandler("GangwarMapEditor:requestData", root, bind(self.Event_requestData, self))
	addEventHandler("GangwarMapEditor:editArea", root, bind(self.Event_editArea, self))
	Player.getQuitHook():register(bind(self.onPlayerQuit, self))
end

function GangwarMapEditor:isAllowed(player)
	return player and player:getRank() >= ADMIN_RANK_PERMISSION["openMapEditor"]
end

function GangwarMapEditor:Command_open(player)
	if not self:isAllowed(player) then
		player:sendError(_("Du bist nicht berechtigt!", player))
		return
	end
	self:sendData(player, true)
end

function GangwarMapEditor:Event_requestData()
	if self:isAllowed(client) then
		self:sendData(client, true)
	end
end

function GangwarMapEditor:sendData(player, open)
	local loader = MapLoader:getSingleton()
	local counts = loader:getGangwarObjectCounts()
	local editors = {}
	for key, editor in ipairs(getElementsByType("player")) do
		if editor.m_GangwarMapArea then
			editors[editor.m_GangwarMapArea] = editors[editor.m_GangwarMapArea] and editors[editor.m_GangwarMapArea]..", "..editor:getName() or editor:getName()
		end
	end

	local areas = {}
	for id, area in pairs(Gangwar:getSingleton().m_Areas) do
		local mapId = loader:getGangwarMapId(id)
		areas[#areas + 1] = {id = id, name = area.m_Name, hasMap = mapId ~= nil, objects = mapId and counts[mapId] or 0, editors = editors[id] or "-", attacked = area.m_IsAttacked}
	end
	table.sort(areas, function(a, b) return a.name < b.name end)
	local currentMapId = player.m_GangwarMapArea and loader:getGangwarMapId(player.m_GangwarMapArea)
	player:triggerEvent("GangwarMapEditor:receiveData", areas, player.m_GangwarMapArea, open, currentMapId)
end

function GangwarMapEditor:Event_editArea(areaId)
	if not self:isAllowed(client) then return end
	areaId = tonumber(areaId)
	local area = areaId and Gangwar:getSingleton().m_Areas[areaId]
	if not area then return end

	if client.m_IsInEditorMode and not client.m_GangwarMapArea then
		client:sendError(_("Schließe zuerst den normalen Map Editor!", client))
		return
	end
	if client.m_GangwarSession or client.m_GangwarReturn then
		client:sendError(_("Du bist gerade in einem Gangwar!", client))
		return
	end

	local loader = MapLoader:getSingleton()
	local mapId = loader:createGangwarMap(areaId, client)
	if not mapId then
		client:sendError(_("Die Map konnte nicht angelegt werden!", client))
		return
	end

	local previousArea = client.m_GangwarMapArea
	if not previousArea then
		local rx, ry, rz = getElementRotation(client)
		client.m_GangwarMapReturn = {position = client:getPosition(), rotation = rz, interior = client:getInterior(), dimension = client:getDimension()}
	end
	client.m_GangwarMapArea = areaId
	if previousArea and previousArea ~= areaId then
		self:releaseMap(previousArea)
	end

	loader:loadFromDatabase(mapId, GANGWAR_DIMENSION_BASE)
	self:createPreview(areaId)

	if client.vehicle then
		client:removeFromVehicle()
	end
	local x, y, z = unpack(area:getPosition())
	client:setInterior(0)
	client:setDimension(GANGWAR_DIMENSION_BASE)
	client:setPosition(x, y, z + 1)
	self:sendWorld(client, areaId)

	MapEditor:getSingleton():setPlayerInEditorMode(client, mapId)
	Admin:getSingleton():sendShortMessage("%s bearbeitet die Gangwar-Map von %s!", {client:getName(), area.m_Name})
	StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Map", "Gebiet: "..area.m_Name)
	self:sendData(client, false)
end

function GangwarMapEditor:sendWorld(player, areaId)
	local removals = MapLoader:getSingleton():getGangwarRemovals(areaId)
	if not player.m_GangwarWorldSent then
		player.m_GangwarWorldSent = true
		player:triggerEvent("Gangwar:enterWorld", Gangwar:getSingleton():getWorldRemovals(), removals)
	else
		player:triggerEvent("Gangwar:enterWorld", false, removals)
	end
end

function GangwarMapEditor:syncRemovals(mapId)
	local loader = MapLoader:getSingleton()
	local areaId = loader:getGangwarAreaId(mapId)
	if not areaId then return end
	local removals = loader:getGangwarRemovals(areaId)
	for key, player in ipairs(getElementsByType("player")) do
		if player.m_GangwarMapArea == areaId then
			player:triggerEvent("Gangwar:setAreaRemovals", removals)
		end
	end
	local area = Gangwar:getSingleton().m_Areas[areaId]
	if area and area.m_AttackSession then
		area.m_AttackSession:broadcast("Gangwar:setAreaRemovals", removals)
	end
end

function GangwarMapEditor:onEditorClosed(player, quitting)
	local areaId = player.m_GangwarMapArea
	if not areaId then return end
	player.m_GangwarMapArea = nil
	if not quitting then
		player:triggerEvent("Gangwar:leaveWorld")
	end

	local target = player.m_GangwarMapReturn
	player.m_GangwarMapReturn = nil
	if target then
		if player.vehicle then
			player:removeFromVehicle()
		end
		player:setInterior(target.interior)
		player:setDimension(target.dimension)
		player:setPosition(target.position)
		player:setRotation(0, 0, target.rotation)
	end
	self:releaseMap(areaId)
end

function GangwarMapEditor:releaseMap(areaId)
	for key, player in ipairs(getElementsByType("player")) do
		if player.m_GangwarMapArea == areaId then
			return
		end
	end
	local mapId = MapLoader:getSingleton():getGangwarMapId(areaId)
	if mapId then
		MapLoader:getSingleton():unloadMap(mapId)
	end
	self:destroyPreview(areaId)
end

function GangwarMapEditor:createPreview(areaId)
	if self.m_Previews[areaId] then return end
	local area = Gangwar:getSingleton().m_Areas[areaId]
	if not area then return end

	local elements = {}
	local x, y, z = unpack(area:getPosition())
	local flag = createPickup(x, y, z, 3, GANGWAR_ATTACK_PICKUPMODEL, 5)
	setElementDimension(flag, GANGWAR_DIMENSION_BASE)
	elements[#elements + 1] = flag

	for key, spawn in ipairs(area:getBarricadeSpawns()) do
		local vehicle = TemporaryVehicle.create(spawn.model, spawn.x, spawn.y, spawn.z, spawn.rotation)
		if vehicle then
			vehicle:setDimension(GANGWAR_DIMENSION_BASE)
			vehicle:setInterior(0)
			vehicle:disableRespawn(true)
			vehicle:toggleRespawn(false)
			vehicle:setFrozen(true)
			vehicle:setLocked(true)
			vehicle:setAlpha(200)
			setVehicleDamageProof(vehicle, true)
			addEventHandler("onVehicleStartEnter", vehicle, cancelEvent)
			elements[#elements + 1] = vehicle
		end
	end
	self.m_Previews[areaId] = elements
end

function GangwarMapEditor:destroyPreview(areaId)
	for key, element in ipairs(self.m_Previews[areaId] or {}) do
		if isElement(element) then
			destroyElement(element)
		end
	end
	self.m_Previews[areaId] = nil
end

function GangwarMapEditor:refreshPreview(areaId)
	if self.m_Previews[areaId] then
		self:destroyPreview(areaId)
		self:createPreview(areaId)
	end
end

function GangwarMapEditor:onPlayerQuit(player)
	if player.m_GangwarMapArea then
		player.m_IsInEditorMode = nil
		player.m_EditingMapId = nil
		self:onEditorClosed(player, true)
	end
end
