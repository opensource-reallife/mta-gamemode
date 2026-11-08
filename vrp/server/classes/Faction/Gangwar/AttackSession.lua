-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/GangwarAttack.lua
-- *  PURPOSE:     Gangwar Attack class
-- *
-- ****************************************************************************
AttackSession = inherit(Object)
GANGWAR_TEAMBLIPS = true

local WEAPON_LEVEL_STATS = {69, 70, 71, 72, 74, 76, 77, 78}
local KEEP_STATS = {160, 229, 230}

function AttackSession:constructor(pAreaObj, faction1, faction2, attackingPlayer, picks, slot, isGiven)
	self.m_AreaObj = pAreaObj
	self.m_Faction1 = faction1
	self.m_Faction2 = faction2
	self.m_AttackingPlayer = attackingPlayer
	self.m_AttackingPlayerId = attackingPlayer and attackingPlayer:getId() or nil
	self.m_Slot = slot
	self.m_Dimension = GANGWAR_DIMENSION_BASE + slot
	self.m_IsGiven = isGiven
	self.m_Manager = Gangwar:getSingleton()
	self.m_StartTime = pAreaObj.m_LastAttack
	self.m_Phase = "prepare"
	self.m_Participants = {}
	self.m_Eliminated = {}
	self.m_Stats = {}
	self.m_Picks = {[faction1:getId()] = picks, [faction2:getId()] = {}}
	self.m_PickSubmitted = {[faction1:getId()] = true}
	self.m_Vehicles = {}
	self.m_VehicleCounts = {[faction1:getId()] = {}, [faction2:getId()] = {}}
	self.m_LateRequests = {}
	self.m_LateCooldown = {}

	self.m_MapObjects = MapLoader:getSingleton():createGangwarInstance(pAreaObj.m_ID, self.m_Dimension)
	self:createFlag()
	self:createVehicleZones()
	self:createBarricadeVehicles()

	self.m_PhaseTimer = setTimer(bind(self.onPrepareEnd, self), self.m_Manager:getSetting("PrepareTime")*1000, 1)
	self.m_SyncTimer = setTimer(bind(self.synchronizeTime, self), 5000, 0)
	self.m_WeaponTimer = setTimer(bind(self.checkWeapons, self), 3000, 0)
	self:createDefenderZone()
	self.m_DefenderZoneTimer = setTimer(bind(self.checkDefenderZone, self), 1000, 0)

	self:notifyStart()
end

function AttackSession:destructor()
end

function AttackSession:getFactions()
	return self.m_Faction1, self.m_Faction2
end

function AttackSession:getOpponent(faction)
	return faction == self.m_Faction1 and self.m_Faction2 or self.m_Faction1
end

function AttackSession:getSidePosition(faction)
	if faction == self.m_Faction1 then
		return self.m_AreaObj:getPosition()
	end
	return self.m_Manager:getFactionSpawn(faction, self.m_AreaObj)
end

function AttackSession:getTimeLeft()
	if self.m_PhaseTimer and isTimer(self.m_PhaseTimer) then
		return math.ceil(getTimerDetails(self.m_PhaseTimer)/1000)
	end
	return 0
end

function AttackSession:sendToBoth(text, r, g, b)
	self.m_Faction1:sendMessage(text, r, g, b, true)
	self.m_Faction2:sendMessage(text, r, g, b, true)
end

function AttackSession:createFlag()
	local x, y, z = unpack(self.m_AreaObj:getPosition())
	self.m_FlagPickup = createPickup(x, y, z, 3, GANGWAR_ATTACK_PICKUPMODEL, 5)
	setElementDimension(self.m_FlagPickup, self.m_Dimension)
	self.m_CenterSphere = createColSphere(x, y, z - 1, GANGWAR_CENTER_HOLD_RANGE + 1)
	setElementDimension(self.m_CenterSphere, self.m_Dimension)
	addEventHandler("onColShapeHit", self.m_CenterSphere, bind(self.onCenterEnter, self))
	addEventHandler("onColShapeLeave", self.m_CenterSphere, bind(self.onCenterLeave, self))
end

function AttackSession:createVehicleZones()
	self.m_VehicleZones = {}
	local radius = self.m_Manager:getSetting("VehicleRadius")
	for _, faction in ipairs({self.m_Faction2}) do
		local x, y = unpack(self:getSidePosition(faction))
		local zone = createColCircle(x, y, radius)
		setElementDimension(zone, self.m_Dimension)
		zone.m_GangwarFaction = faction
		addEventHandler("onColShapeHit", zone, bind(self.onVehicleZoneHit, self))
		addEventHandler("onColShapeLeave", zone, bind(self.onVehicleZoneLeave, self))
		self.m_VehicleZones[#self.m_VehicleZones + 1] = zone
	end
end

function AttackSession:createDefenderZone()
	local x1, y1, x2, y2 = unpack(self.m_AreaObj.m_PositionRadar)
	local distance = self.m_Manager:getSetting("DefenderDistance")
	local sx, sy = unpack(self:getSidePosition(self.m_Faction2))
	self.m_DefenderSafePositions = {}
	self.m_DefenderZone = {x1 - distance, y1 - distance, x2 + distance, y2 + distance}
	if self:isInDefenderZone(sx, sy) then
		self.m_DefenderZone = {x1, y1, x2, y2}
		if self:isInDefenderZone(sx, sy) then
			self.m_DefenderZone = nil
		end
	end
end

function AttackSession:isInDefenderZone(x, y)
	local zone = self.m_DefenderZone
	return zone and x >= zone[1] and x <= zone[3] and y >= zone[2] and y <= zone[4]
end

function AttackSession:checkDefenderZone()
	if not self.m_DefenderZone then return end
	for playerIndex, player in ipairs(self.m_Participants) do
		if player:getFaction() == self.m_Faction2 and not isPedDead(player) then
			local element = player.vehicle or player
			local x, y, z = getElementPosition(element)
			if self:isInDefenderZone(x, y) then
				local safe = self.m_DefenderSafePositions[player]
				if not safe then
					local sx, sy, sz = unpack(self:getSidePosition(self.m_Faction2))
					safe = {sx, sy, sz + 1}
				end
				setElementVelocity(element, 0, 0, 0)
				setElementPosition(element, safe[1], safe[2], safe[3])
				player:sendWarning(_("Du darfst dich dem Gebiet in der Aufbauphase nicht nähern!", player))
			else
				self.m_DefenderSafePositions[player] = {x, y, z}
			end
		end
	end
end

function AttackSession:destroyVehicleZones()
	for _, zone in ipairs(self.m_VehicleZones or {}) do
		if isElement(zone) then
			destroyElement(zone)
		end
	end
	self.m_VehicleZones = {}
end

function AttackSession:notifyStart()
	local minutes = math.ceil(self.m_Manager:getSetting("PrepareTime")/60)
	self:sendToBoth(("[Gangwar] #FFFFFFDie Aufbauzeit für %s läuft %d Minuten. Eingeteilte Spieler treten beim Gangwar-NPC bei."):format(self.m_AreaObj.m_Name, minutes), 0, 204, 204)
	self:syncPickStatus()
end

function AttackSession:getPickStatus(faction)
	local entries = {}
	for index, id in ipairs(self.m_Picks[faction:getId()]) do
		local player = Player.getFromId(id)
		entries[#entries + 1] = {name = Account.getNameFromId(id) or tostring(id), entered = player and player.m_GangwarSession == self or false}
	end
	return {area = self.m_AreaObj.m_Name, entries = entries}
end

function AttackSession:sendPickStatus(player)
	if self.m_Phase ~= "prepare" or self.m_Finished then return end
	player:triggerEvent("GangwarPick:status", self:getPickStatus(player:getFaction()), self:isPicked(player), self:isParticipantInList(player))
end

function AttackSession:syncPickStatus()
	if self.m_Phase ~= "prepare" or self.m_Finished then return end
	for factionIndex, faction in ipairs({self.m_Faction1, self.m_Faction2}) do
		local status = self:getPickStatus(faction)
		for playerIndex, player in ipairs(faction:getOnlinePlayers()) do
			player:triggerEvent("GangwarPick:status", status, self:isPicked(player), self:isParticipantInList(player))
		end
	end
end

function AttackSession:closePickStatus()
	for factionIndex, faction in ipairs({self.m_Faction1, self.m_Faction2}) do
		for playerIndex, player in ipairs(faction:getOnlinePlayers()) do
			player:triggerEvent("GangwarPick:statusClose")
		end
	end
end

function AttackSession:canModifyPick(player)
	local faction = player:getFaction()
	if faction ~= self.m_Faction1 and faction ~= self.m_Faction2 then return false end
	if player == self.m_AttackingPlayer then return true end
	return (faction:getPlayerRank(player) or 0) >= 3 or PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "startGangWar")
end

function AttackSession:isPicked(player)
	local list = self.m_Picks[player:getFaction() and player:getFaction():getId()]
	if not list then return false end
	for _, id in ipairs(list) do
		if id == player:getId() then
			return true
		end
	end
	return false
end

function AttackSession:removePick(faction, playerId)
	local list = self.m_Picks[faction:getId()]
	for index = #list, 1, -1 do
		if list[index] == playerId then
			table.remove(list, index)
		end
	end
end

function AttackSession:isParticipantInList(player)
	return player.m_GangwarSession == self
end

function AttackSession:getEnterBlockReason(player)
	if not player:isFactionDuty() then
		return _("Du musst im Fraktionsdienst sein!", player)
	end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "joinGangWar") then
		return _("Du darfst nicht am Gangwar teilnehmen!", player)
	end
	if player:hasTemporaryStorage() then return _("Beende zuerst deine aktuelle Aktivität!", player) end
	if player:isDead() or player:getExecutionPed() then return _("Du kannst gerade nicht beitreten!", player) end
	if (player.m_JailTime or 0) > 0 or (player.m_PrisonTime or 0) > 0 then return _("Du sitzt im Gefängnis!", player) end
	if player:isStateCuffed() then return _("Du bist gefesselt!", player) end
	if player.m_isAFK then return _("Du bist AFK!", player) end
	if player.m_SupMode then return _("Du bist im Support-Modus!", player) end
	if player.m_GangwarReturn then return _("Du kehrst gerade aus dem Gangwar zurück!", player) end
	if player.m_GangwarMapArea then return _("Du bist im Gangwar-Map-Editor!", player) end
	return false
end

function AttackSession:tryEnter(player)
	local id = player:getId()
	if self:isParticipantInList(player) then
		player:sendError(_("Du bist bereits im Gangwar!", player))
		return
	end
	if self.m_Eliminated[id] then
		player:sendError(_("Du bist aus diesem Gangwar ausgeschieden!", player))
		return
	end
	if self.m_Phase ~= "prepare" then
		player:sendError(_("Die Aufbauzeit ist vorbei. Du kannst nur noch einen Nachjoin anfragen!", player))
		return
	end

	local faction = player:getFaction()
	if not self:isPicked(player) then
		local list = self.m_Picks[faction:getId()]
		if self.m_PickSubmitted[faction:getId()] then
			player:sendError(_("Du bist nicht eingeteilt!", player))
			return
		end
		if #list >= self.m_Manager:getSetting("MaxPlayers") then
			player:sendError(_("Es sind bereits alle Plätze belegt!", player))
			return
		end
	end

	local reason = self:getEnterBlockReason(player)
	if reason then
		player:sendError(reason)
		return
	end
	if not self:isPicked(player) then
		local list = self.m_Picks[faction:getId()]
		list[#list + 1] = id
	end
	self:enterPlayer(player)
end

function AttackSession:enterStarter()
	local player = self.m_AttackingPlayer
	if not player or not isElement(player) or player:getFaction() ~= self.m_Faction1 then return end

	local reason = self:getEnterBlockReason(player)
	if reason then
		player:sendError(reason)
		return
	end
	self:enterPlayer(player)
end

function AttackSession:enforceFactionSkin(player)
	local faction = player:getFaction()
	if faction and not faction.m_Skins[player:getModel()] then
		faction:changeSkin(player)
	end
end

function AttackSession:isWithinFlagRange(player)
	local x, y = unpack(self.m_AreaObj:getPosition())
	local px, py = getElementPosition(player)
	return getDistanceBetweenPoints2D(x, y, px, py) <= self.m_Manager:getSetting("MaxFlagDistance")
end

function AttackSession:checkFlagRange(player)
	if self.m_Phase ~= "battle" then return end
	self.m_RangeWarnings = self.m_RangeWarnings or {}
	if self:isWithinFlagRange(player) then
		self.m_RangeWarnings[player] = nil
	elseif not self.m_RangeWarnings[player] then
		self.m_RangeWarnings[player] = true
		player:sendWarning(_("Du bist mehr als %d m vom TK entfernt und kannst weder Schaden machen noch erhalten!", player, self.m_Manager:getSetting("MaxFlagDistance")))
	end
end

function AttackSession:equipPlayer(player)
	player:createStorage(true)
	for _, stat in ipairs(KEEP_STATS) do
		setPedStat(player, stat, player.m_Storage.stats[stat] or 0)
	end
	for _, stat in ipairs(WEAPON_LEVEL_STATS) do
		setPedStat(player, stat, stat == 69 and 900 or 1000)
	end
	for index, weapon in ipairs(self.m_Manager:getLoadout()) do
		rawGiveWeapon(player, weapon[1], weapon[2], index == 1)
	end
end

function AttackSession:enterPlayer(player)
	local id = player:getId()
	if player.vehicle then
		removePedFromVehicle(player)
	end
	if player:getPrivateSync("isAttachedToVehicle") then
		player:attachToVehicle(true)
	end
	local rx, ry, rz = getElementRotation(player)
	player.m_GangwarReturn = {position = player:getPosition(), rotation = rz, interior = player:getInterior(), dimension = player:getDimension()}
	player.m_GangwarSession = self

	self:equipPlayer(player)
	local x, y, z = unpack(self:getSidePosition(player:getFaction()))
	player:setInterior(0)
	player:setDimension(self.m_Dimension)
	player:setPosition(x + math.random(-20, 20)/10, y + math.random(-20, 20)/10, z + 1)
	player:setHealth(100)
	player:setArmor(100)
	if player:getHunger() <= 20 then
		player:toggleControl("sprint", true)
	end
	player.m_GangwarHealthDamaged = nil
	self:enforceFactionSkin(player)

	if not self.m_Stats[id] then
		self.m_Stats[id] = {name = player:getName(), faction = player:getFaction(), damage = 0, kills = 0}
	end
	self.m_Participants[#self.m_Participants + 1] = player
	if self.m_Phase == "prepare" and player:getFaction() == self.m_Faction1 then
		player:sendShortMessage(_("Mit F4 kannst du in der Aufbauphase überall im Gebiet Fahrzeuge spawnen.", player), "Gangwar")
	elseif self.m_Phase == "prepare" then
		player:sendShortMessage(_("Spawne Fahrzeuge an deiner Base. Dem Gebiet darfst du dich erst in der Attackphase nähern.", player), "Gangwar")
	end
	player:setPublicSync("gangwarParticipant", self.m_Slot)
	player:setData("gangwarBlockDriveby", true, true)

	if not player.m_GangwarWorldSent then
		player.m_GangwarWorldSent = true
		player:triggerEvent("Gangwar:enterWorld", self.m_Manager:getWorldRemovals())
	else
		player:triggerEvent("Gangwar:enterWorld")
	end
	player:triggerEvent("AttackClient:launchClient", self:getClientData())
	self:synchronizeLists()
	self:createTeamBlips()
	self:syncPickStatus()
end

function AttackSession:getClientData()
	local f1, f2 = self.m_Faction1, self.m_Faction2
	local spawnX, spawnY, spawnZ = unpack(self:getSidePosition(f2))
	return {
		faction1 = {m_Id = f1:getId(), m_Name = f1.m_Name, m_Color = f1.m_Color},
		faction2 = {m_Id = f2:getId(), m_Name = f2.m_Name, m_Color = f2.m_Color},
		participants = self.m_Participants,
		phase = self.m_Phase,
		time = self:getTimeLeft(),
		flag = self.m_AreaObj:getPosition(),
		area = self.m_AreaObj.m_Name,
		slot = self.m_Slot,
		dimension = self.m_Dimension,
		defenderZone = self.m_DefenderZone,
		vehicleCircle = {x = spawnX, y = spawnY, z = spawnZ, radius = self.m_Manager:getSetting("VehicleRadius")},
		picks1 = #self.m_Picks[f1:getId()],
		picks2 = #self.m_Picks[f2:getId()],
	}
end

function AttackSession:broadcast(event, ...)
	for _, player in ipairs(self.m_Participants) do
		if isElement(player) then
			player:triggerEvent(event, ...)
		end
	end
end

function AttackSession:synchronizeLists()
	self:broadcast("AttackClient:synchronizeLists", self.m_Participants, #self.m_Picks[self.m_Faction1:getId()], #self.m_Picks[self.m_Faction2:getId()])
end

function AttackSession:synchronizeTime()
	self:broadcast("AttackClient:synchronizeTime", self.m_Phase, self:getTimeLeft())
end

function AttackSession:createTeamBlips()
	if GANGWAR_TEAMBLIPS == false then return end
	local teams = {[self.m_Faction1] = {}, [self.m_Faction2] = {}}
	for _, player in ipairs(self.m_Participants) do
		local team = teams[player:getFaction()]
		if team then
			team[#team + 1] = player
		end
	end
	for _, player in ipairs(self.m_Participants) do
		player:triggerEvent("Gangwar:createTeamBlips", teams[player:getFaction()] or {})
	end
end

function AttackSession:removeFromSession(player)
	for index = #self.m_Participants, 1, -1 do
		if self.m_Participants[index] == player then
			table.remove(self.m_Participants, index)
		end
	end
	player.m_GangwarSession = nil
	player:setPublicSync("gangwarParticipant", false)
	player:setData("gangwarBlockDriveby", false, true)
	player:triggerEvent("AttackClient:stopClient")
	self.m_Manager:onCandidateGone(player)
	if not self.m_Finished then
		self:synchronizeLists()
		self:createTeamBlips()
		self:checkCenter()
		self:syncPickStatus()
	end
end

function AttackSession:leaveByPlayer(player)
	if isPedDead(player) then return end
	if self.m_Phase == "battle" then
		self:sendToBoth(("[Gangwar] #FFFFFFDer Spieler %s hat den Gangwar verlassen!"):format(player:getName()), 100, 120, 100)
	end
	player:triggerEvent("GangwarVehicle:close")
	self:eliminate(player)
end

function AttackSession:restorePlayer(player)
	if player.vehicle then
		removePedFromVehicle(player)
	end
	self.m_Manager:finishLeave(player)
end

function AttackSession:eliminate(player)
	if self.m_Phase == "battle" then
		self.m_Eliminated[player:getId()] = true
	end
	self:removeFromSession(player)
	if not isPedDead(player) then
		self:restorePlayer(player)
	end
	self:scheduleSessionCheck()
end

function AttackSession:scheduleSessionCheck()
	if self.m_Phase ~= "battle" or self.m_Finished then return end
	nextframe(function()
		self:sessionCheck()
	end)
end

function AttackSession:sessionCheck()
	if self.m_Phase ~= "battle" or self.m_Finished then return false end
	local count1, count2 = 0, 0
	for _, player in ipairs(self.m_Participants) do
		if player:getFaction() == self.m_Faction1 then
			count1 = count1 + 1
		else
			count2 = count2 + 1
		end
	end
	if count1 == 0 then
		self:finish(self.m_Faction2, 1)
		return true
	elseif count2 == 0 then
		self:finish(self.m_Faction1, 2)
		return true
	end
	return false
end

function AttackSession:onPlayerWasted(player, killer)
	local faction = player:getFaction()
	if killer and isValidElement(killer, "player") and killer ~= player then
		killer:increaseStatistics("Kills", 1)
		if killer.m_GangwarSession == self and killer:getFaction() ~= faction then
			local stats = self.m_Stats[killer:getId()]
			if stats then
				stats.kills = stats.kills + 1
			end
			killer:triggerEvent("onGangwarKill")
		end
	end

	if self.m_Phase == "battle" then
		faction:sendMessage("[Gangwar] #FFFFFFEin Mitglied ("..player.name..") ist getötet worden!", 200, 0, 0, true)
		self:getOpponent(faction):sendMessage(("[Gangwar] #FFFFFFEin Gegner (%s) ist %s!"):format(player.name, killer and "getötet worden" or "gestorben"), 0, 200, 0, true)
	end
	self:eliminate(player)
end

function AttackSession:onPlayerQuit(player)
	self:eliminate(player)
end

function AttackSession:addDamage(attacker, damage)
	local stats = self.m_Stats[attacker:getId()]
	if stats then
		stats.damage = stats.damage + damage
		attacker:triggerEvent("onGangwarDamage", damage)
	end
end

function AttackSession:submitPick(player, ids)
	if not self:canModifyPick(player) then
		player:sendError(_("Du hast keine Berechtigung die Spieler einzuteilen!", player))
		return
	end
	if self.m_Phase ~= "prepare" then
		player:sendError(_("Die Aufbauzeit ist vorbei!", player))
		return
	end

	local faction = player:getFaction()
	local picks = self.m_Manager:sanitizePicks(faction, ids, faction == self.m_Faction1 and self.m_AttackingPlayerId or nil)
	self.m_Picks[faction:getId()] = picks
	self.m_PickSubmitted[faction:getId()] = true

	for index = #self.m_Participants, 1, -1 do
		local participant = self.m_Participants[index]
		if participant:getFaction() == faction and not self:isPicked(participant) then
			participant:sendInfo(_("Du wurdest aus der Einteilung entfernt!", participant))
			self:removeFromSession(participant)
			self:restorePlayer(participant)
		end
	end

	faction:sendMessage(("[Gangwar] #FFFFFF%s hat %d Spieler eingeteilt."):format(player:getName(), #picks), 0, 204, 204, true)
	self:syncPickStatus()
	self:synchronizeLists()
end

function AttackSession:sendPickData(player)
	if self.m_Phase ~= "prepare" then
		player:sendError(_("Die Aufbauzeit ist vorbei!", player))
		return
	end
	local faction = player:getFaction()
	player:triggerEvent("GangwarPick:open", {
		title = self.m_AreaObj.m_Name,
		members = self.m_Manager:getMemberList(faction),
		picks = self.m_Picks[faction:getId()],
		canModify = self:canModifyPick(player),
		maxPlayers = self.m_Manager:getSetting("MaxPlayers"),
		lockedId = faction == self.m_Faction1 and self.m_AttackingPlayerId or nil,
	})
end

function AttackSession:getNpcInfo(player)
	return {
		area = self.m_AreaObj.m_Name,
		attacker = self.m_Faction1:getShortName(),
		defender = self.m_Faction2:getShortName(),
		phase = self.m_Phase,
		time = self:getTimeLeft(),
		picked = self:isPicked(player),
		entered = self:isParticipantInList(player),
		eliminated = self.m_Eliminated[player:getId()] or false,
		canPick = self:canModifyPick(player),
		pickOpen = not self.m_PickSubmitted[player:getFaction():getId()],
	}
end

function AttackSession:requestLateJoin(player)
	local id = player:getId()
	if self.m_Phase ~= "battle" then
		player:sendError(_("Nachjoin ist erst in der Attackzeit möglich!", player))
		return
	end
	if self:isParticipantInList(player) then
		player:sendError(_("Du kannst nicht nachjoinen!", player))
		return
	end
	if self.m_LateRequests[id] then
		player:sendError(_("Deine Anfrage läuft noch!", player))
		return
	end
	local cooldown = (self.m_LateCooldown[id] or 0) - getRealTime().timestamp
	if cooldown > 0 then
		player:sendError(_("Du kannst erst in %d:%02d Minuten erneut anfragen!", player, math.floor(cooldown/60), cooldown%60))
		return
	end

	local reason = self:getEnterBlockReason(player)
	if reason then
		player:sendError(reason)
		return
	end

	local faction = player:getFaction()
	local count = 0
	for _, participant in ipairs(self.m_Participants) do
		if participant:getFaction() == faction then
			count = count + 1
		end
	end
	if count >= self.m_Manager:getSetting("MaxPlayers") then
		player:sendError(_("Es sind bereits alle Plätze belegt!", player))
		return
	end

	local opponent = self:getOpponent(faction)
	local clear = function()
		self.m_LateRequests[id] = nil
	end
	self.m_LateRequests[id] = true
	self.m_LateCooldown[id] = getRealTime().timestamp + 180
	local request = self.m_Manager:createRequest({
		session = self,
		timeout = 30,
		text = self.m_Eliminated[id] and _("%s (%s) ist bereits ausgeschieden und möchte erneut beitreten. Erlauben?", player, player:getName(), faction:getShortName()) or _("%s (%s) möchte dem Gangwar nachjoinen. Erlauben?", player, player:getName(), faction:getShortName()),
		rankFaction = opponent,
		candidates = function()
			local list = {}
			for _, participant in ipairs(self.m_Participants) do
				if participant:getFaction() == opponent and PermissionsManager:getSingleton():hasPlayerPermissionsTo(participant, "faction", "allowGangwarLateJoin") then
					list[#list + 1] = participant
				end
			end
			return list
		end,
		onAccept = function()
			clear()
			if not isElement(player) or self.m_Finished or self.m_Phase ~= "battle" or self:isParticipantInList(player) then return end
			local blocked = self:getEnterBlockReason(player)
			if blocked then
				player:sendError(blocked)
				return
			end
			if not self:isPicked(player) then
				table.insert(self.m_Picks[faction:getId()], id)
			end
			self.m_Eliminated[id] = nil
			self:enterPlayer(player)
			self:sendToBoth(("[Gangwar] #FFFFFFDer Spieler %s jointe dem Gangwar nach!"):format(player:getName()), 0, 204, 204)
		end,
		onDecline = function()
			clear()
			if isElement(player) then
				player:sendError(_("Dein Nachjoin wurde abgelehnt!", player))
			end
		end,
	})
	if request then
		player:sendInfo(_("Deine Anfrage wurde an %s gesendet!", player, opponent:getShortName()))
	end
end

function AttackSession:applySaves()
	local present = {[self.m_Faction1] = 0, [self.m_Faction2] = 0}
	for _, player in ipairs(self.m_Participants) do
		present[player:getFaction()] = present[player:getFaction()] + 1
	end
	local count1, count2 = present[self.m_Faction1], present[self.m_Faction2]
	if count1 == 0 or count2 == 0 then return end

	local defenderCount = self.m_IsGiven and count2 or math.max(count2, self.m_Manager:getSetting("MinPlayers"))
	self:saveSurplus(self.m_Faction1, count1 - math.min(count1, defenderCount + 1))
	self:saveSurplus(self.m_Faction2, count2 - math.min(count2, count1))
end

function AttackSession:saveSurplus(faction, surplus)
	if surplus <= 0 then return end
	local list = self.m_Picks[faction:getId()]
	for index = #list, 1, -1 do
		if surplus <= 0 then return end
		local player = Player.getFromId(list[index])
		if player and isElement(player) and self:isParticipantInList(player) then
			surplus = surplus - 1
			player:sendInfo(_("Du wurdest automatisch gesaved und nimmst nicht am Gangwar teil.", player))
			self:sendToBoth(("[Gangwar] #FFFFFFDer Spieler %s nimmt nicht am Gangwar teil! (Gesaved)"):format(player:getName()), 100, 120, 100)
			self:removeFromSession(player)
			self:restorePlayer(player)
		end
	end
end

function AttackSession:onPrepareEnd()
	if self.m_Finished then return end
	self:destroyVehicleZones()
	self:closePickStatus()
	if isTimer(self.m_DefenderZoneTimer) then killTimer(self.m_DefenderZoneTimer) end
	self:applySaves()
	self.m_Phase = "battle"

	for _, player in ipairs(self.m_Participants) do
		player:setHealth(100)
		player:setArmor(100)
		player:triggerEvent("GangwarVehicle:close")
	end

	self.m_PhaseTimer = setTimer(function()
		self:finish(self.m_Faction1, 0)
	end, self.m_Manager:getSetting("BattleTime")*60000, 1)

	self:sendToBoth("[Gangwar] #FFFFFFDie Attackzeit hat begonnen!", 0, 204, 204)
	self:synchronizeLists()
	self:synchronizeTime()
	if not self:sessionCheck() then
		self:checkCenter()
	end
end

function AttackSession:onCenterEnter(hitElement, matchingDimension)
	if matchingDimension and getElementType(hitElement) == "player" and hitElement:getFaction() == self.m_Faction1 and self:isParticipantInList(hitElement) then
		self:stopCenterCountdown()
	end
end

function AttackSession:onCenterLeave(leaveElement, matchingDimension)
	if matchingDimension and getElementType(leaveElement) == "player" and leaveElement:getFaction() == self.m_Faction1 then
		self:checkCenter()
	end
end

function AttackSession:isAttackerAtFlag()
	local x, y = unpack(self.m_AreaObj:getPosition())
	for _, player in ipairs(self.m_Participants) do
		if player:getFaction() == self.m_Faction1 and not isPedDead(player) and getElementHealth(player) ~= 0 and player:getDimension() == self.m_Dimension then
			local px, py = getElementPosition(player)
			if getDistanceBetweenPoints2D(x, y, px, py) <= GANGWAR_CENTER_HOLD_RANGE then
				return true
			end
		end
	end
	return false
end

function AttackSession:checkCenter()
	if self.m_Phase ~= "battle" or self.m_Finished then return end
	if self:isAttackerAtFlag() then
		self:stopCenterCountdown()
	elseif not isTimer(self.m_HoldCenterTimer) then
		self:startCenterCountdown()
	end
end

function AttackSession:startCenterCountdown()
	local seconds = self.m_Manager:getSetting("FlagTime")
	self.m_Faction1:sendMessage("[Gangwar] #FFFFFFIhr habt noch "..seconds.." Sekunden Zeit die Flagge zu erreichen!", 200, 0, 0, true)
	self.m_Faction2:sendMessage("[Gangwar] #FFFFFFEure Gegner haben noch "..seconds.." Sekunden Zeit die Flagge zu erreichen!", 0, 200, 0, true)
	self.m_HoldCenterTimer = setTimer(bind(self.onCenterTimeout, self), seconds*1000, 1)
	self.m_NotifyAgainTimer = setTimer(bind(self.notifyCenterHalf, self), math.floor(seconds*500), 1)
end

function AttackSession:stopCenterCountdown()
	if isTimer(self.m_HoldCenterTimer) then killTimer(self.m_HoldCenterTimer) end
	if isTimer(self.m_NotifyAgainTimer) then killTimer(self.m_NotifyAgainTimer) end
end

function AttackSession:notifyCenterHalf()
	if self:isAttackerAtFlag() then return end
	local seconds = math.floor(self.m_Manager:getSetting("FlagTime")/2)
	self.m_Faction1:sendMessage("[Gangwar] #FFFFFFIhr habt nur noch "..seconds.." Sekunden Zeit die Flagge zu erreichen!", 200, 0, 0, true)
	self.m_Faction2:sendMessage("[Gangwar] #FFFFFFEure Gegner haben nur noch "..seconds.." Sekunden Zeit die Flagge zu erreichen!", 0, 200, 0, true)
end

function AttackSession:onCenterTimeout()
	if self:isAttackerAtFlag() then return end
	self:finish(self.m_Faction2, 3)
end

function AttackSession:onVehicleZoneHit(hitElement, matchingDimension)
	if not matchingDimension or getElementType(hitElement) ~= "player" or hitElement.vehicle then return end
	if self.m_Phase == "prepare" and self:isParticipantInList(hitElement) and hitElement:getFaction() == source.m_GangwarFaction then
		self:sendVehicleMenu(hitElement)
	end
end

function AttackSession:onVehicleZoneLeave(leaveElement, matchingDimension)
	if matchingDimension and getElementType(leaveElement) == "player" then
		leaveElement:triggerEvent("GangwarVehicle:close")
	end
end

function AttackSession:getVehicleSpawnBlockReason(player)
	local px, py = getElementPosition(player)
	if player:getFaction() == self.m_Faction1 then
		local x1, y1, x2, y2 = unpack(self.m_AreaObj.m_PositionRadar)
		if px < x1 or px > x2 or py < y1 or py > y2 then
			return _("Fahrzeuge kannst du nur innerhalb des Gebiets spawnen!", player)
		end
		return false
	end
	local x, y = unpack(self:getSidePosition(player:getFaction()))
	if getDistanceBetweenPoints2D(x, y, px, py) > self.m_Manager:getSetting("VehicleRadius") + 1 then
		return _("Gehe zum Spawnen in den markierten Kreis!", player)
	end
	return false
end

function AttackSession:requestVehicleMenu(player)
	if self.m_Phase ~= "prepare" then
		player:sendError(_("Fahrzeuge können nur in der Aufbauphase gespawnt werden!", player))
		return
	end
	if player.vehicle then return end
	local reason = self:getVehicleSpawnBlockReason(player)
	if reason then
		player:sendError(reason)
		return
	end
	self:sendVehicleMenu(player)
end

function AttackSession:sendVehicleMenu(player)
	local faction = player:getFaction()
	local used = self.m_VehicleCounts[faction:getId()]
	local list = {}
	local carsLeft, carsTotal = 0, 0
	for model, count in pairs(self.m_Manager:getOwnedVehicleCounts(faction)) do
		if not self.m_Manager:isVehicleBanned(self.m_AreaObj, model) then
			local left = math.max(0, count - (used[model] or 0))
			list[#list + 1] = {id = model, name = getVehicleNameFromModel(model) or tostring(model), left = left}
			carsLeft = carsLeft + left
			carsTotal = carsTotal + count
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	player:triggerEvent("GangwarVehicle:open", list, carsLeft, carsTotal)
end

function AttackSession:spawnVehicle(player, vehicleId)
	if self.m_Phase ~= "prepare" then
		player:sendError(_("Fahrzeuge können nur in der Aufbauzeit gespawnt werden!", player))
		return
	end
	if player.vehicle then return end

	local faction = player:getFaction()
	local factionId = faction:getId()
	local owned = self.m_Manager:getOwnedVehicleCounts(faction)[vehicleId]
	if not owned then return end
	if self.m_Manager:isVehicleBanned(self.m_AreaObj, vehicleId) then
		player:sendError(_("Dieses Fahrzeug ist in diesem Gebiet gesperrt!", player))
		return
	end

	local reason = self:getVehicleSpawnBlockReason(player)
	if reason then
		player:sendError(reason)
		return
	end
	local px, py, pz = getElementPosition(player)
	if (self.m_VehicleCounts[factionId][vehicleId] or 0) >= owned then
		player:sendError(_("Das Fahrzeug-Limit ist erreicht!", player))
		return
	end

	local _rx, _ry, rz = getElementRotation(player)
	local angle = math.rad(rz)
	local x, y = px - 4*math.sin(angle), py + 4*math.cos(angle)
	for vehicleIndex, vehicle in ipairs(self.m_Vehicles) do
		if isElement(vehicle) then
			local vx, vy = getElementPosition(vehicle)
			if getDistanceBetweenPoints2D(vx, vy, x, y) < 3.5 then
				player:sendError(_("Hier steht bereits ein Fahrzeug!", player))
				return
			end
		end
	end

	if not self:createSessionVehicle(vehicleId, x, y, pz + 0.5, rz, faction) then return end
	self.m_VehicleCounts[factionId][vehicleId] = (self.m_VehicleCounts[factionId][vehicleId] or 0) + 1
	self:sendVehicleMenu(player)
end

function AttackSession:createSessionVehicle(model, x, y, z, rotation, faction)
	local vehicle = TemporaryVehicle.create(model, x, y, z, rotation)
	if not vehicle then return false end
	vehicle:setDimension(self.m_Dimension)
	vehicle:setInterior(0)
	vehicle:disableRespawn(true)
	vehicle:toggleRespawn(false)
	vehicle:setData("isGangwarVehicle", true)
	vehicle.m_GangwarFaction = faction
	setVehicleDamageProof(vehicle, true)
	local color = factionCarColors[faction:getId()]
	if color then
		setVehicleColor(vehicle, color.r, color.g, color.b)
	end
	addEventHandler("onVehicleStartEnter", vehicle, bind(self.onVehicleEnter, self))
	self.m_Vehicles[#self.m_Vehicles + 1] = vehicle
	return vehicle
end

function AttackSession:createBarricadeVehicles()
	for index, spawn in ipairs(self.m_AreaObj:getBarricadeSpawns()) do
		self:createSessionVehicle(spawn.model, spawn.x, spawn.y, spawn.z, spawn.rotation, self.m_Faction1)
	end
end

function AttackSession:onVehicleEnter(player)
	if player.m_GangwarSession ~= self or player:getFaction() ~= source.m_GangwarFaction then
		player:sendError(_("Dieses Fahrzeug gehört der anderen Seite!", player))
		cancelEvent()
	end
end

function AttackSession:destroyVehicles()
	for _, vehicle in ipairs(self.m_Vehicles) do
		if isElement(vehicle) then
			destroyElement(vehicle)
		end
	end
	self.m_Vehicles = {}
end

function AttackSession:checkWeapons()
	for playerIndex, player in ipairs(self.m_Participants) do
		if isElement(player) and not isPedDead(player) then
			self:enforceFactionSkin(player)
			self:checkFlagRange(player)
			for slot = 1, 12 do
				local weapon = getPedWeapon(player, slot)
				if weapon > 0 and not self.m_Manager:isAllowedWeapon(weapon) then
					rawTakeWeapon(player, weapon)
					player:sendError(_("Diese Waffe ist im Gangwar nicht erlaubt und wurde entzogen!", player))
				end
			end
		end
	end
end

function AttackSession:stopTimers()
	for _, timer in ipairs({self.m_PhaseTimer, self.m_SyncTimer, self.m_WeaponTimer, self.m_DefenderZoneTimer}) do
		if isTimer(timer) then
			killTimer(timer)
		end
	end
	self:stopCenterCountdown()
end

function AttackSession:releasePlayers()
	local players = {}
	for _, player in ipairs(self.m_Participants) do
		players[#players + 1] = player
	end
	for _, player in ipairs(players) do
		player:triggerEvent("GangwarVehicle:close")
		self:removeFromSession(player)
		if not isPedDead(player) then
			self:restorePlayer(player)
		end
	end
end

function AttackSession:cleanup()
	self:destroyVehicleZones()
	self:closePickStatus()
	self:destroyVehicles()
	if isElement(self.m_FlagPickup) then destroyElement(self.m_FlagPickup) end
	if isElement(self.m_CenterSphere) then destroyElement(self.m_CenterSphere) end
	MapLoader:getSingleton():destroyGangwarInstance(self.m_MapObjects)
	self.m_MapObjects = nil
	self.m_Manager:onSessionFinished(self)
	self.m_AreaObj:attackEnd()
end

function AttackSession:notifyResult(winner, reason)
	local area, f1, f2 = self.m_AreaObj.m_Name, self.m_Faction1, self.m_Faction2
	local discord = Discord:getSingleton()
	if reason == 1 then
		discord:outputGangwarNews(("Die Fraktion %s hat das Gebiet %s gegen die Fraktion %s verteidigt!"):format(f2:getShortName(), area, f1:getShortName()))
	elseif reason == 2 then
		discord:outputGangwarNews(("Die Fraktion %s hat das Gebiet %s der Fraktion %s eingenommen!"):format(f1:getShortName(), area, f2:getShortName()))
	elseif reason == 3 then
		discord:outputGangwarNews(("Die Fraktion %s konnte die Flagge im Gebiet %s der Fraktion %s nicht halten!"):format(f1:getShortName(), area, f2:getShortName()))
	else
		discord:outputGangwarNews(("Die Fraktion %s hat das Gebiet %s der Fraktion %s bis zum Ende gehalten und eingenommen!"):format(f1:getShortName(), area, f2:getShortName()))
	end

	if winner == f1 then
		f1:sendMessage("[Gangwar] #FFFFFFDer Angriff war erfolgreich!", 0, 180, 40, true)
		f2:sendMessage("[Gangwar] #FFFFFFDas Gebiet ist verloren!", 200, 0, 0, true)
	else
		f1:sendMessage("[Gangwar] #FFFFFFDer Angriff ist gescheitert!", 200, 0, 0, true)
		f2:sendMessage("[Gangwar] #FFFFFFDas Gebiet wurde verteidigt!", 0, 180, 40, true)
	end
end

function AttackSession:finish(winner, reason)
	if self.m_Finished then return end
	self.m_Finished = true
	self:stopTimers()

	local area = self.m_AreaObj
	if winner == self.m_Faction1 then
		area.m_Owner = self.m_Faction1:getId()
	end
	area:update()
	self:notifyResult(winner, reason)

	local attackEnd = getRealTime().timestamp
	StatisticsLogger:getSingleton():addGangwarLog(area.m_Name, self.m_Faction1.m_Name, self.m_Faction2.m_Name, self.m_StartTime, attackEnd, winner.m_Name)
	GangwarStatistics:getSingleton():addAttackLog(area.m_Name, self.m_Faction1.m_Name, self.m_Faction2.m_Name, self.m_StartTime, attackEnd, winner.m_Name)

	self.m_Manager:addFinishedAttack({
		areaId = area.m_ID, areaName = area.m_Name, attacker = self.m_Faction1, defender = self.m_Faction2,
		previousOwner = area.m_PreviousOwner, previousLastAttack = area.m_PreviousLastAttack, startTime = self.m_StartTime, winnerName = winner.m_Name,
	})
	self.m_Manager.m_GangwarGuard:lockAfterAttack(self.m_Faction1, self.m_Faction2, self.m_Manager:getSetting("Cooldown"), self.m_Manager:getSetting("SameFactionCooldown"))

	for id, stats in pairs(self.m_Stats) do
		if stats.faction == winner then
			local player = Player.getFromId(id)
			if player and isElement(player) then
				player:givePoints(20)
			end
		end
	end

	GangwarStatistics:getSingleton():collectDamage(self.m_Stats, {
		attacker = {id = self.m_Faction1:getId(), name = self.m_Faction1:getShortName()},
		defender = {id = self.m_Faction2:getId(), name = self.m_Faction2:getShortName()},
		area = area.m_Name,
		duration = attackEnd - self.m_StartTime,
	})
	self:startEndPhase()
end

function AttackSession:startEndPhase()
	self.m_Phase = "end"
	self:destroyVehicleZones()
	self:closePickStatus()
	self:broadcast("GangwarVehicle:close")
	self.m_PhaseTimer = setTimer(bind(self.onEndPhaseOver, self), self.m_Manager:getSetting("EndTime")*1000, 1)
	self.m_SyncTimer = setTimer(bind(self.synchronizeTime, self), 5000, 0)
	self:synchronizeTime()
end

function AttackSession:onEndPhaseOver()
	self:stopTimers()
	self:releasePlayers()
	self:cleanup()
end

function AttackSession:cancelWithoutRating()
	if self.m_Finished then return end
	self.m_Finished = true
	self:stopTimers()

	local area = self.m_AreaObj
	area.m_LastAttack = area.m_PreviousLastAttack
	area:update()
	self:sendToBoth(("[Gangwar] #FFFFFFDer Attack auf %s wurde von einem Admin für ungültig erklärt und nicht gewertet!"):format(area.m_Name), 200, 120, 0)
	self:releasePlayers()
	self:cleanup()
end
