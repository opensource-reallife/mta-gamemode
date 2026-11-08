-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/Area.lua
-- *  PURPOSE:     Gangwar Area Class
-- *
-- ****************************************************************************

Area = inherit(Object)

function Area:constructor(dataset, pGManager)
	self.m_Name = dataset["Name"]
	self.m_ID = dataset["ID"]
	self.m_Owner = tonumber(dataset["Besitzer"])
	self.m_LastAttack = dataset["lastAttack"]
	self.m_Position = {tonumber(dataset["x"]), tonumber(dataset["y"]), tonumber(dataset["z"])}
	self.m_PositionRadar = {tonumber(dataset["cX"]), tonumber(dataset["cY"]), tonumber(dataset["cX2"]), tonumber(dataset["cY2"])}
	self.m_CarCount = tonumber(dataset["Autos"]) or 4
	self.m_Active = dataset["active"] ~= 0
	self.m_GangwarManager = pGManager
	self.m_BannedVehicles = {}
	local banned = dataset["BannedVehicles"] and fromJSON(dataset["BannedVehicles"])
	if type(banned) == "table" then
		for index, model in pairs(banned) do
			self.m_BannedVehicles[tonumber(model)] = true
		end
	end
	self:refreshRadar()
end

function Area:destructor()
	if self.m_RadarArea then delete(self.m_RadarArea) end
	if self.m_BlipImage then self.m_BlipImage:delete() end
end

function Area:getName()
	return self.m_Name
end

function Area:getPosition()
	return self.m_Position
end

function Area:getBarricadeSpawns()
	local x, y, z = unpack(self.m_Position)
	local spawns = {}
	for index = 1, self.m_CarCount do
		local newX, newY = getPointFromDistanceRotation(x, y, 6, 360*(index/5))
		spawns[index] = {model = 482, x = newX, y = newY, z = z, rotation = index*(360/self.m_CarCount)}
	end
	return spawns
end

function Area:getLastAttack()
	return self.m_LastAttack
end

function Area:getOwnerId()
	return self.m_Owner
end

function Area:getId()
	return self.m_ID
end

function Area:refreshRadar()
	if self.m_RadarArea then
		self.m_RadarArea:delete()
		self.m_RadarArea = nil
	end
	if not self.m_Active then return end

	local areaX, areaY = self.m_PositionRadar[1], self.m_PositionRadar[2]
	local areaX2, areaY2 = self.m_PositionRadar[3], self.m_PositionRadar[4]
	local areaWidth = math.abs(areaX - areaX2)
	local areaHeight = math.abs(areaY - areaY2)
	local factionColor = factionColors[self.m_Owner]
	if factionColor then
		factionColor = setBytesInInt32(150, factionColor.r, factionColor.g, factionColor.b)
	else
		factionColor = GANGWAR_DUMP_COLOR
	end
	if self.m_IsAttacked then
		factionColor = setBytesInInt32(150, 220, 0, 0)
	end
	self.m_RadarArea = RadarArea:new(areaX, areaY, areaWidth, -1*areaHeight, factionColor, "gangwar")
end

function Area:setCorner(corner, x, y)
	if corner == 1 then
		self.m_PositionRadar[1], self.m_PositionRadar[2] = x, y
	else
		self.m_PositionRadar[3], self.m_PositionRadar[4] = x, y
	end
	local x1, y1, x2, y2 = unpack(self.m_PositionRadar)
	self.m_PositionRadar = {math.min(x1, x2), math.min(y1, y2), math.max(x1, x2), math.max(y1, y2)}
end

function Area:attack(faction1, faction2, attackingPlayer, picks, slot, isGiven)
	if self.m_IsAttacked then return false end

	self.m_IsAttacked = true
	self.m_PreviousLastAttack = self.m_LastAttack
	self.m_PreviousOwner = self.m_Owner
	self.m_LastAttack = getRealTime().timestamp
	faction1:sendMessage("[Gangwar] #FFFFFFIhre Fraktion hat einen Attack gestartet! ( Gebiet: "..self.m_Name.." )", 0, 204, 204, true)
	faction2:sendMessage("[Gangwar] #FFFFFFIhre Fraktion wurde attackiert von "..faction1.m_Name_Short.." ! ( Gebiet: "..self.m_Name.." )", 204, 20, 0, true)
	if not faction1.m_DiscordRole or not faction2.m_DiscordRole then
		Discord:getSingleton():outputGangwarNews("Das Gebiet "..self.m_Name.." der Fraktion "..faction2.m_Name_Short.." wird von der Fraktion "..faction1.m_Name_Short.." angegriffen!")
	else
		Discord:getSingleton():outputGangwarNews("Das Gebiet "..self.m_Name.." der Fraktion <@&"..faction2.m_DiscordRole.."> wird von der Fraktion <@&"..faction1.m_DiscordRole.."> angegriffen!")
	end

	self.m_AttackSession = AttackSession:new(self, faction1, faction2, attackingPlayer, picks, slot, isGiven)
	self.m_BlipImage = Blip:new("Gangwar.png", self.m_Position[1], self.m_Position[2], {faction = {faction1:getId(), faction2:getId()}}, 9999)
	self:refreshRadar()
	if self.m_RadarArea then
		self.m_RadarArea:setFlashing(true, {faction1.m_Color, faction2.m_Color})
	end
	if attackingPlayer then
		faction1:addLog(attackingPlayer, "Gangwar", ("hat das Gebiet %s attackiert!"):format(self.m_Name))
	end
	return self.m_AttackSession
end

function Area:attackEnd()
	if not self.m_IsAttacked then return end
	if self.m_RadarArea then
		self.m_RadarArea:setFlashing(false)
	end
	local session = self.m_AttackSession
	self.m_AttackSession = nil
	self.m_IsAttacked = false
	if self.m_BlipImage then
		self.m_BlipImage:delete()
		self.m_BlipImage = nil
	end
	self:refreshRadar()
	if session then
		delete(session)
	end
end

function Area:update()
	sql:queryExec("UPDATE ??_gangwar SET Besitzer = ?, lastAttack = ? WHERE ID = ?", sql:getPrefix(), self.m_Owner, self.m_LastAttack, self.m_ID)
end

function Area:getBannedVehicleList()
	local list = {}
	for model in pairs(self.m_BannedVehicles) do
		list[#list + 1] = model
	end
	return list
end

function Area:saveConfig()
	local x1, y1, x2, y2 = unpack(self.m_PositionRadar)
	sql:queryExec("UPDATE ??_gangwar SET Name = ?, x = ?, y = ?, z = ?, cX = ?, cY = ?, cX2 = ?, cY2 = ?, Autos = ?, active = ?, BannedVehicles = ? WHERE ID = ?",
		sql:getPrefix(), self.m_Name, self.m_Position[1], self.m_Position[2], self.m_Position[3], x1, y1, x2, y2, self.m_CarCount, self.m_Active and 1 or 0, toJSON(self:getBannedVehicleList()), self.m_ID)
end

function Area:isUnderAttack()
	return self.m_IsAttacked
end

function Area:getMatchFactions()
	if self.m_IsAttacked and self.m_AttackSession then
		return self.m_AttackSession:getFactions()
	end
end
