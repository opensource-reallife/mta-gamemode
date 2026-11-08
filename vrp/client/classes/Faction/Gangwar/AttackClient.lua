-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/AttackClient.lua
-- *  PURPOSE:     AttackSession Client
-- *
-- ****************************************************************************
AttackClient = inherit(Object)
addRemoteEvents{"onGangwarDamage", "onGangwarKill", "AttackClient:synchronizeLists", "AttackClient:synchronizeTime", "AttackClient:launchClient", "AttackClient:stopClient", "Gangwar:createTeamBlips"}
AttackClient.Blips = {}

local ZONE_MAP_BORDER = 10
local ZONE_WALL_RANGE = 250
local ZONE_WALL_HEIGHT = 80
local CIRCLE_SEGMENTS = 48
local CIRCLE_HEIGHT = 4
local CIRCLE_RANGE = 300

local pseudoSingleton, lingeringDisplay, clearTimer

local function removeLingeringDisplay()
	if isTimer(clearTimer) then
		killTimer(clearTimer)
	end
	if lingeringDisplay then
		delete(lingeringDisplay)
		lingeringDisplay = nil
	end
end

function AttackClient:constructor(data)
	self.m_Faction = data.faction1
	self.m_Faction2 = data.faction2
	self.m_Participants = data.participants
	self.m_Phase = data.phase
	self.m_Slot = data.slot
	self.m_Dimension = data.dimension
	self.m_AreaName = data.area
	self.m_Picks1 = data.picks1
	self.m_Picks2 = data.picks2
	self.m_GangwarDamage = 0
	self.m_GangwarKill = 0
	localPlayer.attackSession = self
	HUDRadar:getSingleton():setGangwarDimension(data.dimension)
	removeLingeringDisplay()
	self.m_Display = GangwarDisplay:new(data.faction1, data.faction2, self, data.phase, data.time, data.flag)
	self:startDefenderZone(data)
end

function AttackClient:destructor()
	self:destroyTeamBlips()
	self:stopDefenderZone()
	localPlayer.attackSession = nil
	HUDRadar:getSingleton():setGangwarDimension(0)
	if self.m_Display then
		lingeringDisplay = self.m_Display
		if self.m_Phase == "end" then
			removeLingeringDisplay()
		else
			clearTimer = setTimer(removeLingeringDisplay, 5000, 1)
		end
	end
end

function AttackClient:startDefenderZone(data)
	if (data.phase ~= "prepare" and data.phase ~= "battle") or localPlayer:getFactionId() ~= data.faction2.m_Id then return end

	self.m_DefenderZone = data.phase == "prepare" and data.defenderZone or nil
	self.m_VehicleCircle = data.vehicleCircle
	self.m_CircleColor = tocolor(data.faction2.m_Color.r, data.faction2.m_Color.g, data.faction2.m_Color.b, 110)
	self.m_ZoneColor = tocolor(230, 30, 30, 90)
	self.m_ZoneTexture = dxCreateTexture("files/images/Textures/Ware/white.png")
	self.m_ZoneAreas = {}

	if self.m_DefenderZone then
		local x1, y1, x2, y2 = unpack(self.m_DefenderZone)
		local width, height = x2 - x1, y2 - y1
		local sides = {
			{x1, y2, width, ZONE_MAP_BORDER},
			{x1, y1 + ZONE_MAP_BORDER, width, ZONE_MAP_BORDER},
			{x1, y2, ZONE_MAP_BORDER, height},
			{x2 - ZONE_MAP_BORDER, y2, ZONE_MAP_BORDER, height},
		}
		for key, side in ipairs(sides) do
			self.m_ZoneAreas[key] = HUDRadar:getSingleton():addArea(side[1], side[2], side[3], side[4], {230, 30, 30, 220}, "gangwar")
		end
	end

	self.m_ZoneRender = bind(self.renderDefenderZone, self)
	addEventHandler("onClientRender", root, self.m_ZoneRender)
end

function AttackClient:stopZoneWalls()
	self.m_DefenderZone = nil
	if self.m_ZoneAreas then
		for key, area in ipairs(self.m_ZoneAreas) do
			HUDRadar:getSingleton():removeArea(area)
		end
		self.m_ZoneAreas = nil
	end
end

function AttackClient:stopDefenderZone()
	if self.m_ZoneRender then
		removeEventHandler("onClientRender", root, self.m_ZoneRender)
		self.m_ZoneRender = nil
	end
	self:stopZoneWalls()
	if isElement(self.m_ZoneTexture) then
		destroyElement(self.m_ZoneTexture)
	end
	self.m_ZoneTexture = nil
end

function AttackClient:renderDefenderZone()
	if localPlayer:getDimension() ~= self.m_Dimension or not self.m_ZoneTexture then return end

	local px, py, pz = getElementPosition(localPlayer)
	if self.m_DefenderZone then
		local x1, y1, x2, y2 = unpack(self.m_DefenderZone)
		self:drawZoneWall(x1, y1, x2, y1, px, py, pz)
		self:drawZoneWall(x2, y1, x2, y2, px, py, pz)
		self:drawZoneWall(x2, y2, x1, y2, px, py, pz)
		self:drawZoneWall(x1, y2, x1, y1, px, py, pz)
	end
	self:drawVehicleCircle(px, py)
end

function AttackClient:drawZoneWall(ax, ay, bx, by, px, py, pz)
	local length = getDistanceBetweenPoints2D(ax, ay, bx, by)
	local dirX, dirY = (bx - ax)/length, (by - ay)/length
	local along = (px - ax)*dirX + (py - ay)*dirY
	local side = (py - ay)*dirX - (px - ax)*dirY
	if math.abs(side) > ZONE_WALL_RANGE then return end

	local startAt, endAt = math.max(0, along - ZONE_WALL_RANGE), math.min(length, along + ZONE_WALL_RANGE)
	if startAt >= endAt then return end

	local sign = side >= 0 and 1 or -1
	local middle = (startAt + endAt)/2
	local faceX = ax + dirX*middle - dirY*sign*10
	local faceY = ay + dirY*middle + dirX*sign*10
	dxDrawMaterialLine3D(ax + dirX*startAt, ay + dirY*startAt, pz, ax + dirX*endAt, ay + dirY*endAt, pz, self.m_ZoneTexture, ZONE_WALL_HEIGHT, self.m_ZoneColor, faceX, faceY, pz)
end

function AttackClient:drawVehicleCircle(px, py)
	local circle = self.m_VehicleCircle
	if getDistanceBetweenPoints2D(circle.x, circle.y, px, py) > CIRCLE_RANGE then return end

	local z = circle.z - 1 + CIRCLE_HEIGHT/2
	local step = math.pi*2/CIRCLE_SEGMENTS
	for segment = 1, CIRCLE_SEGMENTS do
		local startAngle, endAngle = (segment - 1)*step, segment*step
		local middleAngle = (startAngle + endAngle)/2
		dxDrawMaterialLine3D(
			circle.x + math.cos(startAngle)*circle.radius, circle.y + math.sin(startAngle)*circle.radius, z,
			circle.x + math.cos(endAngle)*circle.radius, circle.y + math.sin(endAngle)*circle.radius, z,
			self.m_ZoneTexture, CIRCLE_HEIGHT, self.m_CircleColor,
			circle.x + math.cos(middleAngle)*(circle.radius + 10), circle.y + math.sin(middleAngle)*(circle.radius + 10), z
		)
	end
end

function AttackClient:getFactionParticipants(faction)
	local list = {}
	for key, player in ipairs(self.m_Participants) do
		if isElement(player) and player:getFactionId() == faction.m_Id then
			list[#list + 1] = player
		end
	end
	return list
end

function AttackClient:getPickCount(faction)
	return faction.m_Id == self.m_Faction.m_Id and self.m_Picks1 or self.m_Picks2
end

function AttackClient:createTeamBlips(playertable)
	self:destroyTeamBlips()
	for key, player in ipairs(playertable) do
		if player ~= localPlayer and isElement(player) then
			local blips = {}
			blips[1] = Blip:new("Marker.png", player:getPosition().x, player:getPosition().y, 9999, {235, 125, 15}, {235, 125, 15})
			blips[1]:attach(player)
			blips[1]:setDisplayText(player:getName(), "Anderes")
			blips[2] = createBlipAttachedTo(player, 0, 1, 50, 200, 50, 255, 0, 9999)
			blips[2]:setData("isGangwarBlip", true)
			setElementDimension(blips[2], self.m_Dimension)
			AttackClient.Blips[player:getName()] = blips
		end
	end
end

function AttackClient:destroyTeamBlips()
	for name, blips in pairs(AttackClient.Blips) do
		delete(blips[1])
		if isElement(blips[2]) then
			destroyElement(blips[2])
		end
	end
	AttackClient.Blips = {}
end

function AttackClient.isDamageBlocked(target, attacker, weapon)
	if not pseudoSingleton or not target.getPublicSync then return false end
	if target:getPublicSync("gangwarParticipant") ~= pseudoSingleton.m_Slot then return false end
	if pseudoSingleton.m_Phase ~= "battle" then return true end

	if isElement(attacker) then
		local attackingPlayer = attacker
		if getElementType(attacker) == "vehicle" then
			attackingPlayer = getVehicleController(attacker)
		end
		if attackingPlayer and getElementType(attackingPlayer) == "player" then
			if attackingPlayer:getPublicSync("gangwarParticipant") ~= pseudoSingleton.m_Slot then
				return true
			end
			if getElementType(attacker) == "player" and attacker.vehicle then
				return true
			end
		end
	end
	return false
end

function AttackClient.isActive()
	return pseudoSingleton ~= nil
end

addEventHandler("AttackClient:launchClient", localPlayer, function(data)
	if pseudoSingleton then
		delete(pseudoSingleton)
	end
	pseudoSingleton = AttackClient:new(data)
	if PolicePanel:isInstantiated() and PolicePanel:getSingleton():isVisible() then
		PolicePanel:getSingleton():toggle()
	end
end)

addEventHandler("AttackClient:stopClient", localPlayer, function()
	if pseudoSingleton then
		delete(pseudoSingleton)
		pseudoSingleton = nil
	end
end)

addEventHandler("AttackClient:synchronizeLists", localPlayer, function(participants, picks1, picks2)
	if pseudoSingleton then
		pseudoSingleton.m_Participants = participants
		pseudoSingleton.m_Picks1 = picks1
		pseudoSingleton.m_Picks2 = picks2
	end
end)

addEventHandler("AttackClient:synchronizeTime", localPlayer, function(phase, time)
	if pseudoSingleton then
		pseudoSingleton.m_Phase = phase
		if phase == "battle" then
			pseudoSingleton:stopZoneWalls()
		elseif phase ~= "prepare" then
			pseudoSingleton:stopDefenderZone()
		end
		if pseudoSingleton.m_Display then
			pseudoSingleton.m_Display:synchronize(phase, time)
		end
	end
end)

addEventHandler("onGangwarDamage", localPlayer, function(loss)
	if pseudoSingleton then
		pseudoSingleton.m_GangwarDamage = math.ceil(pseudoSingleton.m_GangwarDamage + loss)
	end
end)

addEventHandler("onGangwarKill", localPlayer, function()
	if pseudoSingleton then
		pseudoSingleton.m_GangwarKill = pseudoSingleton.m_GangwarKill + 1
	end
end)

addEventHandler("Gangwar:createTeamBlips", localPlayer, function(playertable)
	if pseudoSingleton then
		pseudoSingleton:createTeamBlips(playertable)
	end
end)
